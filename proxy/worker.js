/**
 * Ona proxy — Cloudflare Worker
 *
 * Deploy steps:
 *   1. npm install -g wrangler
 *   2. wrangler login
 *   3. cd proxy && wrangler deploy
 *   4. wrangler secret put ANTHROPIC_API_KEY   (paste your key when prompted)
 *
 * The worker URL goes in the iOS app's ProxyConfig.swift as `proxyURL`.
 *
 * To restrict to your own app add a shared secret:
 *   wrangler secret put ONA_SECRET
 * Then set the same value in ProxyConfig.swift as `proxySecret`.
 * The worker checks the X-Ona-Secret header and rejects other callers.
 */

export default {
  async fetch(request, env) {
    // CORS pre-flight
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders() });
    }

    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    // Optional shared-secret gate
    if (env.ONA_SECRET) {
      const incoming = request.headers.get("X-Ona-Secret") ?? "";
      if (incoming !== env.ONA_SECRET) {
        return json({ error: "Unauthorized" }, 401);
      }
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON" }, 400);
    }

    const prompt = body?.prompt;
    if (typeof prompt !== "string" || prompt.trim() === "") {
      return json({ error: "Missing prompt" }, 400);
    }

    const anthropicBody = {
      model: "claude-haiku-4-5-20251001",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
    };

    const upstream = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify(anthropicBody),
    });

    if (!upstream.ok) {
      const err = await upstream.text();
      return json({ error: "Upstream error", detail: err }, upstream.status);
    }

    const data = await upstream.json();
    const text = data?.content?.[0]?.text ?? "";

    return json({ text }, 200);
  },
};

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Ona-Secret",
  };
}
