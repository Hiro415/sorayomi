import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getAppCheck } from "firebase-admin/app-check";
import { initializeApp } from "firebase-admin/app";

// Initialize Firebase Admin
initializeApp();

const openaiApiKey = defineSecret("OPENAI_API_KEY");

// ============================================================
// Rate Limiting (in-memory, resets on cold start)
// ============================================================

interface RateLimitEntry {
  timestamps: number[];
}

const rateLimitMap = new Map<string, RateLimitEntry>();

const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
const RATE_LIMIT_MAX_REQUESTS = 30; // per IP per window
const GLOBAL_RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const GLOBAL_RATE_LIMIT_MAX = 1000; // total requests per hour

let globalTimestamps: number[] = [];

function isRateLimited(ip: string): boolean {
  const now = Date.now();

  // --- Global rate limit ---
  globalTimestamps = globalTimestamps.filter(
    (t) => now - t < GLOBAL_RATE_LIMIT_WINDOW_MS
  );
  if (globalTimestamps.length >= GLOBAL_RATE_LIMIT_MAX) {
    return true;
  }

  // --- Per-IP rate limit ---
  const entry = rateLimitMap.get(ip) || { timestamps: [] };
  entry.timestamps = entry.timestamps.filter(
    (t) => now - t < RATE_LIMIT_WINDOW_MS
  );

  if (entry.timestamps.length >= RATE_LIMIT_MAX_REQUESTS) {
    return true;
  }

  entry.timestamps.push(now);
  rateLimitMap.set(ip, entry);
  globalTimestamps.push(now);
  return false;
}

// ============================================================
// PII Scrubbing
// ============================================================

function scrubPII(text: string): string {
  let scrubbed = text;

  // Japanese phone numbers: 090-1234-5678, 09012345678, 03-1234-5678, etc.
  scrubbed = scrubbed.replace(
    /0[0-9]{1,4}[-\s]?[0-9]{1,4}[-\s]?[0-9]{3,4}/g,
    "[電話番号]"
  );

  // Email addresses
  scrubbed = scrubbed.replace(
    /[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/g,
    "[メールアドレス]"
  );

  // Japanese postal codes: 〒123-4567 or 123-4567
  scrubbed = scrubbed.replace(/〒?\d{3}[-\s]?\d{4}/g, "[郵便番号]");

  // Credit card numbers: 16 digits with optional separators
  scrubbed = scrubbed.replace(
    /\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}/g,
    "[カード番号]"
  );

  // My Number (マイナンバー): exactly 12 consecutive digits
  scrubbed = scrubbed.replace(/(?<!\d)\d{12}(?!\d)/g, "[個人番号]");

  // Japanese full names with specific patterns (名前 + さん/様/氏)
  // Intentionally conservative — only scrub when clearly a name reference
  scrubbed = scrubbed.replace(
    /([一-龯ぁ-んァ-ヶ]{1,4})\s*([一-龯]{1,4})\s*(さん|様|氏|くん|ちゃん)/g,
    "[お名前]$3"
  );

  return scrubbed;
}

// ============================================================
// Input Validation
// ============================================================

const MAX_SYSTEM_PROMPT_LENGTH = 15000;
const MAX_USER_PROMPT_LENGTH = 10000;
const MAX_CONVERSATION_MESSAGES = 20;
const MAX_MESSAGE_LENGTH = 5000;
const MAX_PAYLOAD_BYTES = 100 * 1024; // 100KB

// NOTE: model is intentionally NOT in the request interface — the model is
// server-controlled to prevent cost attacks via arbitrary model selection.
const OPENAI_MODEL = "gpt-4o-mini";

interface ReadingRequest {
  systemPrompt: string;
  userPrompt: string;
  conversationHistory?: Array<{ role: string; content: string }>;
}

function validateRequest(
  body: ReadingRequest
): { valid: true } | { valid: false; error: string } {
  const { systemPrompt, userPrompt, conversationHistory = [] } = body;

  if (!systemPrompt || !userPrompt) {
    return { valid: false, error: "systemPrompt and userPrompt are required" };
  }

  if (typeof systemPrompt !== "string" || typeof userPrompt !== "string") {
    return { valid: false, error: "Prompts must be strings" };
  }

  if (systemPrompt.length > MAX_SYSTEM_PROMPT_LENGTH) {
    return {
      valid: false,
      error: `systemPrompt exceeds ${MAX_SYSTEM_PROMPT_LENGTH} characters`,
    };
  }

  if (userPrompt.length > MAX_USER_PROMPT_LENGTH) {
    return {
      valid: false,
      error: `userPrompt exceeds ${MAX_USER_PROMPT_LENGTH} characters`,
    };
  }

  if (!Array.isArray(conversationHistory)) {
    return { valid: false, error: "conversationHistory must be an array" };
  }

  if (conversationHistory.length > MAX_CONVERSATION_MESSAGES) {
    return {
      valid: false,
      error: `conversationHistory exceeds ${MAX_CONVERSATION_MESSAGES} messages`,
    };
  }

  for (const msg of conversationHistory) {
    if (!msg.role || !msg.content) {
      return {
        valid: false,
        error: "Each message must have role and content",
      };
    }
    if (!["user", "assistant", "system"].includes(msg.role)) {
      return { valid: false, error: `Invalid message role: ${msg.role}` };
    }
    if (msg.content.length > MAX_MESSAGE_LENGTH) {
      return {
        valid: false,
        error: `Message content exceeds ${MAX_MESSAGE_LENGTH} characters`,
      };
    }
  }

  return { valid: true };
}

