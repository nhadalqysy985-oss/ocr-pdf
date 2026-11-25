# Test report — ضغط PDF + OCR عربي (browser-only)

Date: 2026-11-25
Environment: Windows, Google Chrome 158.0.8127.38 (headless), Playwright (`playwright-core`), Node.js 24.
App under test: `http://127.0.0.1:8765/` served by `serve.mjs`, fully self-hosted `vendor/` assets.

## Test document

A two-page scanned-style Arabic exam paper generated for the test:

1. Arabic HTML (RTL, Segoe UI) rendered at 1000×1414 CSS px, DPR 2.
2. Screenshot rotated by **+1.35°** (page 1) and **−0.9°** (page 2).
3. Per-pixel scanner noise (±11) and a slight warm cast added on canvas.
4. JPEG at q=0.86, embedded full-page into an A4 PDF with pdf-lib.
5. Ground-truth UTF-8 text saved separately (131 words, 873 chars).

Input PDF: **1,029,995 bytes** (1005.7 KiB).

## End-to-end procedure

For every case Playwright:

- uploads the file through the real `<input type=file>`,
- selects the compression preset (and `بدون OCR` where applicable),
- clicks **ابدأ التحويل**,
- waits for the result card,
- downloads the produced PDF through the real download button,
- reopens the downloaded PDF with PDF.js 3.11.174 in the same browser, calls `getTextContent()` for every page and **renders every page to a canvas** (ink-coverage check that the page is not blank/inverted),
- computes normalized character/word Levenshtein accuracy and runs 10 Arabic search probes.

### Note on PDF.js and Arabic text order

PDF.js applies the bidi algorithm when returning text items, so RTL text comes back in **visual** order. The PDF content stream itself stores **logical** Unicode order, verified by decoding the TJ hex (`0627 0644 062C …` = `الجمهورية`) and by pypdf extraction. For accuracy comparison the extracted text is passed through the standard inverse bidi reordering (`bidi-js`, base direction RTL); search probes run on the logical text.

## Compression results

| Case | Preset | Output | Saving | Time | Char acc. | Word acc. | Probes | Confidence |
|---|---|---|---|---|---|---|---|---|
| `balanced` | JPEG 2000 px / 66% | **175,545 B** (171 KiB) | **−83%** | 24.1 s | 98.63% | 94.19% | 10/10 | 88% |
| `max` | 1‑bit Flate 1600 px | **24,247 B** (24 KiB) | **−98%** | 24.2 s | 98.63% | 94.19% | 10/10 | 88% |
| `high` | JPEG 2800 px / 82% | **531,330 B** (519 KiB) | **−48%** | 22.1 s | 98.63% | 94.19% | 10/10 | 88% |
| `noocr` | JPEG 2000 px / 66% | **169,762 B** (166 KiB) | **−84%** | 5.0 s | — (no text layer) | — | — | — |
| `image` | scanned PNG 3.44 MiB → JPEG 2000 px | **80,283 B** (78 KiB) | **−98%** | 13.3 s | 98.25% | 93.65% | 6/10 | 85% |

- Page size preserved on all cases: **595.28 × 841.89 pt (A4)** for the PDF cases; 495.36 × 689.52 pt for the raw image case.
- Ink coverage per page: 1.4–2.2% (page images present, white background, not inverted).
- Per-page confidence: 90% / 86% (unchanged from the OCR-only build).
- Console errors: **0** in every case.

The OCR accuracy is identical across the three compression presets because the compression step only re-encodes the *visible* page image; the Tesseract text layer (and the OCR input) are unchanged. `max` is the most aggressive: it stores the page as a 1‑bit `DeviceGray` image (`/FlateDecode`, `BitsPerComponent 1`) after Otsu thresholding, which is why 2 A4 pages fit in 24 KiB.

## Structural verification (pypdf)

