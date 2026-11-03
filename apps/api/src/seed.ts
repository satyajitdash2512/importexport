import type {
  Account, CloseTask, CostSheet, Declaration, EntitlementClaim, ExceptionItem, Instrument,
  Licence, Party, ReconciliationSummary, Shipment, TaskItem, TradeOrder, Voucher, VoucherType,
} from './types.js';
import { computeDeclarationLine, previewPosting, round } from './engines.js';

const D = (s: string) => s;

/* ------------------------------------------------------------------ parties */
export const parties: Party[] = [
  { id: 'P-001', contactCode: 'CON-006299', name: 'INDIA IMPEX', legalName: 'INDIA IMPEX', country: 'IN', roles: ['customer'], gstin: '07AABFI8721R1ZP', pan: 'AABFI8721R', iec: '0507012345', ledgerGroup: 'Sundry Debtors', ledgerCode: '1100000506', screeningStatus: 'clear', screenedOn: '2026-07-28', currency: 'INR', relatedParty: false, bankVerified: true },
  { id: 'P-002', contactCode: 'CON-006301', name: 'Hanyang Precision Co', legalName: 'Hanyang Precision Co Ltd', country: 'KR', roles: ['supplier', 'manufacturer'], screeningStatus: 'clear', screenedOn: '2026-08-01', currency: 'USD', incoterm: 'CIF', paymentTerm: 'LC 60 days', relatedParty: false, bankVerified: true, ledgerGroup: 'Sundry Creditors', ledgerCode: '2100000112' },
  { id: 'P-003', contactCode: 'CON-006344', name: 'Acme Global Logistics', legalName: 'Acme Global Logistics Pvt Ltd', country: 'IN', roles: ['forwarder'], gstin: '27AACCA1234M1Z5', screeningStatus: 'clear', screenedOn: '2026-07-20', currency: 'INR', relatedParty: false, bankVerified: true, ledgerGroup: 'Sundry Creditors', ledgerCode: '2100000341' },
  { id: 'P-004', contactCode: 'CON-006350', name: 'Bluewave Clearing', legalName: 'Bluewave Clearing & Forwarding', country: 'IN', roles: ['broker'], gstin: '27AAGCB9911K1Z2', screeningStatus: 'clear', screenedOn: '2026-07-20', currency: 'INR', relatedParty: false, bankVerified: true },
  { id: 'P-005', contactCode: 'CON-006377', name: 'Meridian Industries GmbH', legalName: 'Meridian Industries GmbH', country: 'DE', roles: ['customer'], screeningStatus: 'clear', screenedOn: '2026-08-02', currency: 'EUR', incoterm: 'FOB', paymentTerm: 'LC at sight', relatedParty: false, bankVerified: true, ledgerGroup: 'Sundry Debtors', ledgerCode: '1100000733' },
  { id: 'P-006', contactCode: 'CON-006390', name: 'Orient Traders FZE', legalName: 'Orient Traders FZE', country: 'AE', roles: ['customer'], screeningStatus: 'review', screenedOn: '2026-08-03', currency: 'USD', incoterm: 'CFR', paymentTerm: 'Advance 30%', relatedParty: false, bankVerified: false, ledgerGroup: 'Sundry Debtors', ledgerCode: '1100000811' },
  { id: 'P-007', contactCode: 'CON-006401', name: 'Zhejiang Fastener Works', legalName: 'Zhejiang Fastener Works Co', country: 'CN', roles: ['supplier'], screeningStatus: 'match', screenedOn: '2026-08-04', currency: 'USD', relatedParty: false, bankVerified: false, ledgerGroup: 'Sundry Creditors', ledgerCode: '2100000455' },
  { id: 'P-008', contactCode: 'CON-006412', name: 'Sundar Roadways', legalName: 'Sundar Roadways Pvt Ltd', country: 'IN', roles: ['transporter'], gstin: '27AAECS5522L1ZQ', screeningStatus: 'clear', screenedOn: '2026-06-30', currency: 'INR', relatedParty: false, bankVerified: true },
  { id: 'P-009', contactCode: 'CON-006420', name: 'Sentinel Marine Insurance', legalName: 'Sentinel Marine Insurance Ltd', country: 'IN', roles: ['insurer'], screeningStatus: 'clear', screenedOn: '2026-05-15', currency: 'INR', relatedParty: false, bankVerified: true },
  { id: 'P-010', contactCode: 'CON-006433', name: 'Nordic Components AB', legalName: 'Nordic Components AB', country: 'SE', roles: ['supplier', 'manufacturer'], screeningStatus: 'clear', screenedOn: '2026-07-11', currency: 'EUR', incoterm: 'FCA', paymentTerm: 'Open account 45 days', relatedParty: true, bankVerified: true, ledgerGroup: 'Sundry Creditors', ledgerCode: '2100000478' },
];

/* ------------------------------------------------------------------- orders */
export const orders: TradeOrder[] = [
  {
    id: 'O-001', type: 'import', number: 'IPO-2026-0912', date: '2026-05-28', partyId: 'P-002',
    currency: 'USD', incoterm: 'CIF', namedPlace: 'Nhava Sheva', mode: 'SEA',
    portOfLoading: 'KRPUS', portOfDischarge: 'INNSA', paymentTerm: 'LC 60 days', instrumentRef: 'I-001',
    shipmentWindowFrom: '2026-06-10', shipmentWindowTo: '2026-06-30', status: 'Fully shipped', value: 184500,
    lines: [
      { id: 'OL-001', itemCode: 'HPB-4400', description: 'Bearing housing, cast steel', hsCode: '84821020', qty: 1200, uom: 'PCS', unitPrice: 42.5, currency: 'USD', originCountry: 'KR', preferenceIntent: 'AIFTA', estLandedCost: 5230000, netWeightKg: 2480 },
      { id: 'OL-002', itemCode: 'HPB-4410', description: 'Precision bearing, sealed', hsCode: '84821010', qty: 4000, uom: 'PCS', unitPrice: 11.4, currency: 'USD', originCountry: 'KR', preferenceIntent: 'AIFTA', licenceRef: 'L-002', estLandedCost: 4210000, netWeightKg: 1240 },
      { id: 'OL-003', itemCode: 'HPB-4420', description: 'Seal kit, nitrile', hsCode: '40169390', qty: 8000, uom: 'PCS', unitPrice: 3.1, currency: 'USD', originCountry: 'KR', estLandedCost: 2380000, netWeightKg: 1020 },
      { id: 'OL-004', itemCode: 'HPB-4430', description: 'Spindle assembly', hsCode: '84831099', qty: 600, uom: 'PCS', unitPrice: 71.2, currency: 'USD', originCountry: 'KR', estLandedCost: 3980000, netWeightKg: 1210 },
    ],
  },
  {
    id: 'O-002', type: 'export', number: 'EXO-2026-0441', date: '2026-06-14', partyId: 'P-005',
    currency: 'EUR', incoterm: 'FOB', namedPlace: 'Nhava Sheva', mode: 'SEA',
    portOfLoading: 'INNSA', portOfDischarge: 'DEHAM', paymentTerm: 'LC at sight', instrumentRef: 'I-002',
    shipmentWindowFrom: '2026-07-20', shipmentWindowTo: '2026-08-10', status: 'In fulfilment', value: 342800,
    zeroRatingRoute: 'LUT',
    lines: [
      { id: 'OL-011', itemCode: 'FIN-8801', description: 'Machined gearbox housing', hsCode: '84839000', qty: 900, uom: 'PCS', unitPrice: 214, currency: 'EUR', originCountry: 'IN', schemeIntent: ['RoDTEP', 'Drawback'], netWeightKg: 5400 },
      { id: 'OL-012', itemCode: 'FIN-8815', description: 'Drive shaft, hardened', hsCode: '84832000', qty: 1400, uom: 'PCS', unitPrice: 106, currency: 'EUR', originCountry: 'IN', schemeIntent: ['RoDTEP'], licenceRef: 'L-001', netWeightKg: 3920 },
    ],
  },
  {
    id: 'O-003', type: 'import', number: 'IPO-2026-0948', date: '2026-07-02', partyId: 'P-010',
    currency: 'EUR', incoterm: 'FCA', namedPlace: 'Gothenburg', mode: 'SEA',
    portOfLoading: 'SEGOT', portOfDischarge: 'INNSA', paymentTerm: 'Open account 45 days',
    shipmentWindowFrom: '2026-07-25', shipmentWindowTo: '2026-08-15', status: 'Partially shipped', value: 96400,
    lines: [
      { id: 'OL-021', itemCode: 'NC-2201', description: 'Hydraulic valve block', hsCode: '84811000', qty: 340, uom: 'PCS', unitPrice: 214, currency: 'EUR', originCountry: 'SE', netWeightKg: 890 },
      { id: 'OL-022', itemCode: 'NC-2208', description: 'Servo controller card', hsCode: '85371000', qty: 120, uom: 'PCS', unitPrice: 197, currency: 'EUR', originCountry: 'SE', netWeightKg: 96 },
    ],
  },
  {
    id: 'O-004', type: 'export', number: 'EXO-2026-0468', date: '2026-07-21', partyId: 'P-006',
    currency: 'USD', incoterm: 'CFR', namedPlace: 'Jebel Ali', mode: 'SEA',
    portOfLoading: 'INNSA', portOfDischarge: 'AEJEA', paymentTerm: 'Advance 30% balance DP',
    shipmentWindowFrom: '2026-08-05', shipmentWindowTo: '2026-08-25', status: 'Acceptance checks run', value: 128600,
    zeroRatingRoute: 'IGST',
    lines: [
      { id: 'OL-031', itemCode: 'FIN-9002', description: 'Pump assembly, industrial', hsCode: '84139200', qty: 480, uom: 'PCS', unitPrice: 268, currency: 'USD', originCountry: 'IN', schemeIntent: ['RoDTEP'], netWeightKg: 2880 },
    ],
  },
  {
    id: 'O-005', type: 'import', number: 'IPO-2026-0955', date: '2026-07-18', partyId: 'P-007',
    currency: 'USD', incoterm: 'FOB', namedPlace: 'Ningbo', mode: 'SEA',
    portOfLoading: 'CNNGB', portOfDischarge: 'INNSA', paymentTerm: 'Advance 100%',
    shipmentWindowFrom: '2026-08-01', shipmentWindowTo: '2026-08-20', status: 'Blocked — screening', value: 41200,
    lines: [
      { id: 'OL-041', itemCode: 'ZF-1100', description: 'Hex bolt, grade 8.8', hsCode: '73181500', qty: 240000, uom: 'PCS', unitPrice: 0.17, currency: 'USD', originCountry: 'CN', netWeightKg: 4100 },
    ],
  },
];

