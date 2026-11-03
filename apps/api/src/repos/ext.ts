/**
 * Public identifier mapping. The UI and its deep links use string ids
 * (P-001, D-001, S-001, V-002 …). Internally every row has a BIGINT surrogate.
 * The demo seed inserts in a fixed order, so surrogate ids line up with the
 * historical string ids; these helpers translate between the two so the entire
 * front end — routes, cross-links, task inbox — keeps working unchanged.
 *
 * Cost sheets keep their natural number (CS-001, CS-003), which the seed stored
 * verbatim, so those are looked up by that column rather than by surrogate.
 */
export const pad3 = (id: number | string) => String(id).padStart(3, '0');

export const ext = {
  party: (id: number) => `P-${pad3(id)}`,
  order: (id: number) => `O-${pad3(id)}`,
  shipment: (id: number) => `S-${pad3(id)}`,
  declaration: (id: number) => `D-${pad3(id)}`,
  licence: (id: number) => `L-${pad3(id)}`,
  instrument: (id: number) => `I-${pad3(id)}`,
  voucher: (id: number) => `V-${pad3(id)}`,
};

/** Parse the trailing number out of a public id (`D-001` → 1). */
export function parseExt(idStr: string): number {
  const m = String(idStr).match(/(\d+)\s*$/);
  return m ? Number(m[1]) : NaN;
}
