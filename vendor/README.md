# Vendored third-party assets

These files are self-hosted so the OCR app works offline. Versions are pinned to
the versions named in `index.html`.

| Package | Version | License | Files |
|---|---|---|---|
| [pdf.js](https://github.com/mozilla/pdf.js) | 3.11.174 | Apache-2.0 | `pdfjs/pdf.min.js`, `pdfjs/pdf.worker.min.js`, `pdfjs/LICENSE` |
| [tesseract.js](https://github.com/naptha/tesseract.js) | 5.1.1 | Apache-2.0 | `tesseract/tesseract.min.js`, `tesseract/worker.min.js`, `tesseract/LICENSE.md` |
| [tesseract.js-core](https://github.com/naptha/tesseract.js-core) | 5.1.1 | Apache-2.0 | LSTM WASM builds (SIMD + fallback), `tesseract-core/LICENSE` |
| [pdf-lib](https://github.com/Hopding/pdf-lib) | 1.17.1 | MIT | `pdf-lib/pdf-lib.min.js`, `pdf-lib/LICENSE.md` |
| [tessdata_fast](https://github.com/tesseract-ocr/tessdata_fast) | main (2025) | Apache-2.0 | `tessdata/ara.traineddata.gz`, `tessdata/eng.traineddata.gz`, `tessdata/LICENSE` |

`ara.traineddata.gz` is `tessdata_fast/ara.traineddata` compressed with gzip
(level 9), 715,721 bytes. `eng.traineddata.gz` is likewise from tessdata_fast.

The unused non-LSTM core builds (OEM 0/2) were removed to keep the repository
small; the app always initializes Tesseract with `OEM.LSTM_ONLY` (`1`).