/* ---------------------------------------------------------------- shipments */
const ms = (k: string, l: string, p?: string, a?: string, r?: string) => ({ key: k, label: l, planned: p, actual: a, revised: r });

export const shipments: Shipment[] = [
  {
    id: 'S-001', number: 'SHP-2026-04471', direction: 'import', mode: 'SEA', orderIds: ['O-001'], partyId: 'P-002',
    carrier: 'Ocean Star Lines', vessel: 'MV Pacific Trader', voyage: '026E', blNumber: 'OSLNSA2604471', blDate: '2026-06-22',
    portOfLoading: 'KRPUS', portOfDischarge: 'INNSA', incoterm: 'CIF',
    etd: '2026-06-20', atd: '2026-06-22', eta: '2026-07-08', ata: '2026-07-09',
    stage: 'Under clearance', status: 'Under clearance', value: 184500, currency: 'USD',
    forwarder: 'Acme Global Logistics', broker: 'Bluewave Clearing', grossKg: 6320, netKg: 5950,
    containers: [
      { number: 'OSLU4471021', type: '40HC', sealNumber: 'SL884120', tareKg: 3900, grossKg: 24800, freeFrom: '2026-07-09', freeDays: 7, daysUsed: 5, projectedCharge: 34000 },
      { number: 'OSLU4471044', type: '40HC', sealNumber: 'SL884121', tareKg: 3900, grossKg: 23600, freeFrom: '2026-07-09', freeDays: 7, daysUsed: 5, projectedCharge: 34000 },
    ],
    milestones: [
      ms('booked', 'Booking confirmed', '2026-06-12', '2026-06-18'),
      ms('gateIn', 'Gate in at origin', '2026-06-18', '2026-06-20'),
      ms('onBoard', 'Loaded on board', '2026-06-20', '2026-06-22'),
      ms('departed', 'Vessel departed', '2026-06-20', '2026-06-22'),
      ms('arrived', 'Vessel arrived', '2026-07-08', '2026-07-09'),
      ms('igmFiled', 'Arrival manifest filed', '2026-07-09', '2026-07-09'),
      ms('declFiled', 'Declaration filed', '2026-07-07', '2026-07-07'),
      ms('assessed', 'Assessed', '2026-07-10'),
      ms('dutyPaid', 'Duty paid', '2026-07-10'),
      ms('examined', 'Examination', '2026-07-11'),
      ms('cleared', 'Out of charge', '2026-07-11'),
      ms('gateOut', 'Gate out', '2026-07-12'),
      ms('delivered', 'Delivered at site', '2026-07-13'),
      ms('emptyReturn', 'Empty returned', '2026-07-15'),
    ],
    declarationIds: ['D-001'], docsRequired: 13, docsReceived: 11,
    exceptions: [
      { id: 'E-001', severity: 'critical', type: 'Origin proof', title: 'Origin proof not on file — preference at risk', detail: 'Line 2 claims AIFTA preferential rate. Certificate of origin has not been received. The duty saving on that line is blocked and the claim cannot be made without the proof and the underlying origin information (VR-009).', objectType: 'declaration', objectId: 'D-001', exposure: 290257, deadline: '2026-07-10', ageDays: 3, owner: 'Compliance officer', ruleId: 'VR-009', open: true },
      { id: 'E-002', severity: 'high', type: 'Document version', title: 'Insurance certificate version superseded', detail: 'Certificate v1 attached to the declaration has been superseded by v2 issued on 24-Jun-2026 with a corrected assured value.', objectType: 'shipment', objectId: 'S-001', ageDays: 2, owner: 'Documentation executive', ruleId: 'VR-014', open: true },
      { id: 'E-003', severity: 'high', type: 'Free time', title: 'Free time expires in 2 days on 2 containers', detail: 'Blocking item: duty payment pending. Projected detention ₹68,000 if release slips 3 days.', objectType: 'shipment', objectId: 'S-001', exposure: 68000, deadline: '2026-07-16', ageDays: 1, owner: 'Logistics coordinator', ruleId: 'DR-009', open: true },
    ],
  },
  {
    id: 'S-002', number: 'SHP-2026-04502', direction: 'export', mode: 'SEA', orderIds: ['O-002'], partyId: 'P-005',
    carrier: 'Baltic Container Line', vessel: 'MV Hansa Bremen', voyage: '118W', blNumber: 'BCLHAM2604502', blDate: '2026-07-30',
    portOfLoading: 'INNSA', portOfDischarge: 'DEHAM', incoterm: 'FOB',
    etd: '2026-07-29', atd: '2026-07-30', eta: '2026-08-24',
    stage: 'Documents with bank', status: 'Documents presented', value: 342800, currency: 'EUR',
    forwarder: 'Acme Global Logistics', broker: 'Bluewave Clearing', grossKg: 9860, netKg: 9320,
    containers: [{ number: 'BCLU7702118', type: '40GP', sealNumber: 'IN9920114', tareKg: 3700, grossKg: 26400, freeFrom: '2026-07-24', freeDays: 10, daysUsed: 4, projectedCharge: 0 }],
    milestones: [
      ms('booked', 'Booking confirmed', '2026-07-16', '2026-07-16'),
      ms('stuffed', 'Container stuffed', '2026-07-24', '2026-07-25'),
      ms('declFiled', 'Shipping bill filed', '2026-07-26', '2026-07-26'),
      ms('leo', 'Let export order', '2026-07-28', '2026-07-28'),
      ms('onBoard', 'Loaded on board', '2026-07-29', '2026-07-30'),
      ms('egmFiled', 'Export manifest filed', '2026-07-31', '2026-07-31'),
      ms('docsDispatched', 'Documents to bank', '2026-08-01', '2026-08-01'),
      ms('arrived', 'Vessel arrival', '2026-08-24'),
    ],
    declarationIds: ['D-002'], docsRequired: 11, docsReceived: 11,
    exceptions: [
      { id: 'E-004', severity: 'critical', type: 'Presentation deadline', title: 'Bank presentation deadline tomorrow', detail: 'LC/2026/0918 presentation period is 21 days from shipment date 30-Jul-2026. Deadline 05-Aug-2026. One beneficiary certificate is unsigned.', objectType: 'instrument', objectId: 'I-002', exposure: 342800, deadline: '2026-08-05', ageDays: 4, owner: 'Trade finance officer', ruleId: 'VR-011', open: true },
    ],
  },
  {
    id: 'S-003', number: 'SHP-2026-04518', direction: 'import', mode: 'AIR', orderIds: ['O-003'], partyId: 'P-010',
    carrier: 'SkyCargo', portOfLoading: 'SEGOT', portOfDischarge: 'INBOM', incoterm: 'FCA',
    blNumber: '176-44821905', blDate: '2026-08-01',
    etd: '2026-08-01', atd: '2026-08-01', eta: '2026-08-03', ata: '2026-08-03',
    stage: 'Arrived', status: 'Arrived', value: 96400, currency: 'EUR',
    forwarder: 'Acme Global Logistics', broker: 'Bluewave Clearing', grossKg: 1120, netKg: 986,
    containers: [],
    milestones: [
      ms('booked', 'Booking confirmed', '2026-07-28', '2026-07-28'),
      ms('departed', 'Flight departed', '2026-08-01', '2026-08-01'),
      ms('arrived', 'Flight arrived', '2026-08-03', '2026-08-03'),
      ms('declFiled', 'Declaration filed', '2026-08-04'),
      ms('cleared', 'Out of charge', '2026-08-05'),
    ],
    declarationIds: [], docsRequired: 10, docsReceived: 7,
    exceptions: [
      { id: 'E-005', severity: 'high', type: 'Related party', title: 'Related-party import — valuation basis required', detail: 'Supplier Nordic Components AB is a related party. The declaration must record the valuation basis and any special valuation branch reference before filing.', objectType: 'shipment', objectId: 'S-003', ageDays: 1, owner: 'Compliance officer', ruleId: 'HBIE-MDM-025', open: true },
      { id: 'E-006', severity: 'medium', type: 'Documents', title: '3 of 10 required documents pending', detail: 'Pending: certificate of origin, insurance certificate, supplier declaration of origin.', objectType: 'shipment', objectId: 'S-003', ageDays: 1, owner: 'Import executive', ruleId: 'HBIE-MDM-052', open: true },
    ],
  },
  {
    id: 'S-004', number: 'SHP-2026-04530', direction: 'export', mode: 'SEA', orderIds: ['O-004'], partyId: 'P-006',
    carrier: 'Gulf Feeder Services', portOfLoading: 'INNSA', portOfDischarge: 'AEJEA', incoterm: 'CFR',
    etd: '2026-08-12', eta: '2026-08-19', stage: 'Planned', status: 'Planned', value: 128600, currency: 'USD',
    forwarder: 'Acme Global Logistics', broker: 'Bluewave Clearing', grossKg: 3120, netKg: 2880,
    containers: [], declarationIds: [], docsRequired: 9, docsReceived: 2,
    milestones: [ms('booked', 'Booking confirmed', '2026-08-06'), ms('stuffed', 'Container stuffed', '2026-08-10'), ms('declFiled', 'Shipping bill filed', '2026-08-11')],
    exceptions: [
      { id: 'E-007', severity: 'critical', type: 'Screening', title: 'Buyer screening under review — order release blocked', detail: 'Orient Traders FZE returned a potential match on the restricted-party list refresh of 03-Aug-2026 with a score of 87. Order release and payment are blocked pending disposition (VR-020).', objectType: 'party', objectId: 'P-006', exposure: 128600, ageDays: 1, owner: 'Compliance officer', ruleId: 'VR-020', open: true },
      { id: 'E-008', severity: 'medium', type: 'Bank details', title: 'Beneficiary bank details unverified', detail: 'Bank details changed on 01-Aug-2026 and have not been independently verified. Outbound payment is suspended (VR-029).', objectType: 'party', objectId: 'P-006', ageDays: 3, owner: 'Accounts payable', ruleId: 'VR-029', open: true },
    ],
  },
  {
    id: 'S-005', number: 'SHP-2026-04412', direction: 'import', mode: 'SEA', orderIds: ['O-001'], partyId: 'P-002',
    carrier: 'Ocean Star Lines', vessel: 'MV Pacific Trader', voyage: '024E', blNumber: 'OSLNSA2604412', blDate: '2026-05-18',
    portOfLoading: 'KRPUS', portOfDischarge: 'INNSA', incoterm: 'CIF',
    etd: '2026-05-16', atd: '2026-05-18', eta: '2026-06-02', ata: '2026-06-02',
    stage: 'Costed', status: 'Cost sheet open', value: 96200, currency: 'USD',
    forwarder: 'Acme Global Logistics', broker: 'Bluewave Clearing', grossKg: 3980, netKg: 3720,
    containers: [{ number: 'OSLU4412008', type: '40HC', sealNumber: 'SL881002', tareKg: 3900, grossKg: 21400, freeFrom: '2026-06-02', freeDays: 7, daysUsed: 9, projectedCharge: 18000 }],
    milestones: [ms('arrived', 'Vessel arrived', '2026-06-02', '2026-06-02'), ms('cleared', 'Out of charge', '2026-06-05', '2026-06-06'), ms('delivered', 'Delivered at site', '2026-06-08', '2026-06-08')],
    declarationIds: ['D-003'], docsRequired: 13, docsReceived: 13,
    exceptions: [
      { id: 'E-009', severity: 'high', type: 'Cost sheet', title: 'Cost sheet open 58 days — 2 provider invoices awaited', detail: 'Uninvoiced accrual ₹2,12,000 in landed cost clearing. Policy age is 45 days. This is a period close blocker (C-25).', objectType: 'costSheet', objectId: 'CS-003', exposure: 212000, ageDays: 58, owner: 'Cost accountant', ruleId: 'VR-026', open: true },
    ],
  },
];

