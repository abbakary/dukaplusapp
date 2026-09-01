import type { SaleTransaction } from '@/types/v1';
import type { DocumentRenderData, DocumentType } from './documentTemplates';

const DOC_PREFIX: Record<DocumentType, string> = {
  invoice: 'INV',
  delivery_note: 'DN',
  order_note: 'ON',
};

export function saleDocumentNumber(sale: SaleTransaction, type: DocumentType): string {
  const base = sale.receiptNumber?.replace(/\s+/g, '-') || sale.id.slice(0, 8).toUpperCase();
  return `${DOC_PREFIX[type]}-${base}`;
}

export function saleToDocumentRenderData(
  sale: SaleTransaction,
  documentType: DocumentType,
  options?: { showDiscount?: boolean },
): DocumentRenderData {
  const discount = sale.discountAmount ?? 0;
  const subtotalExVat = sale.subtotal ?? sale.total - sale.vatAmount;
  return {
    documentType,
    documentNumber: saleDocumentNumber(sale, documentType),
    date: formatSaleDate(sale.date),
    customerName: sale.customerName?.trim() || 'Walk-in Customer',
    items: sale.items.map(item => ({
      description: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discountPercent: 0,
    })),
    subtotal: subtotalExVat,
    discountAmount: discount,
    vatAmount: sale.vatAmount ?? 0,
    total: sale.total,
    showDiscount: options?.showDiscount ?? discount > 0,
    notes: sale.traEfdSignature
      ? `TRA EFD: ${sale.traEfdSignature}`
      : sale.payments?.length
        ? `Payment: ${sale.payments.map(p => `${p.method} ${p.amount}`).join(', ')}`
        : undefined,
  };
}

function formatSaleDate(raw: string): string {
  const d = new Date(raw.includes('T') ? raw : raw.replace(' ', 'T'));
  if (Number.isNaN(d.getTime())) return raw;
  return d.toLocaleDateString('en-GB');
}

export const COMPLETED_SALE_STATUSES: SaleTransaction['status'][] = [
  'completed',
  'pending_credit',
];

export function isCompletedSale(sale: SaleTransaction): boolean {
  return COMPLETED_SALE_STATUSES.includes(sale.status);
}
