# scan-receipt

Cloudflare Worker that reads receipt images with a vision model on OpenRouter
and returns structured JSON for the Patungan Kuy app. The app falls back to on-device ML Kit OCR when
this service is unreachable or not configured.

## Setup

```bash
cd backend/scan-receipt
npm install
npx wrangler login

# Secrets - never commit these
npx wrangler secret put OPENROUTER_API_KEY  # from openrouter.ai/keys
npx wrangler secret put APP_KEY             # any long random string

npx wrangler deploy
```

`wrangler deploy` prints the Worker URL, e.g.
`https://patungan-kuy-scan-receipt.<account>.workers.dev`.

## Local development

```bash
cp .dev.vars.example .dev.vars   # fill in the values
npm run dev
```

## Connecting the app

```bash
flutter run \
  --dart-define=SCANNER_API_URL=https://patungan-kuy-scan-receipt.<account>.workers.dev \
  --dart-define=SCANNER_APP_KEY=<same APP_KEY>
```

For the GitHub Action, add repository secrets `SCANNER_API_URL` and
`SCANNER_APP_KEY`. Without `SCANNER_API_URL` the app only uses ML Kit.

## API

`POST /scan` with header `x-app-key` and body
`{"image": "<base64>", "media_type": "image/jpeg"}`.

Response:

```json
{
  "is_receipt": true,
  "items": [{"name": "Kacang Susu", "quantity": 1, "line_total": 33750}],
  "fees": [{"label": "Biaya Layanan", "amount": 3500}],
  "discounts": [{"label": "Voucher Diskon", "amount": 62643}],
  "tax": null,
  "subtotal": 149150,
  "total": 91507
}
```

Errors: `401` wrong key, `429` per-IP limit (10/minute, see `wrangler.toml`),
`413` image over 5 MB, `502/503` OpenRouter or model problems.

## Notes

- `APP_KEY` ships inside the APK, so it only stops casual abuse; the per-IP
  rate limit and a credit limit on the OpenRouter key are the real cost
  guards. Set that limit at openrouter.ai/keys.
- Model: `MODEL` in `wrangler.toml` (default `google/gemini-3.1-flash-lite`).
  Any OpenRouter model whose page lists image input and `structured_outputs`
  works; change it and run `npx wrangler deploy`, no app rebuild needed.
  `provider.require_parameters` keeps requests on providers that enforce the
  JSON schema.