/* ------------------------------------------------------------- declarations */
const FX = 82.65;

function buildDeclaration(): Declaration {
  const rawLines = [
    { id: 'DL-1', lineNo: 1, itemCode: 'HPB-4400', description: 'Bearing housing, cast steel', hsCode: '84821020', qty: 1200, statutoryUom: 'PCS', stockUom: 'EA', conversion: 1, invoiceValueFc: 51000, currency: 'USD', freightFc: 1275, insuranceFc: 255, originCountry: 'KR', preferenceAgreement: 'AIFTA', preferenceProofRef: 'COO/KR/2026/88412', licenceRef: undefined, assessableValue: 0, levies: [], dutySaved: 0, netWeightKg: 2480 },
    { id: 'DL-2', lineNo: 2, itemCode: 'HPB-4410', description: 'Precision bearing, sealed', hsCode: '84821010', qty: 4000, statutoryUom: 'PCS', stockUom: 'EA', conversion: 1, invoiceValueFc: 45600, currency: 'USD', freightFc: 1140, insuranceFc: 228, originCountry: 'KR', preferenceAgreement: 'AIFTA', preferenceProofRef: undefined, licenceRef: 'AA/2026/0044', assessableValue: 0, levies: [], dutySaved: 0, netWeightKg: 1240 },
    { id: 'DL-3', lineNo: 3, itemCode: 'HPB-4420', description: 'Seal kit, nitrile', hsCode: '40169390', qty: 8000, statutoryUom: 'PCS', stockUom: 'EA', conversion: 1, invoiceValueFc: 24800, currency: 'USD', freightFc: 620, insuranceFc: 124, originCountry: 'KR', assessableValue: 0, levies: [], dutySaved: 0, netWeightKg: 1020 },
    { id: 'DL-4', lineNo: 4, itemCode: 'HPB-4430', description: 'Spindle assembly', hsCode: '84831099', qty: 600, statutoryUom: 'PCS', stockUom: 'EA', conversion: 1, invoiceValueFc: 42720, currency: 'USD', freightFc: 1068, insuranceFc: 214, originCountry: 'KR', assessableValue: 0, levies: [], dutySaved: 0, netWeightKg: 1210 },
  ] as any[];
  const lines = rawLines.map((l) => computeDeclarationLine(l, FX));
  const dutyTotal = round(lines.reduce((s, l) => s + l.levies.reduce((a, x) => a + x.amount, 0), 0), 2);
  const dutyRecoverable = round(lines.reduce((s, l) => s + l.levies.filter((x) => x.recoverable).reduce((a, x) => a + x.amount, 0), 0), 2);
  return {
    id: 'D-001', number: 'BOE-4471', type: 'Home consumption', direction: 'import', shipmentId: 'S-001',
    partyId: 'P-002', portCode: 'INNSA1', filingChannel: 'ICEGATE via broker', authorityRef: '4471021', filedOn: '2026-07-07',
    status: 'Under assessment', statutoryFxRate: FX, currency: 'USD',
    assessableValue: round(lines.reduce((s, l) => s + l.assessableValue, 0), 2),
    dutyTotal, dutyRecoverable, dutyInventoriable: round(dutyTotal - dutyRecoverable, 2),
    assessedDuty: round(dutyTotal + 21400, 2), lines, validations: [], provisional: false,
  };
}

const D001 = buildDeclaration();
/** Duty figures used by the cost sheet and vouchers are DERIVED from the duty
 *  engine, never hand-entered, so every screen agrees with every other. */
export const D001_DUTY = {
  total: D001.dutyTotal,
  recoverable: D001.dutyRecoverable,
  inventoriable: D001.dutyInventoriable,
  assessed: D001.assessedDuty ?? D001.dutyTotal,
  goodsValueFunc: round(D001.lines.reduce((s, l) => s + l.invoiceValueFc * FX, 0), 2),
};

export const declarations: Declaration[] = [
  D001,
  {
    id: 'D-002', number: 'SB-0119', type: 'Export under LUT with RoDTEP and drawback', direction: 'export',
    shipmentId: 'S-002', partyId: 'P-005', portCode: 'INNSA1', filingChannel: 'ICEGATE via broker',
    authorityRef: '0119284', filedOn: '2026-07-26', status: 'Permitted to export', statutoryFxRate: 96.4,
    currency: 'EUR', assessableValue: 33045920, dutyTotal: 0, dutyRecoverable: 0, dutyInventoriable: 0,
    leoRef: 'LEO/0119284', egmMatched: true, provisional: false, lines: [], validations: [],
    entitlements: [
      { id: 'EC-001', scheme: 'RoDTEP', declarationId: 'D-002', declarationNumber: 'SB-0119', fobValue: 18576000, ratePct: 1.4, cap: 320000, computed: 260064, claimed: 260064, sanctioned: 260064, received: 260064, scripRef: 'SCRIP/2026/1188', stage: 'Reconciled', recognitionPoint: 'On sanction', recognised: true, filedOn: '2026-07-26' },
      { id: 'EC-002', scheme: 'Drawback', declarationId: 'D-002', declarationNumber: 'SB-0119', fobValue: 18576000, ratePct: 0.9, computed: 167184, claimed: 167184, sanctioned: 152400, received: 152400, stage: 'Short-received', recognitionPoint: 'On sanction', recognised: true, filedOn: '2026-07-26', shortfallCause: 'Cap applied on two line items at brand rate' },
      { id: 'EC-003', scheme: 'RoDTEP', declarationId: 'D-002', declarationNumber: 'SB-0119', fobValue: 14469920, ratePct: 1.4, computed: 202579, claimed: 202579, stage: 'Under processing', recognitionPoint: 'On sanction', recognised: false, filedOn: '2026-07-26' },
    ],
  },
  {
    id: 'D-003', number: 'BOE-4412', type: 'Home consumption', direction: 'import', shipmentId: 'S-005',
    partyId: 'P-002', portCode: 'INNSA1', filingChannel: 'ICEGATE via broker', authorityRef: '4412884',
    filedOn: '2026-06-03', status: 'Cleared', statutoryFxRate: 83.1, currency: 'USD',
    assessableValue: 8112400, dutyTotal: 1621240, dutyRecoverable: 1145600, dutyInventoriable: 475640,
    assessedDuty: 1621240, paidOn: '2026-06-05', clearedOn: '2026-06-06', lines: [], validations: [], provisional: false,
  },
];

/* ------------------------------------------------------------- cost sheets */
export const costSheets: CostSheet[] = [
  {
    id: 'CS-001', shipmentId: 'S-001', status: 'Partially actualised', goodsValue: D001_DUTY.goodsValueFunc, stockOnHandPct: 62,
    lines: [
      { id: 'CL-1', chargeCode: 'FRT-OCN', chargeName: 'Ocean freight', category: 'Freight', providerId: 'P-003', providerName: 'Acme Global Logistics', basis: 'grossWeight', estimate: 310000, accrued: 310000, actual: 344000, invoiceRef: 'AGL/26/8841', treatment: 'capitalise', status: 'Variance beyond tolerance', currency: 'INR', fxRate: 1, tolerancePct: 5 },
      { id: 'CL-2', chargeCode: 'THC', chargeName: 'Terminal handling and port charges', category: 'Port', providerId: 'P-003', providerName: 'Acme Global Logistics', basis: 'container', estimate: 120000, accrued: 120000, treatment: 'capitalise', status: 'Awaiting invoice', currency: 'INR', fxRate: 1, tolerancePct: 5 },
      { id: 'CL-3', chargeCode: 'DUTY', chargeName: 'Customs duty and levies (non-recoverable)', category: 'Duty', basis: 'direct', estimate: D001_DUTY.inventoriable, accrued: D001_DUTY.inventoriable, actual: round(D001_DUTY.inventoriable + 21400, 2), invoiceRef: 'CHLN/4471021', treatment: 'capitalise', status: 'Variance — assessed above computed', currency: 'INR', fxRate: 1, tolerancePct: 1 },
      { id: 'CL-4', chargeCode: 'IGST-IMP', chargeName: 'Integrated tax on import (recoverable)', category: 'Duty', basis: 'direct', estimate: D001_DUTY.recoverable, accrued: D001_DUTY.recoverable, actual: D001_DUTY.recoverable, invoiceRef: 'CHLN/4471021', treatment: 'recoverable', status: 'Matched', currency: 'INR', fxRate: 1, tolerancePct: 1 },
      { id: 'CL-5', chargeCode: 'BRK', chargeName: 'Customs brokerage fee', category: 'Brokerage', providerId: 'P-004', providerName: 'Bluewave Clearing', basis: 'equal', estimate: 45000, accrued: 45000, actual: 45000, invoiceRef: 'BWC/26/1102', treatment: 'capitalise', status: 'Matched', currency: 'INR', fxRate: 1, tolerancePct: 10 },
      { id: 'CL-6', chargeCode: 'INS', chargeName: 'Marine insurance premium', category: 'Insurance', providerId: 'P-009', providerName: 'Sentinel Marine Insurance', basis: 'value', estimate: 38000, accrued: 38000, actual: 36200, invoiceRef: 'SMI/OP/4471', treatment: 'capitalise', status: 'Matched', currency: 'INR', fxRate: 1, tolerancePct: 10 },
      { id: 'CL-7', chargeCode: 'FRT-INL', chargeName: 'Inland freight to site', category: 'Freight', providerId: 'P-008', providerName: 'Sundar Roadways', basis: 'grossWeight', estimate: 92000, accrued: 92000, treatment: 'capitalise', status: 'Awaiting invoice', currency: 'INR', fxRate: 1, tolerancePct: 8 },
      { id: 'CL-8', chargeCode: 'DET', chargeName: 'Detention', category: 'Penalty', providerId: 'P-003', providerName: 'Acme Global Logistics', basis: 'direct', estimate: 0, accrued: 0, actual: 18000, invoiceRef: 'AGL/26/8877', treatment: 'expense', status: 'Unbudgeted — root cause: duty payment delay', currency: 'INR', fxRate: 1, tolerancePct: 0 },
    ],
  },
  {
    id: 'CS-003', shipmentId: 'S-005', status: 'Partially actualised', goodsValue: 7994000, stockOnHandPct: 18,
    lines: [
      { id: 'CL-11', chargeCode: 'FRT-OCN', chargeName: 'Ocean freight', category: 'Freight', providerId: 'P-003', providerName: 'Acme Global Logistics', basis: 'grossWeight', estimate: 168000, accrued: 168000, treatment: 'capitalise', status: 'Awaiting invoice 58 days', currency: 'INR', fxRate: 1, tolerancePct: 5 },
      { id: 'CL-12', chargeCode: 'DUTY', chargeName: 'Customs duty and levies', category: 'Duty', basis: 'direct', estimate: 475640, accrued: 475640, actual: 475640, invoiceRef: 'CHLN/4412884', treatment: 'capitalise', status: 'Matched', currency: 'INR', fxRate: 1, tolerancePct: 1 },
      { id: 'CL-13', chargeCode: 'THC', chargeName: 'Terminal handling', category: 'Port', providerId: 'P-003', providerName: 'Acme Global Logistics', basis: 'container', estimate: 44000, accrued: 44000, treatment: 'capitalise', status: 'Awaiting invoice 58 days', currency: 'INR', fxRate: 1, tolerancePct: 5 },
      { id: 'CL-14', chargeCode: 'DET', chargeName: 'Detention', category: 'Penalty', providerId: 'P-003', providerName: 'Acme Global Logistics', basis: 'direct', estimate: 0, accrued: 0, actual: 18000, invoiceRef: 'AGL/26/8102', treatment: 'expense', status: 'Matched', currency: 'INR', fxRate: 1, tolerancePct: 0 },
    ],
  },
];

