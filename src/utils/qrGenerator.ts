import QRCode from 'qrcode';
import { Product } from '@/types/v1';

export interface ProductQRPayload {
  id: string;
  sku: string;
  name: string;
  price: number;
  cost?: number;
  batchNumber?: string;
  expiryDate?: string;
  category?: string;
}

/**
 * Encodes product details into a standard scannable payload format
 */
export function getProductQRPayloadString(product: Product): string {
  const payload: ProductQRPayload = {
    id: product.id,
    sku: product.sku,
    name: product.name,
    price: product.price,
    batchNumber: product.batchNumber,
    expiryDate: product.expiryDate,
    category: product.category,
  };
  return JSON.stringify(payload);
}

/**
 * Generate a high-resolution base64 PNG data URL for a product
 */
export async function generateProductQRCodeDataUrl(
  product: Product,
  width = 256
): Promise<string> {
  try {
    const payloadStr = getProductQRPayloadString(product);
    const dataUrl = await QRCode.toDataURL(payloadStr, {
      width,
      margin: 1,
      errorCorrectionLevel: 'M',
      color: {
        dark: '#1E213D',
        light: '#FFFFFF',
      },
    });
    return dataUrl;
  } catch (err) {
    console.error('Failed to generate QR code data URL', err);
    // Fallback minimal SVG/data url
    return '';
  }
}

/**
 * Parse scanned QR string safely
 */
export function parseScannedQRPayload(scannedText: string): Partial<ProductQRPayload> | null {
  if (!scannedText) return null;
  const trimmed = scannedText.trim();
  
  // Case 1: Standard JSON
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      const parsed = JSON.parse(trimmed);
      return parsed;
    } catch {
      // ignore
    }
  }

  // Case 2: Formatted string DUKA:SKU:PRICE:ID
  if (trimmed.startsWith('DUKA:')) {
    const parts = trimmed.split(':');
    return {
      sku: parts[1] || '',
      price: Number(parts[2]) || 0,
      id: parts[3] || '',
    };
  }

  // Case 3: Raw SKU / Barcode text
  return {
    sku: trimmed,
  };
}
