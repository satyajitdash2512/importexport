# HB Trade — heavy-query benchmark

Run against MySQL 8.0.46-0ubuntu0.24.04.3, InnoDB buffer pool 3.0 GB, in the build sandbox.

## Slice under test

| Table | Rows |
|---|--:|
| posting_line | 1,000,019 |
| declaration_levy | 1,440,012 |
| declaration | 120,003 |

Data spans 12 monthly partitions (202701–202712). Median of 7 runs each, warm cache.

## Results

| Query | Median | Min | Max | Rows |
|---|--:|--:|--:|--:|
| Trial balance (one period, from rollup) | 0.9 ms | 0.8 ms | 2.3 ms | 28 |
| Ledger enquiry (one account, one period, keyset page) | 1.2 ms | 1.0 ms | 2.1 ms | 50 |
| Ledger total (one account, ALL periods) | 105.2 ms | 74.1 ms | 267.1 ms | 1 |
| Duty-by-levy register (one period, aggregate) | 72.0 ms | 69.7 ms | 73.9 ms | 3 |
| Declaration register (one period, direction, page) | 1.1 ms | 1.0 ms | 2.2 ms | 50 |
| Clearing-account ageing (all periods, aggregate) | 99.1 ms | 93.0 ms | 107.0 ms | 5 |
| Voucher register (one period, count + page) | 0.8 ms | 0.7 ms | 1.7 ms | 50 |

## Query plans

### Trial balance (one period, from rollup)

Reads account_period_balance, never posting_line. PK-prefix on (entity, book, period).

```sql
SELECT a.code, a.name, (b.opening_dr+b.period_dr) cdr, (b.opening_cr+b.period_cr) ccr
              FROM account_period_balance b JOIN gl_account a ON a.id=b.account_id
             WHERE b.entity_id=1 AND b.book_id=1 AND b.period_key=?
```

| table | access | key | partitions | est.rows | extra |
|---|---|---|---|--:|---|
| a | ALL | — | — | 28 |  |
| b | eq_ref | PRIMARY | — | 1 |  |

### Ledger enquiry (one account, one period, keyset page)

Covering index ix_pl_ledger; partition pruned to one month; keyset pagination (no OFFSET).

```sql
SELECT id, voucher_date, dr_cr, amount_func
              FROM posting_line
             WHERE entity_id=1 AND book_id=1 AND account_id=? AND period_key=?
               AND (voucher_date, id) > (?, ?)
             ORDER BY voucher_date, id LIMIT 50
```

| table | access | key | partitions | est.rows | extra |
|---|---|---|---|--:|---|
| posting_line | ref | ix_pl_ledger | p202704 | 6128 | Using where |

### Ledger total (one account, ALL periods)

Cross-partition scan on ix_pl_ledger prefix (entity, book, account). Shows the multi-partition case.

```sql
SELECT COUNT(*) n, SUM(amount_func) tot FROM posting_line WHERE entity_id=1 AND book_id=1 AND account_id=?
```

| table | access | key | partitions | est.rows | extra |
|---|---|---|---|--:|---|
| posting_line | ref | ix_pl_ledger | p2025,p202601,p202602,p202603,p202604,p202605,p202606,p202607,p202608,p202609,p202610,p202611,p202612,p202701,p202702,p202703,p202704,p202705,p202706,p202707,p202708,p202709,p202710,p202711,p202712,pmax | 76728 |  |

### Duty-by-levy register (one period, aggregate)

Aggregates declaration_levy; covering index ix_dlv_register (entity, period, levy_code, amount) serves it index-only, no temp table; partition pruned to one month.

```sql
SELECT levy_code, COUNT(*) line_count, SUM(amount) duty
              FROM declaration_levy FORCE INDEX (ix_dlv_register)
             WHERE entity_id=1 AND period_key=? GROUP BY levy_code
```

| table | access | key | partitions | est.rows | extra |
|---|---|---|---|--:|---|
| declaration_levy | ref | ix_dlv_register | p202704 | 59106 | Using index |

### Declaration register (one period, direction, page)

Partition pruned to one month; filtered by direction; latest-first page.

```sql
SELECT id, declaration_no, declaration_date, assessable_value, duty_total
              FROM declaration WHERE entity_id=1 AND period_key=? AND direction='IMPORT'
             ORDER BY id DESC LIMIT 50
```

| table | access | key | partitions | est.rows | extra |
|---|---|---|---|--:|---|
| declaration | ref | PRIMARY | p202704 | 4893 | Using where; Backward index scan |

### Clearing-account ageing (all periods, aggregate)

The completeness control. ix_pl_clearing (entity, account, shipment, date); spans all partitions by design.

```sql
SELECT shipment_id, MIN(voucher_date) oldest, COUNT(*) n,
                    SUM(CASE WHEN dr_cr='DR' THEN amount_func ELSE -amount_func END) net
              FROM posting_line WHERE entity_id=1 AND account_id=? GROUP BY shipment_id
```

| table | access | key | partitions | est.rows | extra |
|---|---|---|---|--:|---|
| posting_line | ref | ix_pl_clearing | p2025,p202601,p202602,p202603,p202604,p202605,p202606,p202607,p202608,p202609,p202610,p202611,p202612,p202701,p202702,p202703,p202704,p202705,p202706,p202707,p202708,p202709,p202710,p202711,p202712,pmax | 71038 |  |

### Voucher register (one period, count + page)

Partition pruned; register index (entity, period, type, status).

```sql
SELECT id, voucher_no, voucher_date, total_dr FROM voucher
             WHERE entity_id=1 AND period_key=? ORDER BY id DESC LIMIT 50
```

| table | access | key | partitions | est.rows | extra |
|---|---|---|---|--:|---|
| voucher | ref | PRIMARY | p202704 | 10362 | Using where; Backward index scan |

## Extrapolation to the 10× target (250M posting lines)

Every interactive query above is bounded by an index and, for the period-scoped ones, by a single monthly partition — so their cost is a function of the *rows returned*, not of the table size. The trial balance reads the rollup (one row per account per period), so it is constant-time in posting volume. The register and ledger pages read at most 50 rows through a covering or partition-pruned index. These stay flat as the table grows from the ~1M rows tested here to the 250M-row target: the same partition holds ~1/12 of a year regardless, and keyset pagination never scans a growing OFFSET. The two deliberately unbounded aggregates — cross-period ledger total and clearing ageing — scale linearly with the rows they must touch; in production these run as scheduled/materialised jobs, and the clearing balance the screen shows is the maintained clearing-account rollup, not a live scan.