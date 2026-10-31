/**
 * BroML Cloudflare Edge Security Worker
 * Implements Edge-Level Rate Limiting, Turnstile Validation, WAF Rules & Origin Protection
 */

const ORIGIN_SECRET_HEADER = "X-BroML-Origin-Secret";
const TURNSTILE_SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify";

// Edge Rate Limit Windows (in-memory per worker edge location)
const rateLimitMap = new Map();

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const clientIp = request.headers.get("CF-Connecting-IP") || "127.0.0.1";
    const userAgent = request.headers.get("User-Agent") || "";
    const country = request.headers.get("CF-IPCountry") || "XX";
    const rayId = request.headers.get("CF-Ray") || "unknown";

    // 1. WAF & Bot Defense: Block known malicious scanners and empty user-agents
    if (!userAgent || userAgent.includes("masscan") || userAgent.includes("sqlmap") || userAgent.includes("nikto")) {
      return new Response(JSON.stringify({ error: "Access denied by BroML Cloudflare Edge WAF." }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Edge Rate Limiting for Authentication Endpoints
    const isAuthRoute = url.pathname.includes("/login") || url.pathname.includes("/register") || url.pathname.includes("/mfa");
    if (isAuthRoute) {
      const now = Date.now();
      const ipHistory = rateLimitMap.get(clientIp) || [];
      const recentAttempts = ipHistory.filter((timestamp) => now - timestamp < 60000); // 1-minute window

      if (recentAttempts.length >= 10) {
        return new Response(
          JSON.stringify({
            error: "Too many authentication requests from this IP. Blocked by Cloudflare Edge Rate Limiter.",
            retryAfter: 60,
            rayId: rayId,
          }),
          {
            status: 429,
            headers: {
              "Content-Type": "application/json",
              "Retry-After": "60",
              "CF-Ray": rayId,
            },
          }
        );
      }

      recentAttempts.push(now);
      rateLimitMap.set(clientIp, recentAttempts);
    }

    // 3. Cloudflare Turnstile Server-Side Validation Route
    if (url.pathname === "/api/turnstile/verify" && request.method === "POST") {
      try {
        const body = await request.json();
        const turnstileToken = body.token;
        const secretKey = env.TURNSTILE_SECRET_KEY || "0x4AAAAAAAT_TurnstileDemoSecretKey";

        if (!turnstileToken) {
          return new Response(JSON.stringify({ success: false, error: "Missing Turnstile token" }), {
            status: 400,
            headers: { "Content-Type": "application/json" },
          });
        }

        const formData = new FormData();
        formData.append("secret", secretKey);
        formData.append("response", turnstileToken);
        formData.append("remoteip", clientIp);

        const verifyRes = await fetch(TURNSTILE_SITEVERIFY_URL, {
          method: "POST",
          body: formData,
        });

        const verifyData = await verifyRes.json();
        return new Response(JSON.stringify(verifyData), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      } catch (err) {
        return new Response(JSON.stringify({ success: false, error: err.message }), {
          status: 500,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    // 4. Origin Protection: Attach signed header before forwarding to backend origin
    const originHeaders = new Headers(request.headers);
    originHeaders.set(ORIGIN_SECRET_HEADER, env.ORIGIN_SECRET || "broml-production-origin-verified-secret");
    originHeaders.set("X-Forwarded-For", clientIp);
    originHeaders.set("X-Forwarded-Country", country);
    originHeaders.set("X-Cloudflare-Ray", rayId);

    const originRequest = new Request(request, {
      headers: originHeaders,
    });

    const response = await fetch(originRequest);

    // 5. Inject Strict Security Headers into Response
    const secureHeaders = new Headers(response.headers);
    secureHeaders.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload");
    secureHeaders.set("X-Content-Type-Options", "nosniff");
    secureHeaders.set("X-Frame-Options", "SAMEORIGIN");
    secureHeaders.set("Referrer-Policy", "strict-origin-when-cross-origin");
    secureHeaders.set("Permissions-Policy", "camera=(self), microphone=(), geolocation=()");
    secureHeaders.set("X-Cloudflare-Ray", rayId);

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: secureHeaders,
    });
  },
};