/* ----------------------------------------------------------------- licences */
export const licences: Licence[] = [
  {
    id: 'L-001', scheme: 'EPCG', number: 'EPCG/2024/0117', issuedOn: '2024-03-14', importValidTo: '2026-09-13',
    exportValidTo: '2030-03-13', status: 'Open — at risk', dutySaved: 18460000, obligationAmount: 110760000,
    obligationType: '6 × duty saved', minValueAddition: undefined, averageObligation: 21000000, averageMaintained: true,
    blocks: [
      { label: 'Block 1 (years 1–4, 50%)', sharePct: 50, dueOn: '2028-03-13', fulfilled: 46 },
      { label: 'Block 2 (years 5–6, 50%)', sharePct: 50, dueOn: '2030-03-13', fulfilled: 0 },
    ],
    utilisation: [
      { id: 'U1', date: '2024-04-12', ref: 'BOE-3011', description: 'CNC machining centre', value: 11240000 },
      { id: 'U2', date: '2024-07-26', ref: 'BOE-3288', description: 'Coordinate measuring machine', value: 4810000 },
      { id: 'U3', date: '2024-11-03', ref: 'BOE-3502', description: 'Tool presetter and accessories', value: 2410000 },
    ],
    fulfilment: [
      { id: 'F1', date: '2025-06-04', ref: 'SB-8841', description: 'Gearbox housings to Germany', value: 8420000, evidenceComplete: true },
      { id: 'F2', date: '2025-09-19', ref: 'SB-9120', description: 'Drive shafts to Netherlands', value: 10260000, evidenceComplete: true },
      { id: 'F3', date: '2026-02-28', ref: 'SB-9744', description: 'Gearbox assemblies to Germany', value: 14480000, evidenceComplete: true },
      { id: 'F4', date: '2026-05-11', ref: 'SB-0119', description: 'Machined housings to Germany', value: 17790000, evidenceComplete: false },
    ],
    conditions: [
      { name: 'Actual user condition', satisfied: true, detail: 'Capital goods installed at the declared premises' },
      { name: 'Installation certificate', satisfied: true, detail: 'Certified by chartered engineer on 22-Jun-2024' },
      { name: 'Non-transferable', satisfied: true, detail: 'No transfer recorded' },
      { name: 'Average export obligation', satisfied: true, detail: 'FY26 exports ₹2,84,00,000 against average ₹2,10,00,000' },
    ],
    bondRef: 'BOND/2024/0117', bgWaived: true,
  },
  {
    id: 'L-002', scheme: 'Advance Authorisation', number: 'AA/2026/0044', issuedOn: '2026-02-10',
    importValidTo: '2027-02-09', exportValidTo: '2027-08-09', status: 'Open', dutySaved: 4820000,
    obligationAmount: 28920000, obligationType: 'Value with 15% minimum value addition', minValueAddition: 15,
    blocks: [{ label: 'Single block (18 months)', sharePct: 100, dueOn: '2027-08-09', fulfilled: 31 }],
    utilisation: [
      { id: 'U1', date: '2026-03-18', ref: 'BOE-4180', description: 'Bearing steel, alloy grade', qty: 42000, value: 2210000 },
      { id: 'U2', date: '2026-07-07', ref: 'BOE-4471', description: 'Precision bearings (pending confirmation)', qty: 4000, value: 210000 },
    ],
    fulfilment: [
      { id: 'F1', date: '2026-05-22', ref: 'SB-0088', description: 'Assembled units to Italy', value: 8960000, evidenceComplete: true },
    ],
    conditions: [
      { name: 'Actual user condition', satisfied: true, detail: 'Inputs consumed in own manufacture' },
      { name: 'Pre-import condition', satisfied: true, detail: 'Imports precede the corresponding exports' },
      { name: 'Minimum value addition 15%', satisfied: false, detail: 'Achieved 12.4% to date — shortfall of 2.6 percentage points' },
    ],
    bondRef: 'BOND/2026/0044', bgWaived: false,
  },
  {
    id: 'L-003', scheme: 'MOOWR bonded manufacturing', number: 'MOOWR/2025/0009', issuedOn: '2025-08-01',
    importValidTo: '2030-07-31', exportValidTo: '2030-07-31', status: 'Open', dutySaved: 9240000,
    obligationAmount: 0, obligationType: 'None — duty deferred until removal',
    blocks: [{ label: 'No obligation period', sharePct: 100, dueOn: '2030-07-31', fulfilled: 100 }],
    utilisation: [{ id: 'U1', date: '2026-06-14', ref: 'BOE-4402', description: 'Bonded deposit — alloy steel bar', value: 9240000 }],
    fulfilment: [],
    conditions: [
      { name: 'Licensed premises', satisfied: true, detail: 'Section 65 permission for Unit II' },
      { name: 'Bonded stock ledger reconciled', satisfied: true, detail: 'Last reconciled 03-Aug-2026, no difference' },
    ],
    bondRef: 'BOND/2025/0009',
  },
];

/* -------------------------------------------------------------- instruments */
export const instruments: Instrument[] = [
  {
    id: 'I-001', number: 'LC/2026/0731', type: 'Import documentary credit — usance 60 days',
    governingRules: 'UCP 600', issuingBank: 'State Bank of India, Mumbai', advisingBank: 'Woori Bank, Seoul',
    applicant: 'HostBooks Manufacturing Ltd', beneficiary: 'Hanyang Precision Co Ltd', currency: 'USD',
    value: 200000, tolerancePct: 5, latestShipmentDate: '2026-06-30', expiryDate: '2026-07-21',
    presentationDays: 21, paymentTerms: '60 days from bill of lading date', status: 'Drawn — accepted',
    drawnValue: 184500, availableValue: 25500, charges: 42800, discrepancies: [],
    documentRequirements: [
      { doc: 'Commercial invoice', originals: 3, copies: 3, issuer: 'Beneficiary', held: true },
      { doc: 'Packing list', originals: 3, copies: 3, issuer: 'Beneficiary', held: true },
      { doc: 'Full set bill of lading marked freight prepaid', originals: 3, copies: 3, issuer: 'Carrier', held: true },
      { doc: 'Certificate of origin', originals: 1, copies: 2, issuer: 'Chamber of commerce', held: true },
      { doc: 'Insurance certificate for 110% of CIF value', originals: 2, copies: 1, issuer: 'Insurer', held: true },
    ],
  },
  {
    id: 'I-002', number: 'LC/2026/0918', type: 'Export documentary credit — at sight',
    governingRules: 'UCP 600', issuingBank: 'Commerzbank AG, Hamburg', advisingBank: 'HDFC Bank, Mumbai',
    applicant: 'Meridian Industries GmbH', beneficiary: 'HostBooks Manufacturing Ltd', currency: 'EUR',
    value: 350000, tolerancePct: 5, latestShipmentDate: '2026-08-10', expiryDate: '2026-08-31',
    presentationDays: 21, paymentTerms: 'At sight', status: 'Documents prepared — not presented',
    drawnValue: 0, availableValue: 350000, charges: 0,
    discrepancies: [
      { id: 'DC-1', code: 'CERT-UNSIGNED', description: 'Beneficiary certificate not signed as the credit requires', disposition: 'Correct and re-present' },
    ],
    documentRequirements: [
      { doc: 'Signed commercial invoice', originals: 3, copies: 3, issuer: 'Beneficiary', held: true },
      { doc: 'Packing list', originals: 3, copies: 3, issuer: 'Beneficiary', held: true },
      { doc: 'Full set clean on-board bill of lading', originals: 3, copies: 3, issuer: 'Carrier', held: true },
      { doc: 'Certificate of origin — non-preferential', originals: 1, copies: 2, issuer: 'Chamber of commerce', held: true },
      { doc: 'Beneficiary certificate confirming courier of documents', originals: 1, copies: 1, issuer: 'Beneficiary', wording: 'We certify that one set of non-negotiable documents has been couriered to the applicant within 3 days of shipment', held: false },
      { doc: 'Inspection certificate', originals: 1, copies: 1, issuer: 'SGS', held: true },
    ],
  },
];

