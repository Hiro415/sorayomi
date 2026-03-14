import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const openaiApiKey = defineSecret("OPENAI_API_KEY");

interface ReadingRequest {
  systemPrompt: string;
  userPrompt: string;
  conversationHistory?: Array<{ role: string; content: string }>;
  model?: string;
}

/**
 * HTTPS Cloud Function: generateReading
 *
 * Proxies AI reading requests to OpenAI, keeping the API key server-side.
 * Called from the iOS app via URLSession POST.
 */
export const generateReading = onRequest(
  { secrets: [openaiApiKey], cors: true },
  async (req, res) => {
    // Only allow POST
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const {
      systemPrompt,
      userPrompt,
      conversationHistory = [],
      model,
    } = req.body as ReadingRequest;

    // Validate required fields
    if (!systemPrompt || !userPrompt) {
      res
        .status(400)
        .json({ error: "systemPrompt and userPrompt are required" });
      return;
    }

    // Build messages array for OpenAI
    const messages: Array<{ role: string; content: string }> = [
      { role: "system", content: systemPrompt },
    ];

    for (const entry of conversationHistory) {
      messages.push({ role: entry.role, content: entry.content });
    }
    messages.push({ role: "user", content: userPrompt });

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
            model: model || "gpt-4o-mini",
            messages,
            max_tokens: 1024,
            temperature: 0.85,
          }),
        }
      );

      if (!response.ok) {
        const errorBody = await response.text();
        if (response.status === 429) {
          res.status(429).json({ error: "Rate limited by OpenAI" });
          return;
        }
        console.error(`OpenAI error ${response.status}: ${errorBody}`);
        res
          .status(502)
          .json({ error: `AI provider error: ${response.status}` });
        return;
      }

      const json = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      const text = json.choices?.[0]?.message?.content;

      if (!text) {
        res.status(502).json({ error: "Empty response from AI provider" });
        return;
      }

      res.status(200).json({ text });
    } catch (error) {
      console.error("Error calling OpenAI:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
