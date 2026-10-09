interface Env {
  OPENROUTER_API_KEY: string;
  APP_KEY: string;
  MODEL: string;
  SCAN_LIMITER: RateLimit;
}

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

// Most providers reject images over ~5 MB; base64 inflates by 4/3.
const MAX_BASE64_LENGTH = Math.floor((5 * 1024 * 1024 * 4) / 3);

const MEDIA_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];

interface ChatCompletion {
  choices?: { finish_reason?: string; message?: { content?: string | null } }[];
}

const SYSTEM_PROMPT = `You read screenshots and photos of Indonesian food receipts (ShopeeFood, GoFood, GrabFood, restaurant and cafe bills) for a bill-splitting app.

Extract exactly what the customer was charged:
- items: every ordered menu item that is visible. "quantity" is the number ordered, "line_total" is the price for that whole line (quantity x unit price). If the receipt only prints a unit price, multiply it. Variants, toppings and notes under an item (e.g. "Pedas", "Less Ice") belong to that item; never list them as separate items unless they have their own price.
- When a price is struck through next to another price, the struck-through one is the original price; use the price actually charged.
- fees: every extra charge such as delivery (Biaya Pengiriman, Ongkos Kirim), service, app, packaging, order or "lain-lain" fees, using the amount actually charged (0 when shown as free).
- discounts: every voucher, promo or discount, including delivery discounts, as positive amounts.
- tax: tax or PB1/PPN charged as a separate line, otherwise null. Do not invent tax when the receipt says it is already included.
- subtotal and total as printed, otherwise null.
- All amounts are rupiah as plain numbers: "Rp33.750" is 33750.
- If the item list is cut off (e.g. "Lihat Lebih Banyak"), still return the visible items.
- Set is_receipt to false and leave the lists empty if the image is not a receipt or order summary.`;

const RECEIPT_SCHEMA = {
  type: "object",
  properties: {
    is_receipt: { type: "boolean" },
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: { type: "string" },
          quantity: { type: "integer" },
          line_total: { type: "number" },
        },
        required: ["name", "quantity", "line_total"],
        additionalProperties: false,
      },
    },
    fees: {
      type: "array",
      items: {
        type: "object",
        properties: {
          label: { type: "string" },
          amount: { type: "number" },
        },
        required: ["label", "amount"],
        additionalProperties: false,
      },
    },
    discounts: {
      type: "array",
      items: {
        type: "object",
        properties: {
          label: { type: "string" },
          amount: { type: "number" },
        },
        required: ["label", "amount"],
        additionalProperties: false,
      },
    },
    tax: { type: ["number", "null"] },
    subtotal: { type: ["number", "null"] },
    total: { type: ["number", "null"] },
  },
  required: ["is_receipt", "items", "fees", "discounts", "tax", "subtotal", "total"],
  additionalProperties: false,
} as const;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/scan") {
      return json({ error: "not_found" }, 404);
    }

    if (request.headers.get("x-app-key") !== env.APP_KEY) {
      return json({ error: "unauthorized" }, 401);
    }

    const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
    const { success } = await env.SCAN_LIMITER.limit({ key: ip });
    if (!success) {
      return json({ error: "rate_limited" }, 429);
    }

    let body: { image?: unknown; media_type?: unknown };
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid_json" }, 400);
    }

    const { image, media_type: mediaType } = body;
    if (typeof image !== "string" || image.length === 0) {
      return json({ error: "missing_image" }, 400);
    }
    if (image.length > MAX_BASE64_LENGTH) {
      return json({ error: "image_too_large" }, 413);
    }
    if (typeof mediaType !== "string" || !MEDIA_TYPES.includes(mediaType)) {
      return json({ error: "unsupported_media_type" }, 415);
    }

    let upstream: Response;
    try {
      upstream = await fetch(OPENROUTER_URL, {
        method: "POST",
        headers: {
          authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
          "content-type": "application/json",
          "x-title": "Patungan Kuy",
        },
        body: JSON.stringify({
          model: env.MODEL,
          max_tokens: 8000,
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            {
              role: "user",
              content: [
                {
                  type: "image_url",
                  image_url: { url: `data:${mediaType};base64,${image}` },
                },
                { type: "text", text: "Extract this receipt." },
              ],
            },
          ],
          response_format: {
            type: "json_schema",
            json_schema: { name: "receipt", strict: true, schema: RECEIPT_SCHEMA },
          },
          // Only route to providers that actually enforce the schema.
          provider: { require_parameters: true },
        }),
      });
    } catch (error) {
      console.error("OpenRouter unreachable", error);
      return json({ error: "upstream_error" }, 502);
    }

    if (!upstream.ok) {
      console.error(`OpenRouter error ${upstream.status}: ${await upstream.text()}`);
      return json(
        { error: upstream.status === 429 ? "upstream_rate_limited" : "upstream_error" },
        upstream.status === 429 ? 503 : 502,
      );
    }

    const completion: ChatCompletion = await upstream.json();
    const choice = completion.choices?.[0];
    if (choice?.finish_reason === "length") {
      return json({ error: "truncated" }, 502);
    }

    try {
      return json(JSON.parse(choice?.message?.content ?? ""), 200);
    } catch {
      console.error("Model returned invalid JSON", choice?.message?.content);
      return json({ error: "invalid_model_output" }, 502);
    }
  },
} satisfies ExportedHandler<Env>;

function json(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json" },
  });
}
