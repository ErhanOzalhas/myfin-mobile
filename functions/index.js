const {initializeApp} = require("firebase-admin/app");
const {defineSecret} = require("firebase-functions/params");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {URL} = require("node:url");

initializeApp();

const openAiApiKey = defineSecret("OPENAI_API_KEY");
const apiNinjasApiKey = defineSecret("API_NINJAS_API_KEY");
const openAiModel = "gpt-5.6-terra";

const maxPromptCharacters = 12000;
const openAiEndpoint = "https://api.openai.com/v1/responses";

const commodityDefinitions = {
  "GRAM_GUMUS": {
    name: "silver",
    displayName: "Gram Gümüş",
    currency: "TRY",
    unit: "g",
  },
  "BRENT/USD": {
    name: "brent_crude_oil",
    displayName: "Brent Petrol",
    currency: "USD",
  },
  "WHEAT/USD": {
    name: "wheat",
    displayName: "Buğday",
    currency: "USD",
  },
};

exports.myFinCommodityQuote = onCall(
  {
    region: "europe-west1",
    secrets: [apiNinjasApiKey],
    timeoutSeconds: 20,
    memory: "256MiB",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Emtia fiyatını görmek için oturum açmalısınız.",
      );
    }

    const symbol = normalizeText(request.data?.symbol).toUpperCase();
    const definition = commodityDefinitions[symbol];
    if (!definition) {
      throw new HttpsError("invalid-argument", "Desteklenmeyen emtia.");
    }

    const url = new URL("https://api.api-ninjas.com/v1/commodityprice");
    url.searchParams.set("name", definition.name);
    if (definition.currency) {
      url.searchParams.set("currency", definition.currency);
    }
    if (definition.unit) url.searchParams.set("unit", definition.unit);

    const response = await fetch(url, {
      headers: {"X-Api-Key": apiNinjasApiKey.value()},
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      console.error("API Ninjas commodity request failed", {
        symbol,
        status: response.status,
      });
      if (response.status === 429) {
        throw new HttpsError(
          "resource-exhausted",
          "Emtia veri kullanım limiti doldu.",
        );
      }
      throw new HttpsError(
        "unavailable",
        "Emtia fiyatı geçici olarak alınamıyor.",
      );
    }

    const price = finiteNumber(payload.price);
    if (price <= 0) {
      throw new HttpsError("data-loss", "Emtia sağlayıcısı geçersiz fiyat döndürdü.");
    }
    const updatedSeconds = finiteNumber(payload.updated);

    return {
      symbol,
      name: definition.displayName,
      exchange: normalizeText(payload.exchange) || "COMMODITY",
      currency: normalizeText(payload.currency_unit) || "USD",
      unit: normalizeText(payload.unit),
      price,
      change: finiteNumber(payload.change_24h),
      changePercent: finiteNumber(payload.change_24h_percent),
      previousClose: finiteNumber(payload.previous_close),
      high: finiteNumber(payload.high_24h),
      low: finiteNumber(payload.low_24h),
      updatedAt: updatedSeconds > 0
        ? new Date(updatedSeconds * 1000).toISOString()
        : new Date().toISOString(),
    };
  },
);

exports.myFinAi = onCall(
  {
    region: "europe-west1",
    secrets: [openAiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "AI özelliğini kullanmak için oturum açmalısınız.",
      );
    }

    const instructions = normalizeText(request.data?.instructions);
    const input = normalizeText(request.data?.input);
    const webSearch = request.data?.webSearch === true;

    if (!input) {
      throw new HttpsError("invalid-argument", "AI sorusu boş olamaz.");
    }
    if (input.length > maxPromptCharacters) {
      throw new HttpsError(
        "invalid-argument",
        "AI isteği izin verilen uzunluğu aşıyor.",
      );
    }

    const requestBody = {
      model: openAiModel,
      instructions: webSearch
        ? `${instructions}\n\nGüncel haber araştırmasında güvenilir ve doğrudan kaynakları tercih et. Her haberin tarihini belirt. Yanıtın sonunda Kaynaklar başlığı altında bağlantıları listele. Haber ile fiyat hareketi arasında kanıtlanmamış nedensellik kurma.`
        : instructions,
      input,
      reasoning: {effort: "none"},
      text: {verbosity: webSearch ? "medium" : "low"},
      ...(webSearch ? {
        tools: [{type: "web_search"}],
        tool_choice: "required",
      } : {}),
    };

    const response = await fetch(openAiEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${openAiApiKey.value()}`,
      },
      body: JSON.stringify(requestBody),
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      console.error("OpenAI request failed", {
        status: response.status,
        type: payload?.error?.type,
        code: payload?.error?.code,
      });
      throw mapOpenAiError(response.status);
    }

    const text = extractOutputText(payload);
    console.info("MyFin AI response", {
      webSearchRequested: webSearch,
      webSearchUsed: (payload.output ?? []).some(
        (item) => item.type === "web_search_call",
      ),
      sourceCount: countUrlCitations(payload),
    });
    if (!text) {
      throw new HttpsError(
        "internal",
        "AI servisi boş bir yanıt döndürdü.",
      );
    }

    return {
      text,
      model: payload.model ?? openAiModel,
    };
  },
);

function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function finiteNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : 0;
}

function countUrlCitations(payload) {
  const urls = new Set();
  for (const item of payload.output ?? []) {
    for (const content of item.content ?? []) {
      for (const annotation of content.annotations ?? []) {
        const url = normalizeText(annotation.url);
        if (url) urls.add(url);
      }
    }
  }
  return urls.size;
}

function extractOutputText(payload) {
  if (typeof payload.output_text === "string") {
    return payload.output_text.trim();
  }

  const parts = [];
  const sources = new Map();
  for (const item of payload.output ?? []) {
    for (const content of item.content ?? []) {
      if (typeof content.text === "string" && content.text.trim()) {
        parts.push(content.text.trim());
      }
      for (const annotation of content.annotations ?? []) {
        const url = normalizeText(annotation.url);
        if (!url || sources.has(url)) continue;
        sources.set(url, normalizeText(annotation.title) || "Kaynak");
      }
    }
  }
  const answer = parts.join("\n").trim();
  if (!answer || sources.size === 0) return answer;
  const sourceList = [...sources.entries()]
    .slice(0, 8)
    .map(([url, title]) => `- [${title}](${url})`)
    .join("\n");
  if (answer.includes("## Kaynaklar") || answer.includes("**Kaynaklar**")) {
    return answer;
  }
  return `${answer}\n\n**Kaynaklar**\n${sourceList}`;
}

function mapOpenAiError(status) {
  if (status === 429) {
    return new HttpsError(
      "resource-exhausted",
      "AI kullanım limiti doldu. Lütfen biraz sonra tekrar deneyin.",
    );
  }
  if (status === 401 || status === 403) {
    return new HttpsError(
      "failed-precondition",
      "AI servisinin sunucu yapılandırması tamamlanmamış.",
    );
  }
  if (status >= 500) {
    return new HttpsError(
      "unavailable",
      "AI servisi geçici olarak kullanılamıyor.",
    );
  }
  return new HttpsError("internal", "AI isteği işlenemedi.");
}
