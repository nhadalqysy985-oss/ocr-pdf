# Test report — Arabic browser OCR

Date: 2026-11-25
Environment: Windows, Google Chrome 158.0.8127.38 (headless), Playwright (playwright-core), Node.js 24.
App under test: `http://127.0.0.1:8765/` (local static server), fully self-hosted `vendor/` assets.

## Test document

A two-page scanned-style Arabic exam paper was generated for the test:

1. Arabic HTML (RTL, Segoe UI) rendered at 1000×1414 CSS px, DPR 2.
2. Screenshot rotated by **+1.35°** (page 1) and **−0.9°** (page 2).
3. Per-pixel scanner noise (±11) and a slight warm cast added on canvas.
4. JPEG at q=0.86, embedded full-page into an A4 PDF with pdf-lib.
5. Ground-truth UTF-8 text saved separately.

The document contains an exam header, student details (`رقم الجلوس: 123456`), Arabic-Indic-free digits, and a second-page article about digital education — 131 words total.

## End-to-end procedure

For every run Playwright:

- uploads the PDF through the real `<input type=file>`,
- selects the options in the UI,
- clicks **ابدأ التحويل**,
- waits for the result card,
- downloads the produced PDF through the real download button,
- reopens the downloaded PDF with PDF.js **3.11.174** in the same browser and reads `getTextContent()` for every page,
- renders page 1 to a canvas to prove the page is not blank (ink coverage),
- computes normalized character/word Levenshtein accuracy and runs 10 Arabic search probes.

### Note on PDF.js and Arabic text order

PDF.js applies the Unicode bidi algorithm to each text item in `getTextContent()` and returns RTL runs in **visual order** (this is PDF.js behaviour for Arabic/Hebrew, not an OCR error). The text operators in the produced PDF contain **logical Unicode order**; this was verified by decoding the content stream. For the accuracy comparison the extracted text is passed through the standard inverse bidi reordering (`bidi-js`, base direction RTL), and the search probes are run on the logical text.

## Results

### Default settings (3×, contrast stretch, deskew on)

- Runtime: **28.8 s** for 2 pages (includes ~5 s engine/language load).
- Per-page confidence: 90 % / 86 % (avg 88 %).
- Detected skew: **−1.30°** and **+0.90°** (corrects the generated +1.35°/−0.9°).
- Output: 2 pages, page size **595.28 × 841.89 pt (A4)** on both pages.
- Page 1 ink coverage: 3.02 % (image present).
- PDF.js logical text accuracy: **98.58 % character**, **94.03 % word**.
- Search probes: **10/10** (`الجمهورية`, `التربية`, `الامتحانات`, `الجلوس`, `الأسئلة`, `المكتبات`, `الرقمية`, `التعليم`, `الطالب`, `المنصات`).
- PDF size: 4.34 MB.
- TXT download: starts with UTF-8 BOM `EF BB BF`, contains Arabic text.
- Console errors: 0.

### Best settings (4×, Otsu binarization, deskew on)

- Runtime: **27.5 s** for 2 pages.
- Per-page confidence: 91 % / 91 %.
- Detected skew: −1.30° / +0.90°.
- Output: 2 pages, A4, ink coverage 2.59 %.
- PDF.js logical text accuracy: **100 % character**, **100 % word** (131/131 words).
- Search probes: **10/10**.
- PDF size: **0.48 MB** (1-bit image is much smaller than grayscale).
- Console errors: 0.

### Image input

A 2000×2828 scanned-style PNG was uploaded directly (no PDF wrapper). One page was produced in **11.9 s** at 85 % confidence, page size 495×690 pt, searchable text layer present. The image path uses the same render/clean/deskew/OCR pipeline.

### Offline / self-host verification

The page was loaded in a fresh browser context with a route interceptor that **aborts every request outside `http://127.0.0.1:8765/`**. An image was OCRed successfully:

- status: `تم بنجاح: 1 صفحة.`
- engine badge: `المحركات محمّلة محلياً (وضع Offline)`
- blocked external requests: **none** (all assets came from `vendor/`)
- console errors: 0

This confirms the `workerPath` / `corePath` / `langPath` self-host wiring and the offline claim.

## Reproduce

The generator and Playwright test scripts are kept outside the public site (they need Playwright and a local server). Test artifacts: `scanned-arabic.pdf`, `ground-truth.txt`, `result-default.pdf`, `result-otsu.pdf`, `result-image.pdf`, `report.json`.

## Limitations

- Tesseract Arabic word segmentation can merge adjacent words in `data.text` (the PDF text layer, built from Tesseract's word boxes, preserves spaces better). Otsu + 4× resolution gave the best result on this sample.
- Very large multi-page PDFs use a lot of memory; pages are processed sequentially and canvases are released, but a phone may still struggle with dozens of pages at 4×.
- Handwriting, decorative fonts and low-resolution photos are outside the accuracy range of tessdata_fast.
