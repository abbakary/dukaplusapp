import type { DocumentBranding, DocumentRenderData, DocumentTemplate } from './documentTemplates';
import { documentTypeLabel } from './documentTemplates';

function fmt(n: number): string {
  return `TSh ${n.toLocaleString('en-TZ')}`;
}

function esc(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function logoHtml(logoUrl: string, maxHeight = 44): string {
  if (!logoUrl) {
    return `<div style="width:44px;height:44px;border-radius:8px;background:rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:700;">LOGO</div>`;
  }
  return `<img src="${esc(logoUrl)}" alt="Logo" style="max-height:${maxHeight}px;max-width:120px;object-fit:contain;border-radius:6px;" />`;
}

function companyMetaLines(branding: DocumentBranding, isSw: boolean): string {
  const lines: string[] = [];
  if (branding.address) lines.push(esc(branding.address));
  if (branding.phone) lines.push(`${isSw ? 'Simu' : 'Phone'}: ${esc(branding.phone)}`);
  if (branding.tinNumber) lines.push(`TIN: ${esc(branding.tinNumber)}`);
  if (!lines.length) return '';
  return `<div style="font-size:9px;color:#6B7280;line-height:1.45;margin-top:4px;">${lines.join('<br/>')}</div>`;
}

function headerBlock(
  tpl: DocumentTemplate,
  data: DocumentRenderData,
  branding: DocumentBranding,
  isSw: boolean,
) {
  const title = documentTypeLabel(data.documentType, isSw).toUpperCase();
  const { theme } = tpl;
  const logo = logoHtml(branding.logoUrl);

  if (tpl.theme.headerStyle === 'wave') {
    return `
      <div style="background:linear-gradient(135deg,${theme.primary},${theme.secondary});padding:18px 20px;border-radius:12px 12px 0 0;color:#fff;display:flex;justify-content:space-between;align-items:flex-start;gap:12px;">
        <div>
          <div style="font-size:10px;opacity:.85;">${esc(data.documentNumber)}</div>
          <div style="font-size:22px;font-weight:800;margin-top:4px;">${title}</div>
          <div style="font-size:10px;opacity:.9;margin-top:4px;">${esc(data.date)}</div>
        </div>
        <div>${logo.replace('rgba(255,255,255,.2)', 'rgba(255,255,255,.25)')}</div>
      </div>`;
  }
  if (tpl.theme.headerStyle === 'sidebar') {
    return `
      <div style="display:flex;min-height:88px;">
        <div style="width:32%;background:${theme.primary};color:#fff;padding:14px 12px;border-radius:12px 0 0 0;display:flex;flex-direction:column;justify-content:space-between;">
          <div>${logo}</div>
          <div style="font-size:12px;font-weight:800;margin-top:8px;line-height:1.2;">${title}</div>
        </div>
        <div style="flex:1;padding:14px 16px;background:${theme.accent}22;">
          <div style="font-size:11px;font-weight:700;color:${theme.primary};">${esc(data.documentNumber)}</div>
          <div style="font-size:10px;color:#4B5563;margin-top:4px;">${esc(data.date)}</div>
        </div>
      </div>`;
  }
  if (tpl.theme.headerStyle === 'brush') {
    return `
      <div style="position:relative;padding:20px;background:${theme.cardBg};border-radius:12px 12px 0 0;display:flex;justify-content:space-between;align-items:flex-start;gap:12px;">
        <div style="flex:1;">
          <div style="height:8px;background:linear-gradient(90deg,${theme.primary},${theme.secondary});border-radius:99px;width:70%;margin-bottom:10px;"></div>
          <div style="font-size:24px;font-weight:900;color:${theme.primary};">${title}</div>
          <div style="font-size:10px;color:#6B7280;margin-top:4px;">${esc(data.documentNumber)} • ${esc(data.date)}</div>
        </div>
        <div>${logo.replace('44px', '40px')}</div>
      </div>`;
  }
  return `
    <div style="background:${theme.primary};color:#fff;padding:16px 20px;border-radius:12px 12px 0 0;display:flex;justify-content:space-between;align-items:center;gap:12px;">
      <div>${logo}</div>
      <div style="text-align:right;">
        <div style="font-size:16px;font-weight:800;">${title}</div>
        <div style="font-size:10px;opacity:.9;margin-top:2px;">${esc(data.documentNumber)}</div>
      </div>
    </div>`;
}

function customerBlock(data: DocumentRenderData, isSw: boolean): string {
  const address = data.customerAddress
    ? `<div style="font-size:9px;color:#6B7280;margin-top:2px;">${esc(data.customerAddress)}</div>`
    : '';
  return `
    <div style="margin-bottom:12px;padding:10px 12px;background:#F9FAFB;border-radius:10px;border:1px solid #E5E7EB;">
      <div style="font-size:9px;font-weight:700;color:#6B7280;text-transform:uppercase;letter-spacing:.04em;">
        ${isSw ? 'Mteja' : 'Customer'}
      </div>
      <div style="font-size:11px;font-weight:700;color:#111;margin-top:2px;">${esc(data.customerName)}</div>
      ${address}
      <div style="font-size:9px;color:#6B7280;margin-top:4px;">${isSw ? 'Tarehe' : 'Date'}: ${esc(data.date)}</div>
    </div>`;
}

function signatureBlock(isSw: boolean): string {
  return `
    <div style="display:flex;justify-content:space-between;gap:16px;margin-top:16px;padding-top:12px;border-top:1px dashed #D1D5DB;">
      <div style="flex:1;">
        <div style="height:36px;border-bottom:1px solid #9CA3AF;"></div>
        <div style="font-size:8px;color:#6B7280;margin-top:4px;">${isSw ? 'Saini ya Mteja' : 'Customer Signature'}</div>
      </div>
      <div style="flex:1;">
        <div style="height:36px;border-bottom:1px solid #9CA3AF;"></div>
        <div style="font-size:8px;color:#6B7280;margin-top:4px;">${isSw ? 'Saini ya Biashara' : 'Authorized Signature'}</div>
      </div>
    </div>`;
}

export function renderDocumentPreviewHtml(
  tpl: DocumentTemplate,
  data: DocumentRenderData,
  branding: DocumentBranding,
  isSw: boolean,
): string {
  const rows = data.items.slice(0, 8).map(item => {
    const line = item.unitPrice * item.quantity * (1 - (item.discountPercent ?? 0) / 100);
    return `<tr>
      <td style="padding:6px 8px;border-bottom:1px solid #E5E7EB;font-size:10px;">${esc(item.description)}</td>
      <td style="padding:6px 8px;border-bottom:1px solid #E5E7EB;font-size:10px;text-align:center;">${item.quantity}</td>
      <td style="padding:6px 8px;border-bottom:1px solid #E5E7EB;font-size:10px;text-align:right;">${fmt(Math.round(item.unitPrice))}</td>
      <td style="padding:6px 8px;border-bottom:1px solid #E5E7EB;font-size:10px;text-align:right;font-weight:600;">${fmt(Math.round(line))}</td>
    </tr>`;
  }).join('');

  const discountRow = data.showDiscount && data.discountAmount > 0
    ? `<div style="display:flex;justify-content:space-between;font-size:10px;color:#B45309;margin-top:4px;">
        <span>${isSw ? 'Punguzo' : 'Discount'}</span><span>- ${fmt(data.discountAmount)}</span></div>`
    : '';

  const notesBlock = data.notes
    ? `<div style="margin-top:10px;padding:8px 10px;background:#FFFBEB;border-radius:8px;border:1px solid #FDE68A;font-size:9px;color:#92400E;">
        <strong>${isSw ? 'Maelezo:' : 'Notes:'}</strong> ${esc(data.notes)}
      </div>`
    : '';

  const watermark = branding.watermark
    ? `<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;pointer-events:none;opacity:.06;font-size:48px;font-weight:900;color:#000;transform:rotate(-24deg);">${esc(branding.watermark)}</div>`
    : '';

  return `
    <div style="position:relative;font-family:Segoe UI,system-ui,sans-serif;background:${tpl.theme.cardBg};border-radius:14px;overflow:hidden;border:1px solid #E5E7EB;box-shadow:0 8px 24px rgba(0,0,0,.08);transform:scale(.92);transform-origin:top center;">
      ${watermark}
      ${headerBlock(tpl, data, branding, isSw)}
      <div style="background:#fff;padding:14px 16px;">
        <div style="font-size:12px;font-weight:800;color:#111;margin-bottom:2px;">${esc(branding.companyName || 'Your Business')}</div>
        ${companyMetaLines(branding, isSw)}
        ${customerBlock(data, isSw)}
        <table style="width:100%;border-collapse:collapse;">
          <thead>
            <tr style="background:${tpl.theme.primary}15;">
              <th style="padding:6px 8px;text-align:left;font-size:9px;color:${tpl.theme.primary};">${isSw ? 'Bidhaa' : 'Item'}</th>
              <th style="padding:6px 8px;text-align:center;font-size:9px;color:${tpl.theme.primary};">Qty</th>
              <th style="padding:6px 8px;text-align:right;font-size:9px;color:${tpl.theme.primary};">${isSw ? 'Bei' : 'Price'}</th>
              <th style="padding:6px 8px;text-align:right;font-size:9px;color:${tpl.theme.primary};">${isSw ? 'Jumla' : 'Total'}</th>
            </tr>
          </thead>
          <tbody>${rows || `<tr><td colspan="4" style="padding:12px;text-align:center;font-size:10px;color:#9CA3AF;">Sample items</td></tr>`}</tbody>
        </table>
        <div style="margin-top:10px;padding-top:8px;border-top:1px dashed #E5E7EB;">
          <div style="display:flex;justify-content:space-between;font-size:10px;color:#374151;"><span>Subtotal</span><span>${fmt(data.subtotal + data.discountAmount)}</span></div>
          ${discountRow}
          <div style="display:flex;justify-content:space-between;font-size:10px;color:#374151;margin-top:4px;"><span>VAT (18%)</span><span>${fmt(data.vatAmount)}</span></div>
          <div style="display:flex;justify-content:space-between;font-size:12px;font-weight:800;color:${tpl.theme.primary};margin-top:6px;"><span>TOTAL</span><span>${fmt(data.total)}</span></div>
        </div>
        ${notesBlock}
        ${signatureBlock(isSw)}
      </div>
      <div style="background:${tpl.theme.primary};color:#fff;font-size:8px;padding:8px 12px;text-align:center;">${esc(branding.footerText)}</div>
    </div>`;
}

export function samplePreviewData(documentType: DocumentRenderData['documentType']): DocumentRenderData {
  return {
    documentType,
    documentNumber: documentType === 'invoice' ? 'INV-2026-0042' : documentType === 'delivery_note' ? 'DN-2026-0188' : 'ON-2026-0091',
    date: new Date().toLocaleDateString('en-GB'),
    customerName: 'Fatuma Hassan',
    customerAddress: 'Kariakoo, Dar es Salaam',
    items: [
      { description: 'Paracetamol 500mg x100', quantity: 2, unitPrice: 8500, discountPercent: 5 },
      { description: 'Amoxicillin 250mg', quantity: 1, unitPrice: 12000 },
      { description: 'Vitamin C 1000mg', quantity: 3, unitPrice: 4500 },
    ],
    subtotal: 45200,
    discountAmount: 850,
    vatAmount: 7971,
    total: 53171,
    showDiscount: true,
    notes: 'Deliver before 5 PM. Call on arrival.',
  };
}

/** Open browser print dialog to save or print a full-size document PDF. */
export function downloadDocumentPdf(
  tpl: DocumentTemplate,
  data: DocumentRenderData,
  branding: DocumentBranding,
  isSw: boolean,
): void {
  const body = renderDocumentPreviewHtml(tpl, data, branding, isSw)
    .replace('transform:scale(.92);transform-origin:top center;', '');
  const title = documentTypeLabel(data.documentType, isSw);
  const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><title>${title}</title>
<style>@page{margin:12mm}body{margin:0;padding:16px;font-family:Segoe UI,system-ui,sans-serif;background:#fff}</style>
</head><body>${body}<script>window.onload=function(){window.print();}</script></body></html>`;
  const win = window.open('', '_blank', 'noopener,noreferrer,width=900,height=700');
  if (!win) {
    alert(isSw ? 'Ruhusu dirisha jipya ili kupakua PDF.' : 'Allow pop-ups to download the PDF.');
    return;
  }
  win.document.write(html);
  win.document.close();
}