/* ---------------------------------------------------------------- accounts */
export const accounts: Account[] = [
  { code: '1201001', name: 'Bank — current account', class: 'asset', type: 'control', group: 'Cash and cash equivalents', scheduleIIIGroup: 'Current assets › Cash and cash equivalents', cashFlow: 'none', subledger: 'Bank', monetary: true, manualPostingAllowed: false, mandatoryDimensions: ['entity'], reconFrequency: 'Daily', openingDr: 48200000, openingCr: 0, periodDr: 121400000, periodCr: 118900000 },
  { code: '1201004', name: 'Bank — EEFC foreign currency account', class: 'asset', type: 'control', group: 'Cash and cash equivalents', scheduleIIIGroup: 'Current assets › Cash and cash equivalents', cashFlow: 'none', subledger: 'Bank', monetary: true, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'currency'], reconFrequency: 'Daily', openingDr: 9840000, openingCr: 0, periodDr: 33100000, periodCr: 29800000 },
  { code: '1301001', name: 'Trade receivables — export debtors', class: 'asset', type: 'control', group: 'Trade receivables', scheduleIIIGroup: 'Current assets › Trade receivables', cashFlow: 'operating', subledger: 'AR', monetary: true, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'party', 'currency'], reconFrequency: 'Monthly', openingDr: 62400000, openingCr: 0, periodDr: 34280000, periodCr: 18900000 },
  { code: '1307001', name: 'Entitlement receivable — RoDTEP', class: 'asset', type: 'control', group: 'Other current assets', scheduleIIIGroup: 'Current assets › Other current assets', cashFlow: 'operating', subledger: 'Entitlement', monetary: true, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'scheme', 'declaration'], reconFrequency: 'Monthly', openingDr: 1840000, openingCr: 0, periodDr: 462643, periodCr: 412464 },
  { code: '1308001', name: 'Duty credit scrip ledger', class: 'asset', type: 'control', group: 'Other current assets', scheduleIIIGroup: 'Current assets › Other current assets', cashFlow: 'operating', subledger: 'Entitlement', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'scheme'], reconFrequency: 'Monthly', openingDr: 980000, openingCr: 0, periodDr: 260064, periodCr: 0 },
  { code: '1401001', name: 'Inventory — raw material (imported)', class: 'asset', type: 'control', group: 'Inventories', scheduleIIIGroup: 'Current assets › Inventories', cashFlow: 'operating', subledger: 'Inventory', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'site', 'item', 'lot'], reconFrequency: 'Monthly', openingDr: 88200000, openingCr: 0, periodDr: 41200000, periodCr: 32800000 },
  { code: '1403001', name: 'Goods in transit — imports', class: 'asset', type: 'ordinary', group: 'Inventories', scheduleIIIGroup: 'Current assets › Inventories', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'shipment'], reconFrequency: 'Monthly', openingDr: 12400000, openingCr: 0, periodDr: 22600000, periodCr: D001_DUTY.goodsValueFunc },
  { code: '1405002', name: 'IGST on imports — credit receivable', class: 'asset', type: 'control', group: 'Duties and taxes', scheduleIIIGroup: 'Current assets › Other current assets', cashFlow: 'operating', subledger: 'Tax', monetary: true, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'declaration', 'taxCode'], reconFrequency: 'Monthly', openingDr: 6420000, openingCr: 0, periodDr: D001_DUTY.recoverable, periodCr: 6100000 },
  { code: '2101001', name: 'Trade payables — foreign suppliers', class: 'liability', type: 'control', group: 'Trade payables', scheduleIIIGroup: 'Current liabilities › Trade payables', cashFlow: 'operating', subledger: 'AP', monetary: true, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'party', 'currency'], reconFrequency: 'Monthly', openingDr: 0, openingCr: 41800000, periodDr: 28400000, periodCr: 37600000 },
  { code: '2101003', name: 'Trade payables — service providers', class: 'liability', type: 'control', group: 'Trade payables', scheduleIIIGroup: 'Current liabilities › Trade payables', cashFlow: 'operating', subledger: 'AP', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'party'], reconFrequency: 'Monthly', openingDr: 0, openingCr: 8900000, periodDr: 6200000, periodCr: 7100000 },
  { code: '2103001', name: 'Customs duty and levies payable', class: 'liability', type: 'ordinary', group: 'Duties and taxes', scheduleIIIGroup: 'Current liabilities › Other current liabilities', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'declaration'], reconFrequency: 'Monthly', openingDr: 0, openingCr: 1240000, periodDr: D001_DUTY.total, periodCr: D001_DUTY.total },
  { code: '2109001', name: 'Landed cost clearing — freight', class: 'liability', type: 'clearing', group: 'Clearing and suspense', scheduleIIIGroup: 'Current liabilities › Other current liabilities', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'shipment', 'chargeType'], reconFrequency: 'Weekly', openingDr: 0, openingCr: 620000, periodDr: 344000, periodCr: 570000 },
  { code: '2109002', name: 'Landed cost clearing — duty', class: 'liability', type: 'clearing', group: 'Clearing and suspense', scheduleIIIGroup: 'Current liabilities › Other current liabilities', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'shipment'], reconFrequency: 'Weekly', openingDr: 0, openingCr: 0, periodDr: D001_DUTY.inventoriable, periodCr: D001_DUTY.inventoriable },
  { code: '2109003', name: 'Landed cost clearing — port and brokerage', class: 'liability', type: 'clearing', group: 'Clearing and suspense', scheduleIIIGroup: 'Current liabilities › Other current liabilities', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'shipment'], reconFrequency: 'Weekly', openingDr: 0, openingCr: 164000, periodDr: 45000, periodCr: 209000 },
  { code: '2109009', name: 'Goods received / invoice received clearing', class: 'liability', type: 'clearing', group: 'Clearing and suspense', scheduleIIIGroup: 'Current liabilities › Other current liabilities', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'shipment'], reconFrequency: 'Monthly', openingDr: 0, openingCr: 2140000, periodDr: 1980000, periodCr: 2410000 },
  { code: '2105001', name: 'Tax deducted at source payable', class: 'liability', type: 'control', group: 'Duties and taxes', scheduleIIIGroup: 'Current liabilities › Other current liabilities', cashFlow: 'operating', subledger: 'Tax', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'party', 'section'], reconFrequency: 'Monthly', openingDr: 0, openingCr: 412000, periodDr: 380000, periodCr: 468000 },
  { code: '4101002', name: 'Revenue from exports', class: 'income', type: 'ordinary', group: 'Revenue from operations', scheduleIIIGroup: 'Revenue from operations', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'segment', 'customer'], openingDr: 0, openingCr: 0, periodDr: 0, periodCr: 34280000 },
  { code: '4301001', name: 'Other operating income — export entitlements', class: 'income', type: 'ordinary', group: 'Other income', scheduleIIIGroup: 'Other income', cashFlow: 'operating', monetary: false, manualPostingAllowed: true, mandatoryDimensions: ['entity', 'scheme'], openingDr: 0, openingCr: 0, periodDr: 14784, periodCr: 462643 },
  { code: '5101001', name: 'Cost of materials consumed', class: 'expense', type: 'ordinary', group: 'Cost of materials', scheduleIIIGroup: 'Cost of materials consumed', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'site', 'item'], openingDr: 0, openingCr: 0, periodDr: 32800000, periodCr: 0 },
  { code: '5109001', name: 'Landed cost variance', class: 'expense', type: 'ordinary', group: 'Cost of materials', scheduleIIIGroup: 'Cost of materials consumed', cashFlow: 'operating', monetary: false, manualPostingAllowed: true, mandatoryDimensions: ['entity', 'shipment'], openingDr: 0, openingCr: 0, periodDr: 34000, periodCr: 0 },
  { code: '5203001', name: 'Demurrage and detention', class: 'expense', type: 'ordinary', group: 'Other expenses', scheduleIIIGroup: 'Other expenses', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'shipment', 'rootCause'], openingDr: 0, openingCr: 0, periodDr: 36000, periodCr: 0 },
  { code: '5301001', name: 'Exchange difference — realised', class: 'expense', type: 'ordinary', group: 'Finance and other', scheduleIIIGroup: 'Other expenses', cashFlow: 'operating', monetary: false, manualPostingAllowed: true, mandatoryDimensions: ['entity', 'currency'], openingDr: 0, openingCr: 0, periodDr: 284000, periodCr: 96000 },
  { code: '5301002', name: 'Exchange difference — unrealised', class: 'expense', type: 'ordinary', group: 'Finance and other', scheduleIIIGroup: 'Other expenses', cashFlow: 'operating', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'currency'], openingDr: 0, openingCr: 0, periodDr: 412000, periodCr: 0 },
  { code: '5302001', name: 'Bank charges — trade', class: 'expense', type: 'ordinary', group: 'Finance and other', scheduleIIIGroup: 'Finance costs', cashFlow: 'financing', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'instrument'], openingDr: 0, openingCr: 0, periodDr: 128400, periodCr: 0 },
  { code: '9101001', name: 'Memorandum — deferred duty on bonded stock', class: 'liability', type: 'memorandum', group: 'Memorandum', scheduleIIIGroup: 'Contingent liabilities (note)', cashFlow: 'none', monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity', 'declaration', 'lot'], reconFrequency: 'Daily', openingDr: 0, openingCr: 9240000, periodDr: 0, periodCr: 0 },
];

/* ---------------------------------------------------------------------------
 * Equity is the residual. Rather than hand-entering figures that do not add up,
 * the balancing amounts are COMPUTED so the trial balance balances exactly in
 * every book — the integrity check in HBIE-ACC-032 must pass on seed data too.
 * ------------------------------------------------------------------------- */
(function balanceTheBooks() {
  const sum = (f: (a: Account) => number) => round(accounts.reduce((t, a) => t + f(a), 0), 2);
  const openingNet = round(sum((a) => a.openingDr) - sum((a) => a.openingCr), 2);
  const periodNet = round(sum((a) => a.periodDr) - sum((a) => a.periodCr), 2);

  const shareCapital: Account = {
    code: '3101001', name: 'Equity share capital', class: 'equity', type: 'ordinary',
    group: 'Equity', scheduleIIIGroup: 'Equity › Equity share capital', cashFlow: 'financing',
    monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity'],
    openingDr: 0, openingCr: 50000000, periodDr: 0, periodCr: 0,
  };
  const retained: Account = {
    code: '3201001', name: 'Other equity — retained earnings', class: 'equity', type: 'ordinary',
    group: 'Equity', scheduleIIIGroup: 'Equity › Other equity', cashFlow: 'none',
    monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity'],
    openingDr: 0, openingCr: round(openingNet - 50000000, 2), periodDr: 0, periodCr: 0,
  };
  const plSummary: Account = {
    code: '3201009', name: 'Other equity — profit and loss for the period', class: 'equity',
    type: 'ordinary', group: 'Equity', scheduleIIIGroup: 'Equity › Other equity', cashFlow: 'none',
    monetary: false, manualPostingAllowed: false, mandatoryDimensions: ['entity'],
    openingDr: 0, openingCr: 0,
    periodDr: periodNet < 0 ? -periodNet : 0, periodCr: periodNet > 0 ? periodNet : 0,
  };
  accounts.push(shareCapital, retained, plSummary);
})();

