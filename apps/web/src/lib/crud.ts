import { get, post } from './api';
import { getSession } from '../features/auth/utils/session';

/** Thin wrappers over the generic CRUD API and the document-write endpoints. */
const BASE = '/api';

async function send(method: string, path: string, body?: unknown) {
  const s = getSession();
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(s ? { Authorization: `Bearer ${s.accessToken}`, 'X-Entity-Id': String(s.entityId) } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(json.error ?? `${res.status} · ${res.statusText}`);
  return json.data;
}

export const getRaw = (resource: string, id: string | number) => get<any>(`/crud/${resource}/${id}`);
export const createRow = (resource: string, body: Record<string, any>) => send('POST', `/crud/${resource}`, body);
export const updateRow = (resource: string, id: string | number, body: Record<string, any>) => send('PUT', `/crud/${resource}/${id}`, body);
export const deleteRow = (resource: string, id: string | number) => send('DELETE', `/crud/${resource}/${id}`);

// nested child collections (order lines, cost lines, recon items, …)
export const getChildren = (resource: string, id: string | number, child: string) => get<any[]>(`/crud/${resource}/${id}/${child}`);
export const replaceChildren = (resource: string, id: string | number, child: string, rows: any[]) => send('PUT', `/crud/${resource}/${id}/${child}`, { rows });

// document writes with children
export const createVoucher = (body: unknown) => post<any>('/vouchers', body);
export const updateVoucher = (id: string, body: unknown) => send('PUT', `/vouchers/${id}`, body);
export const deleteVoucher = (id: string) => send('DELETE', `/vouchers/${id}`);
export const postVoucher = (id: string) => post<any>(`/vouchers/${id}/post`, {});
export const reverseVoucher = (id: string) => post<any>(`/vouchers/${id}/reverse`, {});

// generic authed calls for the admin/ops endpoints
export const apiPost = (path: string, body?: unknown) => send('POST', path, body);
export const apiPut = (path: string, body?: unknown) => send('PUT', path, body);
export const apiDelete = (path: string) => send('DELETE', path);

/** Fetch an authed blob (for print HTML / xlsx export opened via blob URL). */
export async function fetchBlob(path: string): Promise<Blob> {
  const s = getSession();
  const res = await fetch(`/api${path}`, { headers: s ? { Authorization: `Bearer ${s.accessToken}`, 'X-Entity-Id': String(s.entityId) } : {} });
  if (!res.ok) throw new Error(`${res.status} · ${res.statusText}`);
  return res.blob();
}

/** Fetch an authed print document (HTML) and open it in a new window, then trigger the browser print dialog. */
export async function openPrint(path: string): Promise<void> {
  const html = await (await fetchBlob(path)).text();
  const w = window.open('', '_blank');
  if (!w) throw new Error('Pop-up blocked — allow pop-ups to print.');
  w.document.open();
  w.document.write(html);
  w.document.close();
  // give the browser a moment to lay out before invoking print
  w.onload = () => { try { w.focus(); w.print(); } catch { /* user can print manually */ } };
}

/** Fetch an authed binary export and save it to the user's disk. */
export async function downloadBlob(path: string, filename: string): Promise<void> {
  const blob = await fetchBlob(path);
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 4000);
}
