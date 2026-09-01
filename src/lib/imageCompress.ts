/** Resize and compress an image file for logo upload (max ~480 KB raw). */
export async function compressLogoFile(
  file: File,
  maxBytes = 480_000,
): Promise<{ dataUrl: string; mime: string }> {
  const img = await loadImageFromFile(file);
  const maxDim = 420;
  let w = img.naturalWidth;
  let h = img.naturalHeight;
  if (w > maxDim || h > maxDim) {
    if (w >= h) {
      h = Math.round((h / w) * maxDim);
      w = maxDim;
    } else {
      w = Math.round((w / h) * maxDim);
      h = maxDim;
    }
  }

  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Could not prepare image canvas.');
  ctx.drawImage(img, 0, 0, w, h);

  for (const quality of [0.92, 0.85, 0.78, 0.7, 0.6, 0.5]) {
    const dataUrl = canvas.toDataURL('image/jpeg', quality);
    const rawLen = atob(dataUrl.split(',')[1] ?? '').length;
    if (rawLen <= maxBytes) {
      return { dataUrl, mime: 'image/jpeg' };
    }
  }

  throw new Error(
    'Logo is still too large after compression. Please use a smaller image (under 500 KB).',
  );
}

function loadImageFromFile(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Could not read the selected image.'));
    };
    img.src = url;
  });
}