// ============================================================
// Logging (privacy-safe)
// ============================================================

function hashIP(ip: string): string {
  // Simple hash for logging — not reversible to original IP
  let hash = 0;
  for (let i = 0; i < ip.length; i++) {
    const char = ip.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return Math.abs(hash).toString(16).padStart(8, "0");
}

// ============================================================
// Cloud Function: generateReading
// ============================================================

export const generateReading = onRequest(
  {
    secrets: [openaiApiKey],
    cors: false, // Native iOS app only — no browser CORS needed
  },
  async (req, res) => {
    // Use req.ip (Cloud Run trusted IP) — never trust x-forwarded-for from client
    const clientIP = req.ip || "unknown";
    const ipHash = hashIP(clientIP);

    // --- Method check ---
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    // --- Payload size check ---
    const contentLength = parseInt(req.headers["content-length"] || "0", 10);
    if (contentLength > MAX_PAYLOAD_BYTES) {
      res.status(413).json({ error: "Payload too large" });
      return;
    }

    // --- App Check verification (required) ---
    // Reject requests that carry no App Check token at all — this is the
    // critical gate that stops arbitrary callers from hitting this endpoint.
    const appCheckToken = req.headers["x-firebase-appcheck"] as string;
    if (!appCheckToken) {
      console.warn(`[${ipHash}] Missing App Check token`);
      res.status(401).json({ error: "Unauthorized" });
      return;
    }
    try {
      await getAppCheck().verifyToken(appCheckToken);
    } catch {
      console.warn(`[${ipHash}] Invalid App Check token`);
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    // --- Rate limiting ---
    if (isRateLimited(clientIP)) {
      console.warn(`[${ipHash}] Rate limited`);
      res.set("Retry-After", "900"); // 15 minutes
      res.status(429).json({ error: "Too many requests. Please try later." });
      return;
    }

    // --- Input validation ---
    const body = req.body as ReadingRequest;
    const validation = validateRequest(body);
    if (!validation.valid) {
      res.status(400).json({ error: validation.error });
      return;
    }

    const { systemPrompt, userPrompt, conversationHistory = [] } = body;

    // --- PII scrubbing ---
    const cleanSystemPrompt = scrubPII(systemPrompt);
    const cleanUserPrompt = scrubPII(userPrompt);
    const cleanHistory = conversationHistory.map((msg) => ({
      role: msg.role,
      content: scrubPII(msg.content),
    }));

    // --- Build OpenAI messages ---
    const messages: Array<{ role: string; content: string }> = [
      { role: "system", content: cleanSystemPrompt },
    ];
    for (const entry of cleanHistory) {
      messages.push({ role: entry.role, content: entry.content });
    }
    messages.push({ role: "user", content: cleanUserPrompt });

    // --- Call OpenAI ---
    try {
      const response = await fetch(
        "https://api.openai.com/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${openaiApiKey.value()}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: OPENAI_MODEL,
            messages,
            max_tokens: 2048,
            temperature: 0.85,
            store: false, // Do NOT store data for OpenAI training
          }),
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        if (response.status === 429) {
          console.warn(`[${ipHash}] OpenAI rate limited`);
          res.status(429).json({ error: "Service busy. Please try later." });
          return;
        }
        // Log error details server-side only (never expose to client)
        console.error(`[${ipHash}] OpenAI error ${response.status}: ${errorText}`);
        res
          .status(502)
          .json({ error: "AI provider error" });
        return;
      }

      const json = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
        usage?: { prompt_tokens?: number; completion_tokens?: number };
      };
      const text = json.choices?.[0]?.message?.content;

      if (!text) {
        console.error(`[${ipHash}] Empty response from OpenAI`);
        res.status(502).json({ error: "Empty response from AI provider" });
        return;
      }

      // Privacy-safe logging: only metadata, never content
      console.info(
        `[${ipHash}] OK | tokens: ${json.usage?.prompt_tokens ?? "?"}+${json.usage?.completion_tokens ?? "?"}`
      );

      res.status(200).json({ text });
    } catch (error) {
      console.error(`[${ipHash}] Internal error:`, (error as Error).message);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