| File | Pages | Page box | Image XObject | Text layer |
|---|---|---|---|---|
| `balanced.pdf` | 2 | 595.28×841.89 | `/DCTDecode`, `/DeviceRGB`, 8 bpc, 1436×2000 | 1 font, 425 chars on page 1 |
| `max.pdf` | 2 | 595.28×841.89 | `/FlateDecode`, `/DeviceGray`, **1 bpc**, 1149×1600 | 1 font, 425 chars on page 1 |
| `high.pdf` | 2 | 595.28×841.89 | `/DCTDecode`, `/DeviceRGB`, 8 bpc, 1843×2566 | 1 font, 425 chars on page 1 |
| `noocr.pdf` | 2 | 595.28×841.89 | `/DCTDecode` (embedded via pdf-lib), 1436×2000 | **none** (0 fonts, 0 chars) — as designed |
| `image.pdf` | 1 | 495.36×689.52 | `/DCTDecode`, 1437×2000 | 1 font, 425 chars |

The original Tesseract image stream is removed from the page document (`context.delete`), so the compressed image is the only image in the output — no orphaned baseline image bloats the file.

## Visual verification

Pages were rendered from the downloaded PDFs with PDF.js at 1.4× and inspected:

- `max` page 1: crisp black text on white, no inversion, correct RTL layout and deskew.
- `balanced` page 2: clean grayscale page, legible Arabic, correct orientation, straight lines.

## UI verification

| Check | Result |
|---|---|
| Preset → advanced controls sync (max selects 1‑bit/1600, quality disabled) | ✅ |
| Custom preset reveals controls; hint & `qualityVal` update live | ✅ |
| `بدون OCR` disables the language select, TXT/copy buttons, hides the text block, and switches the result note | ✅ |
| Re-running with OCR re-enables TXT/copy and shows the text block again | ✅ |
| Digital-text PDF triggers the warning note and an honest size delta (`+12567%`) | ✅ |
| Stats show before/after sizes and saving percentage; `−` renders on the correct side (`direction:ltr` isolate) | ✅ |
| Loading state: button becomes `جاري التحويل…` with spinner + `aria-busy`, restored afterwards | ✅ |
| Progress heading switches `جاري المعالجة` → `ملخص المعالجة` / `تم الإلغاء` / `توقفت المعالجة` | ✅ |
| Empty state: no files message under the dropzone, side-rail explainer card before the first run, textarea placeholder | ✅ |
| Side rail hides the explainer and shows status/result cards when processing completes | ✅ |
| IBM Plex Sans Arabic loads from `fonts/` (`document.fonts.check` = true) with zero console errors | ✅ |
| No horizontal overflow at 320, 360, 390, 768, 1024, 1280, 1440 px (`scrollWidth == viewport`) | ✅ |
| Dark mode (`prefers-color-scheme: dark`) renders all surfaces, chips, buttons and stats with AA contrast | ✅ |
| Mobile 390px: stacked cards, full-width CTA, 3×2 stats grid, tap targets ≥ 36px | ✅ |

Screenshots: `ocr-pdf-tests/compress/ui-desktop.png`, `ui-mobile.png`, `ui-dark.png`, `ui-empty.png`.

## Offline / self-host

The change adds **no new network dependencies**: compression uses `canvas.toBlob`, `CompressionStream('deflate')` and the already-vendored pdf-lib. The app still loads PDF.js, Tesseract.js, the WASM core and `ara`/`eng` data from `vendor/`. A fresh context that aborts every request outside `http://127.0.0.1:8765/` completes a conversion with the badge `المحركات محمّلة محلياً (وضع Offline)`.

## Reproduce

```powershell
cd ocr-pdf
node serve.mjs 8765
# in another shell, from the workspace root:
node scripts/ocrtool-compress-test.mjs      # 5 end-to-end cases + report.json
node scripts/ocrtool-ui-test.mjs            # UI/preset/no-OCR interactions
node scripts/ocrtool-digital-test.mjs       # digital-PDF warning
node scripts/ocrtool-render-pages.mjs ocr-pdf-tests/compress/balanced.pdf
```

Artifacts: `ocr-pdf-tests/compress/*.pdf`, `*.png`, `report.json`.

## Limitations

- Tesseract Arabic word segmentation can merge adjacent words in `data.text`; the PDF text layer (built from word boxes) preserves spaces better.
- Very large multi-page PDFs use a lot of memory; pages are processed sequentially and canvases released, but a phone may struggle with dozens of pages at 4×.
- The tool targets scanned pages. Born-digital PDFs are detected and warned about, but still processed as images if the user continues.
- Handwriting, decorative fonts and low-resolution photos are outside the accuracy range of `tessdata_fast`.