/* ------------------------------------------------------------ voucher types */
export const voucherTypes: VoucherType[] = [
  { code: 'PJV', name: 'Purchase / goods receipt voucher', documentClass: 'Inventory', statutorySeries: false, postsOn: 'approval', reversible: true, requiredEvidence: ['Supplier invoice', 'Packing list', 'Bill of entry', 'Goods receipt note'], approvalMatrix: 'Value band — stores then finance', printFormat: 'GRN / purchase voucher', retentionYears: 8, books: ['Primary', 'Tax'] },
  { code: 'PIV', name: 'Purchase invoice voucher', documentClass: 'Financial', statutorySeries: false, postsOn: 'approval', reversible: true, requiredEvidence: ['Supplier invoice', 'Purchase order', 'Goods receipt'], approvalMatrix: 'Value band — AP then controller', printFormat: 'Purchase voucher', retentionYears: 8, books: ['Primary', 'Tax'] },
  { code: 'SVI', name: 'Service invoice voucher', documentClass: 'Financial', statutorySeries: false, postsOn: 'approval', reversible: true, requiredEvidence: ['Provider invoice', 'Rate contract reference'], approvalMatrix: 'Value band — logistics then AP', printFormat: 'Service voucher', retentionYears: 8, books: ['Primary', 'Tax'] },
  { code: 'DTY', name: 'Duty and levy voucher', documentClass: 'Statutory', statutorySeries: false, postsOn: 'approval', reversible: false, requiredEvidence: ['Bill of entry', 'Assessment'], approvalMatrix: 'Compliance then finance', printFormat: 'Duty voucher', retentionYears: 8, books: ['Primary', 'Tax'] },
  { code: 'SIV', name: 'Sales invoice voucher — export', documentClass: 'Statutory', statutorySeries: true, postsOn: 'approval', reversible: false, requiredEvidence: ['Export order', 'Shipping bill reference', 'Packing list'], approvalMatrix: 'Documentation then finance', printFormat: 'Export tax invoice', retentionYears: 8, books: ['Primary', 'Tax'] },
  { code: 'CNV', name: 'Credit note voucher', documentClass: 'Statutory', statutorySeries: true, postsOn: 'approval', reversible: false, requiredEvidence: ['Original invoice', 'Reason', 'Approval'], approvalMatrix: 'Value band — controller above threshold', printFormat: 'Credit note', retentionYears: 8, books: ['Primary', 'Tax'] },
  { code: 'PMT', name: 'Payment voucher', documentClass: 'Financial', statutorySeries: false, postsOn: 'approval', reversible: true, requiredEvidence: ['Approved payable', 'Bank advice'], approvalMatrix: 'Value band — treasury then CFO', printFormat: 'Payment advice', retentionYears: 8, books: ['Primary'] },
  { code: 'RCP', name: 'Receipt voucher', documentClass: 'Financial', statutorySeries: false, postsOn: 'approval', reversible: true, requiredEvidence: ['Bank advice'], approvalMatrix: 'AR then controller', printFormat: 'Receipt voucher', retentionYears: 8, books: ['Primary'] },
  { code: 'JVM', name: 'Journal voucher — manual', documentClass: 'Financial', statutorySeries: false, postsOn: 'approval', reversible: true, requiredEvidence: ['Reason note', 'Supporting computation'], approvalMatrix: 'One level above preparer; controller above threshold', printFormat: 'Journal voucher', retentionYears: 8, books: ['Primary', 'Tax', 'Group'] },
  { code: 'LCV', name: 'Landed cost voucher', documentClass: 'Inventory', statutorySeries: false, postsOn: 'approval', reversible: false, requiredEvidence: ['Cost sheet', 'Allocation trace'], approvalMatrix: 'Cost accountant then controller', printFormat: 'Landed cost statement', retentionYears: 8, books: ['Primary'] },
  { code: 'ENT', name: 'Entitlement voucher', documentClass: 'Financial', statutorySeries: false, postsOn: 'approval', reversible: true, requiredEvidence: ['Shipping bill', 'Claim or sanction record'], approvalMatrix: 'Export head then finance', printFormat: 'Entitlement voucher', retentionYears: 8, books: ['Primary'] },
  { code: 'FXR', name: 'Foreign exchange revaluation voucher', documentClass: 'Financial', statutorySeries: false, postsOn: 'save', reversible: true, requiredEvidence: ['Rate source', 'Run log'], approvalMatrix: 'Controller', printFormat: 'Revaluation register', retentionYears: 8, books: ['Primary', 'Group'] },
  { code: 'BND', name: 'Bonded movement voucher', documentClass: 'Memorandum', statutorySeries: false, postsOn: 'approval', reversible: false, requiredEvidence: ['Declaration', 'Facility record'], approvalMatrix: 'Compliance officer', printFormat: 'Bonded movement note', retentionYears: 8, books: ['Primary', 'Memorandum'] },
];

/* -------------------------------------------------------------- vouchers */
function mkVoucher(v: Partial<Voucher> & { id: string; voucherType: string; number: string; date: string; narration: string; lines: any[] }): Voucher {
  const totalDr = round(v.lines.filter((l: any) => l.drCr === 'Dr').reduce((s: number, l: any) => s + l.amountFunc, 0), 2);
  const totalCr = round(v.lines.filter((l: any) => l.drCr === 'Cr').reduce((s: number, l: any) => s + l.amountFunc, 0), 2);
  const vt = voucherTypes.find((t) => t.code === v.voucherType);
  return {
    book: 'Primary', status: 'posted', postingRule: 'PR-IMP-08', postingRuleVersion: 'v3',
    preparedBy: 'A. Kulkarni', approvedBy: 'S. Menon', postedAt: `${v.date}T14:22:00`,
    evidence: [], currency: 'INR', voucherTypeName: vt?.name ?? v.voucherType,
    ...v, totalDr, totalCr,
  } as Voucher;
}

const PJV_FREIGHT = 310000, PJV_PORT = 165000;
const pjvPreview = previewPosting({
  event: 'goodsReceipt',
  amounts: {
    estimatedLandedCost: round(D001_DUTY.goodsValueFunc + D001_DUTY.inventoriable + PJV_FREIGHT + PJV_PORT, 2),
    goodsValueFunc: D001_DUTY.goodsValueFunc,
    dutyInventoriable: D001_DUTY.inventoriable,
    freightEstimate: PJV_FREIGHT, portEstimate: PJV_PORT,
  },
  dimensions: { entity: 'HB Manufacturing Ltd', site: 'Pune Unit I', shipment: 'SHP-2026-04471', declaration: 'BOE-4471' },
});

export const vouchers: Voucher[] = [
  mkVoucher({
    id: 'V-001', voucherType: 'PJV', number: 'PJV/2026-27/00418', date: '2026-07-12',
    narration: 'Goods receipt against BOE-4471 / SHP-2026-04471 at estimated landed cost',
    sourceType: 'goodsReceipt', sourceId: 'GRN-2026-0881', postingRule: 'PR-IMP-08', postingRuleVersion: 'v3',
    lines: pjvPreview.lines,
    evidence: [
      { id: 'EV-1', docType: 'Supplier invoice', name: 'HANYANG-INV-88412.pdf', issuer: 'Hanyang Precision Co', ref: 'INV-88412', date: '2026-06-20', mandatory: true, attached: true, version: 1, sizeKb: 184 },
      { id: 'EV-2', docType: 'Packing list', name: 'HANYANG-PL-88412.pdf', issuer: 'Hanyang Precision Co', ref: 'PL-88412', date: '2026-06-20', mandatory: true, attached: true, version: 1, sizeKb: 96 },
      { id: 'EV-3', docType: 'Bill of entry', name: 'BOE-4471.pdf', issuer: 'Customs', ref: '4471021', date: '2026-07-07', mandatory: true, attached: true, version: 1, sizeKb: 240 },
      { id: 'EV-4', docType: 'Goods receipt note', name: 'GRN-2026-0881.pdf', issuer: 'Stores', ref: 'GRN-2026-0881', date: '2026-07-12', mandatory: true, attached: true, version: 1, sizeKb: 72 },
    ],
  }),
  mkVoucher({
    id: 'V-002', voucherType: 'DTY', number: 'DTY/2026-27/00212', date: '2026-07-10',
    narration: 'Customs duty and levies assessed on BOE-4471 — recoverable and inventoriable split',
    sourceType: 'declaration', sourceId: 'D-001', postingRule: 'PR-IMP-05', postingRuleVersion: 'v3',
    lines: previewPosting({
      event: 'dutyAssessed',
      amounts: { dutyInventoriable: D001_DUTY.inventoriable, dutyRecoverable: D001_DUTY.recoverable, dutyTotal: D001_DUTY.total },
      dimensions: { entity: 'HB Manufacturing Ltd', declaration: 'BOE-4471', port: 'INNSA1' },
    }).lines,
    evidence: [
      { id: 'EV-5', docType: 'Bill of entry', name: 'BOE-4471.pdf', issuer: 'Customs', ref: '4471021', date: '2026-07-07', mandatory: true, attached: true, version: 1, sizeKb: 240 },
      { id: 'EV-6', docType: 'Assessment', name: 'ASSESS-4471021.pdf', issuer: 'Customs', ref: '4471021', date: '2026-07-10', mandatory: true, attached: true, version: 1, sizeKb: 118 },
    ],
  }),
  mkVoucher({
    id: 'V-003', voucherType: 'SIV', number: 'SIV/2026-27/00094', date: '2026-07-30',
    narration: 'Export invoice EXP/2026/0441 to Meridian Industries GmbH — LUT, without payment of IGST',
    sourceType: 'exportInvoice', sourceId: 'EXP/2026/0441', postingRule: 'PR-EXP-02', postingRuleVersion: 'v2',
    currency: 'EUR',
    lines: previewPosting({
      event: 'exportDispatch', amounts: { invoiceValueFunc: 33045920 }, currency: 'EUR', fxRate: 96.4,
      dimensions: { entity: 'HB Manufacturing Ltd', customer: 'Meridian Industries GmbH', segment: 'Auto components', shipment: 'SHP-2026-04502', declaration: 'SB-0119' },
    }).lines,
    evidence: [
      { id: 'EV-7', docType: 'Export order', name: 'EXO-2026-0441.pdf', mandatory: true, attached: true, version: 1, sizeKb: 88 },
      { id: 'EV-8', docType: 'Shipping bill', name: 'SB-0119.pdf', issuer: 'Customs', ref: '0119284', date: '2026-07-26', mandatory: true, attached: true, version: 1, sizeKb: 210 },
      { id: 'EV-9', docType: 'Packing list', name: 'PL-0441.pdf', mandatory: true, attached: true, version: 1, sizeKb: 74 },
    ],
  }),
  mkVoucher({
    id: 'V-004', voucherType: 'ENT', number: 'ENT/2026-27/00061', date: '2026-07-31',
    narration: 'RoDTEP entitlement accrued on SB-0119 — recognised on sanction per Ind AS 20',
    sourceType: 'entitlementClaim', sourceId: 'EC-001', postingRule: 'PR-EXP-10', postingRuleVersion: 'v4',
    lines: previewPosting({ event: 'entitlementAccrual', amounts: { entitlementValue: 260064 }, dimensions: { entity: 'HB Manufacturing Ltd', scheme: 'RoDTEP', declaration: 'SB-0119' } }).lines,
    evidence: [
      { id: 'EV-10', docType: 'Shipping bill', name: 'SB-0119.pdf', mandatory: true, attached: true, version: 1, sizeKb: 210 },
      { id: 'EV-11', docType: 'Sanction / scroll', name: 'SCROLL-1188.pdf', mandatory: true, attached: true, version: 1, sizeKb: 64 },
    ],
  }),
  mkVoucher({
    id: 'V-005', voucherType: 'JVM', number: 'JVM/2026-27/00027', date: '2026-07-31',
    narration: 'Reclassification of demurrage wrongly capitalised on SHP-2026-04412',
    postingRule: 'MANUAL', postingRuleVersion: '—', status: 'pendingApproval',
    preparedBy: 'R. Iyer', approvedBy: undefined, postedAt: undefined,
    lines: [
      { id: 'L1', accountCode: '5203001', accountName: 'Demurrage and detention', drCr: 'Dr', amountTxn: 18000, amountFunc: 18000, currency: 'INR', fxRate: 1, rateType: 'Accounting', dimensions: { entity: 'HB Manufacturing Ltd', shipment: 'SHP-2026-04412', rootCause: 'Duty payment delay' } },
      { id: 'L2', accountCode: '1401001', accountName: 'Inventory — raw material (imported)', drCr: 'Cr', amountTxn: 18000, amountFunc: 18000, currency: 'INR', fxRate: 1, rateType: 'Accounting', dimensions: { entity: 'HB Manufacturing Ltd', site: 'Pune Unit I', item: 'HPB-4400', lot: 'LOT-4412-01' } },
    ],
    evidence: [
      { id: 'EV-12', docType: 'Reason note', name: 'JV-27-reason.pdf', mandatory: true, attached: true, version: 1, sizeKb: 42 },
      { id: 'EV-13', docType: 'Supporting computation', name: 'demurrage-calc.xlsx', mandatory: true, attached: false, version: 0 },
    ],
  }),
  mkVoucher({
    id: 'V-006', voucherType: 'FXR', number: 'FXR/2026-27/00004', date: '2026-07-31',
    narration: 'Period-end revaluation of foreign currency monetary items at closing rate — auto-reversing',
    postingRule: 'PR-PER-02', postingRuleVersion: 'v2', status: 'posted',
    lines: previewPosting({ event: 'fxRevaluation', amounts: { revalLoss: 412000 }, dimensions: { entity: 'HB Manufacturing Ltd', currency: 'USD' } }).lines,
    evidence: [{ id: 'EV-14', docType: 'Rate source', name: 'closing-rates-2026-07-31.pdf', mandatory: true, attached: true, version: 1, sizeKb: 30 }],
  }),
  mkVoucher({
    id: 'V-007', voucherType: 'LCV', number: 'LCV/2026-27/00033', date: '2026-06-30',
    narration: 'Landed cost closure SHP-2026-04412 — differential split by stock position 18% on hand',
    postingRule: 'PR-IMP-11', postingRuleVersion: 'v2', status: 'parked',
    preparedBy: 'M. Shah', approvedBy: undefined, postedAt: undefined,
    lines: previewPosting({ event: 'landedCostClosure', amounts: { toInventory: 3816, toCogs: 17384, differential: 21200 }, dimensions: { entity: 'HB Manufacturing Ltd', shipment: 'SHP-2026-04412', item: 'HPB-4400' } }).lines,
    evidence: [{ id: 'EV-15', docType: 'Cost sheet', name: 'CS-003.pdf', mandatory: true, attached: true, version: 1, sizeKb: 92 }],
  }),
];

/* ---------------------------------------------------------------- close */
export const closeTasks: CloseTask[] = [
  { id: 'CT-01', day: 'D-3', step: 'Cut-off communicated to all functions', area: 'Pre-close', owner: 'Finance controller', status: 'complete', mandatory: true, blockingCount: 0, signedOffBy: 'S. Menon' },
  { id: 'CT-02', day: 'D-3', step: 'Parked and unapproved documents cleared', area: 'Pre-close', owner: 'Accounts executive', status: 'blocked', mandatory: true, blockingCount: 2, blockingDetail: 'JVM/2026-27/00027 pending approval; LCV/2026-27/00033 parked' },
  { id: 'CT-03', day: 'D-3', step: 'Interface backlogs cleared', area: 'Pre-close', owner: 'IT operations', status: 'complete', mandatory: true, blockingCount: 0, signedOffBy: 'IT ops' },
  { id: 'CT-04', day: 'D+1', step: 'Receipts, invoices and payments posted to cut-off', area: 'Subledger cut-off', owner: 'Accounts executive', status: 'complete', mandatory: true, blockingCount: 0, signedOffBy: 'A. Kulkarni' },
  { id: 'CT-05', day: 'D+1', step: 'Goods in transit determined and agreed to shipment register', area: 'Subledger cut-off', owner: 'Cost accountant', status: 'complete', mandatory: true, blockingCount: 0, evidence: 'GIT statement 31-Jul-2026', signedOffBy: 'M. Shah' },
  { id: 'CT-06', day: 'D+1', step: 'Cost accruals raised for received-not-invoiced services', area: 'Subledger cut-off', owner: 'Cost accountant', status: 'complete', mandatory: true, blockingCount: 0, signedOffBy: 'M. Shah' },
  { id: 'CT-07', day: 'D+2', step: 'Bank reconciliation — all accounts', area: 'Reconciliation', owner: 'Accounts executive', status: 'blocked', mandatory: true, blockingCount: 3, blockingDetail: '3 unmatched items on EEFC account, ₹1,84,000 value at risk' },
  { id: 'CT-08', day: 'D+2', step: 'AP and AR subledger to control account', area: 'Reconciliation', owner: 'Accounts executive', status: 'complete', mandatory: true, blockingCount: 0, signedOffBy: 'A. Kulkarni' },
  { id: 'CT-09', day: 'D+2', step: 'Inventory and bonded stock reconciliation', area: 'Reconciliation', owner: 'Compliance officer', status: 'complete', mandatory: true, blockingCount: 0, evidence: 'Bonded reconciliation 03-Aug-2026', signedOffBy: 'D. Rao' },
  { id: 'CT-10', day: 'D+2', step: 'Import tax credit against statutory statement', area: 'Reconciliation', owner: 'Tax executive', status: 'inProgress', mandatory: true, blockingCount: 4, blockingDetail: '4 declarations present in books but credit not reflected; ₹6,42,000' },
  { id: 'CT-11', day: 'D+2', step: 'Exchange control entries reconciled', area: 'Reconciliation', owner: 'Trade finance officer', status: 'blocked', mandatory: true, blockingCount: 9, blockingDetail: '9 export entries unreconciled beyond 8 months' },
  { id: 'CT-12', day: 'D+3', step: 'Landed cost closure for shipments due', area: 'Valuation', owner: 'Cost accountant', status: 'blocked', mandatory: true, blockingCount: 1, blockingDetail: 'CS-003 open 58 days beyond the 45-day policy age' },
  { id: 'CT-13', day: 'D+3', step: 'Inventory valuation and net realisable value test', area: 'Valuation', owner: 'Cost accountant', status: 'notStarted', mandatory: true, blockingCount: 0 },
  { id: 'CT-14', day: 'D+3', step: 'Foreign exchange revaluation of monetary items', area: 'Valuation', owner: 'Treasury officer', status: 'complete', mandatory: true, blockingCount: 0, evidence: 'FXR/2026-27/00004', signedOffBy: 'P. Nair' },
  { id: 'CT-15', day: 'D+3', step: 'Hedge measurement and designation review', area: 'Valuation', owner: 'Treasury officer', status: 'notStarted', mandatory: false, blockingCount: 0 },
  { id: 'CT-16', day: 'D+3', step: 'Provisions remeasured — duty demands and obligations', area: 'Valuation', owner: 'Finance controller', status: 'notStarted', mandatory: true, blockingCount: 0 },
  { id: 'CT-17', day: 'D+4', step: 'Trial balance review and variance analysis', area: 'Review', owner: 'Finance controller', status: 'notStarted', mandatory: true, blockingCount: 0 },
  { id: 'CT-18', day: 'D+4', step: 'Manual journal review', area: 'Review', owner: 'Internal audit', status: 'notStarted', mandatory: true, blockingCount: 0 },
  { id: 'CT-19', day: 'D+4', step: 'Override register review', area: 'Review', owner: 'Internal audit', status: 'notStarted', mandatory: true, blockingCount: 0 },
  { id: 'CT-20', day: 'D+5', step: 'Financial statements and schedules produced', area: 'Report', owner: 'Finance controller', status: 'notStarted', mandatory: true, blockingCount: 0 },
  { id: 'CT-21', day: 'D+5', step: 'Contingent exposure statement', area: 'Report', owner: 'Finance controller', status: 'notStarted', mandatory: true, blockingCount: 0 },
  { id: 'CT-22', day: 'D+6', step: 'Soft close to hard close and sign-off', area: 'Lock', owner: 'Finance controller', status: 'notStarted', mandatory: true, blockingCount: 0 },
];

/* -------------------------------------------------------- reconciliations */
export const reconciliations: ReconciliationSummary[] = [
  {
    id: 'R-01', name: 'Bank — EEFC foreign currency account', sourceA: 'Bank subledger', sourceB: 'Bank statement',
    frequency: 'Daily', owner: 'Accounts executive', asOf: '2026-07-31', matched: 148, unmatchedA: 2, unmatchedB: 1,
    valueAtRisk: 184000, oldestDays: 11, status: 'exceptions',
    items: [
      { id: 'RI-1', ref: 'RCP/2026-27/00188', date: '2026-07-24', description: 'Export realisation Meridian — bank charges deducted at source not booked', amountA: 2840000, amountB: 2812400, difference: 27600, cause: 'Correspondent bank charges deducted from proceeds', ageDays: 7, status: 'unmatched' },
      { id: 'RI-2', ref: 'PMT/2026-27/00301', date: '2026-07-20', description: 'Remittance to Hanyang — value date difference', amountA: 1240000, amountB: undefined, difference: 1240000, cause: 'In books, not yet in statement', ageDays: 11, status: 'unmatched' },
      { id: 'RI-3', ref: 'BANK-CR-8841', date: '2026-07-29', description: 'Unidentified credit in statement', amountA: undefined, amountB: 156400, difference: -156400, cause: 'In statement, not in books — under investigation', ageDays: 2, status: 'disputed' },
    ],
  },
  {
    id: 'R-02', name: 'Import tax credit against statutory statement', sourceA: 'Import declarations', sourceB: 'GSTR-2B credit statement',
    frequency: 'Monthly', owner: 'Tax executive', asOf: '2026-07-31', matched: 62, unmatchedA: 4, unmatchedB: 0,
    valueAtRisk: 642000, oldestDays: 46, status: 'critical',
    items: [
      { id: 'RI-11', ref: 'BOE-4412', date: '2026-06-03', description: 'Declaration in books, credit absent from statement', amountA: 1145600, amountB: undefined, difference: 1145600, cause: 'Declaration present, credit not reflected', ageDays: 46, limitationDate: '2027-11-30', status: 'unmatched' },
      { id: 'RI-12', ref: 'BOE-4402', date: '2026-06-14', description: 'Bonded deposit — no credit expected until ex-bond clearance', amountA: 0, amountB: undefined, difference: 0, cause: 'Timing — correct', ageDays: 35, status: 'matchedManual' },
      { id: 'RI-13', ref: 'BOE-4380', date: '2026-05-28', description: 'Value mismatch between declaration and statement', amountA: 428000, amountB: 412000, difference: 16000, cause: 'Value mismatch', ageDays: 52, limitationDate: '2027-11-30', status: 'unmatched' },
      { id: 'RI-14', ref: 'BOE-4471', date: '2026-07-07', description: 'Awaiting next statement cycle', amountA: 7563892, amountB: undefined, difference: 7563892, cause: 'Timing — expected in August statement', ageDays: 24, status: 'unmatched' },
    ],
  },
  {
    id: 'R-03', name: 'Landed cost clearing — freight', sourceA: 'Cost sheets', sourceB: 'Clearing account 2109001',
    frequency: 'Weekly', owner: 'Cost accountant', asOf: '2026-07-31', matched: 34, unmatchedA: 3, unmatchedB: 0,
    valueAtRisk: 394000, oldestDays: 58, status: 'exceptions',
    items: [
      { id: 'RI-21', ref: 'CS-003 / CL-11', date: '2026-06-02', description: 'Ocean freight accrued, provider invoice not received', amountA: 168000, amountB: 168000, difference: 0, cause: 'Accrued not invoiced — 58 days, beyond policy age', ageDays: 58, status: 'unmatched' },
      { id: 'RI-22', ref: 'CS-003 / CL-13', date: '2026-06-02', description: 'Terminal handling accrued, provider invoice not received', amountA: 44000, amountB: 44000, difference: 0, cause: 'Accrued not invoiced — 58 days', ageDays: 58, status: 'unmatched' },
      { id: 'RI-23', ref: 'CS-001 / CL-7', date: '2026-07-12', description: 'Inland freight accrued, invoice awaited', amountA: 92000, amountB: 92000, difference: 0, cause: 'Accrued not invoiced — within policy', ageDays: 19, status: 'unmatched' },
    ],
  },
  {
    id: 'R-04', name: 'Exchange control — export realisation (EDPMS)', sourceA: 'Declarations and invoices', sourceB: 'EDPMS status',
    frequency: 'Weekly', owner: 'Trade finance officer', asOf: '2026-07-31', matched: 71, unmatchedA: 9, unmatchedB: 0,
    valueAtRisk: 8940000, oldestDays: 268, status: 'critical',
    items: [
      { id: 'RI-31', ref: 'SB-8712 / EXP/2025/0288', date: '2025-11-06', description: 'Realisation overdue beyond the 9-month period in force for that shipment date', amountA: 3240000, difference: 3240000, cause: 'Overdue — buyer dispute on quality claim', ageDays: 268, limitationDate: '2026-08-06', status: 'unmatched' },
      { id: 'RI-32', ref: 'SB-8804 / EXP/2025/0311', date: '2025-12-14', description: 'Part realisation, balance outstanding', amountA: 1860000, amountB: 1200000, difference: 660000, cause: 'Short realisation pending approval', ageDays: 230, status: 'unmatched' },
      { id: 'RI-33', ref: 'SB-9120 / EXP/2025/0402', date: '2026-01-19', description: 'Realised but entry not closed by AD bank', amountA: 2480000, amountB: 2480000, difference: 0, cause: 'Closure pending at bank', ageDays: 194, status: 'unmatched' },
    ],
  },
  {
    id: 'R-05', name: 'AP subledger to control account', sourceA: 'AP subledger', sourceB: 'Accounts 2101001 / 2101003',
    frequency: 'Monthly', owner: 'Accounts executive', asOf: '2026-07-31', matched: 214, unmatchedA: 0, unmatchedB: 0,
    valueAtRisk: 0, oldestDays: 0, status: 'clean', items: [],
  },
  {
    id: 'R-06', name: 'Bonded stock — duty liability ledger', sourceA: 'Bonded duty ledger', sourceB: 'Physical stock and authority records',
    frequency: 'Daily', owner: 'Compliance officer', asOf: '2026-08-03', matched: 46, unmatchedA: 0, unmatchedB: 0,
    valueAtRisk: 0, oldestDays: 0, status: 'clean', items: [],
  },
];

/* ------------------------------------------------------------ task inbox */
export const tasks: TaskItem[] = [
  { id: 'T-01', title: 'Attach origin proof or drop preferential claim', detail: 'BOE-4471 line 2 — preferential duty saving blocked', severity: 'critical', objectType: 'declaration', objectId: 'D-001', route: '/import/declarations/D-001', dueOn: '2026-08-05', owner: 'Compliance officer', kind: 'exception' },
  { id: 'T-02', title: 'Present documents under LC/2026/0918', detail: 'Presentation deadline 05-Aug-2026; one certificate unsigned', severity: 'critical', objectType: 'instrument', objectId: 'I-002', route: '/finance/presentations/I-002', dueOn: '2026-08-05', owner: 'Trade finance officer', kind: 'deadline' },
  { id: 'T-03', title: 'Dispose screening match — Orient Traders FZE', detail: 'Score 87 on list refresh; order release blocked', severity: 'critical', objectType: 'party', objectId: 'P-006', route: '/compliance/screening', dueOn: '2026-08-05', owner: 'Compliance officer', kind: 'review' },
  { id: 'T-04', title: 'Approve duty variance on BOE-4471', detail: 'Assessed amount exceeds the module’s own computation by ₹21,400', severity: 'high', objectType: 'declaration', objectId: 'D-001', route: '/import/declarations/D-001', owner: 'Finance controller', kind: 'approval' },
  { id: 'T-05', title: 'Approve JVM/2026-27/00027', detail: 'Manual journal — demurrage reclassification; supporting computation not attached', severity: 'high', objectType: 'voucher', objectId: 'V-005', route: '/accounting/vouchers/V-005', owner: 'Finance controller', kind: 'approval' },
  { id: 'T-06', title: 'Close cost sheet CS-003', detail: 'Open 58 days; 2 provider invoices awaited; ₹2,12,000 uninvoiced accrual', severity: 'high', objectType: 'costSheet', objectId: 'CS-003', route: '/finance/landed-cost/CS-003', owner: 'Cost accountant', kind: 'exception' },
  { id: 'T-07', title: 'Confirm classification on 4 items', detail: 'Tariff schedule re-baselined 01-May-2026; 4 items on split headings', severity: 'high', objectType: 'item', objectId: 'ITEM-BATCH-1', route: '/setup/items', owner: 'Compliance officer', kind: 'review' },
  { id: 'T-08', title: 'EPCG/2024/0117 obligation projected short', detail: 'Block 1 projected completion 06-Feb-2028 against deadline 13-Mar-2028', severity: 'high', objectType: 'licence', objectId: 'L-001', route: '/compliance/licences/L-001', owner: 'Compliance officer', kind: 'exception' },
  { id: 'T-09', title: 'Reconcile 9 overdue EDPMS entries', detail: '₹89,40,000 unreconciled beyond the realisation period', severity: 'high', objectType: 'reconciliation', objectId: 'R-04', route: '/finance/reconciliations/R-04', owner: 'Trade finance officer', kind: 'exception' },
  { id: 'T-10', title: 'Answer customs query on BOE-4471', detail: 'Valuation query raised 09-Jul-2026, reply due 12-Jul-2026', severity: 'high', objectType: 'declaration', objectId: 'D-001', route: '/import/declarations/D-001', dueOn: '2026-08-06', owner: 'Compliance officer', kind: 'query' },
  { id: 'T-11', title: 'Verify beneficiary bank details — Orient Traders', detail: 'Changed 01-Aug-2026; payment suspended pending dual verification', severity: 'medium', objectType: 'party', objectId: 'P-006', route: '/setup/parties/P-006', owner: 'Accounts payable', kind: 'approval' },
  { id: 'T-12', title: 'Attach missing evidence to LCV/2026-27/00033', detail: 'Parked voucher; allocation trace attached, cost sheet sign-off pending', severity: 'medium', objectType: 'voucher', objectId: 'V-007', route: '/accounting/vouchers/V-007', owner: 'Cost accountant', kind: 'exception' },
];

export const allExceptions: ExceptionItem[] = shipments.flatMap((s) => s.exceptions);

export const entitlements: EntitlementClaim[] = declarations.flatMap((d) => d.entitlements ?? []);
