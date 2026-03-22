// Supabase Edge Function: initiate M-Pesa STK Push
// Invoke with: { "amount": 100.50, "phone": "254712345678", "reference": "POS001", "mpesa_config": { ... } }
// Optional mpesa_config merges on top of shop_configs so the app and Edge Function use the same credentials.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function getTimestamp(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  const h = String(now.getHours()).padStart(2, "0");
  const min = String(now.getMinutes()).padStart(2, "0");
  const s = String(now.getSeconds()).padStart(2, "0");
  return `${y}${m}${d}${h}${min}${s}`;
}

function base64Encode(str: string): string {
  return btoa(str);
}

/** Non-empty client values override DB (same credentials as Flutter Shop Settings). */
function mergeMpesaConfig(
  db: Record<string, unknown> | null,
  client: Record<string, unknown> | undefined,
): Record<string, unknown> {
  const out: Record<string, unknown> = { ...(db ?? {}) };
  if (!client) return out;
  const keys = [
    "mpesa_consumer_key",
    "mpesa_consumer_secret",
    "mpesa_passkey",
    "mpesa_shortcode",
    "mpesa_till_number",
    "mpesa_base_url",
    "mpesa_callback_url",
    "mpesa_transaction_type",
    "mpesa_is_sandbox",
  ];
  for (const k of keys) {
    const v = client[k];
    if (v === undefined || v === null) continue;
    if (typeof v === "boolean") {
      out[k] = v;
      continue;
    }
    const s = String(v).trim();
    if (s !== "") out[k] = v;
  }
  return out;
}

/** Postgres/JSON sometimes returns booleans as strings; Daraja sandbox flag must be a real boolean. */
function normalizeSandboxFlag(config: Record<string, unknown>): void {
  const v = config.mpesa_is_sandbox;
  if (typeof v === "string") {
    const s = v.trim().toLowerCase();
    config.mpesa_is_sandbox = s === "true" || s === "1" || s === "yes";
  }
}

function envOr(key: string, fallback: string): string {
  return (Deno.env.get(key) ?? "").trim() || fallback;
}

/**
 * Bundled demo credentials — only used when OAuth keys are also missing.
 * NEVER fill shortcode/passkey/till from defaults when the user already set Consumer Key/Secret:
 * OAuth would succeed with live keys but STK Password would use the wrong shortcode+passkey → "Merchant does not exist".
 */
function applyFallbackDefaults(config: Record<string, unknown>): Record<string, unknown> {
  const c = { ...config };
  const fk = envOr("MPESA_CONSUMER_KEY", "4aEia8VMAGLQU28ZoorLQRZtMutc6A6GyGXMq9HYoNFyXNOY");
  const fs = envOr("MPESA_CONSUMER_SECRET", "wMdKEDv2y2JZQ8ZdN1TAn4MgxbuILwrNsOu4ywi6QcVZJw4BrlEclAcW4XSduSlw");
  const fp = envOr("MPESA_PASSKEY", "fc087de2729c7ff67b2b2b3aacc2068039fc56284c676d56679ef86f70640d8d");
  const fsc = envOr("MPESA_SHORTCODE", "3560959");
  const ftill = envOr("MPESA_TILL_NUMBER", "6509715");
  const fcb = envOr("MPESA_CALLBACK_URL", "");

  const hasKey = String(c.mpesa_consumer_key ?? "").trim() !== "";
  const hasSecret = String(c.mpesa_consumer_secret ?? "").trim() !== "";
  const useBundledDemo = !hasKey && !hasSecret;

  if (useBundledDemo) {
    if (!(String(c.mpesa_consumer_key ?? "").trim())) c.mpesa_consumer_key = fk;
    if (!(String(c.mpesa_consumer_secret ?? "").trim())) c.mpesa_consumer_secret = fs;
    if (!(String(c.mpesa_passkey ?? "").trim())) c.mpesa_passkey = fp;
    if (!(String(c.mpesa_shortcode ?? "").trim())) c.mpesa_shortcode = fsc;
    if (!(String(c.mpesa_till_number ?? "").trim())) c.mpesa_till_number = ftill;
  }

  if (!(String(c.mpesa_callback_url ?? "").trim())) {
    if (fcb) c.mpesa_callback_url = fcb;
    else {
      const u = Deno.env.get("SUPABASE_URL");
      if (u) c.mpesa_callback_url = `${u.replace(/\/$/, "")}/functions/v1/mpesa-callback`;
    }
  }
  if (!(String(c.mpesa_base_url ?? "").trim())) c.mpesa_base_url = "https://api.safaricom.co.ke";
  if (c.mpesa_transaction_type == null || String(c.mpesa_transaction_type).trim() === "") {
    c.mpesa_transaction_type = "CustomerBuyGoodsOnline";
  }
  return c;
}

function extractStkErrorMessage(stkData: Record<string, unknown>): string {
  const top = stkData?.errorMessage ?? stkData?.errorCode;
  if (top) return String(top);
  const fault = stkData?.fault as Record<string, unknown> | undefined;
  if (fault?.faultstring) return String(fault.faultstring);
  const detail = stkData?.detail as Record<string, unknown> | undefined;
  if (detail?.errorMessage) return String(detail.errorMessage);
  if (detail?.message) return String(detail.message);
  if (detail?.error && typeof detail.error === "object") {
    const e = detail.error as Record<string, unknown>;
    if (e.errorMessage) return String(e.errorMessage);
  }
  return "";
}

function responseCodeOk(stkData: Record<string, unknown>): boolean {
  const rc = stkData.ResponseCode;
  if (rc === undefined || rc === null) return false;
  const s = String(rc).trim();
  return s === "0" || Number(rc) === 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json();
    const { amount, phone, reference, mpesa_config: clientMpesa } = body as {
      amount?: number;
      phone?: string;
      reference?: string;
      mpesa_config?: Record<string, unknown>;
    };

    if (!amount || !phone) {
      return new Response(
        JSON.stringify({ error: "amount and phone required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: dbRow, error: configError } = await supabase
      .from("shop_configs")
      .select("*")
      .limit(1)
      .maybeSingle();

    let config = mergeMpesaConfig(
      (dbRow ?? {}) as Record<string, unknown>,
      clientMpesa,
    );
    config = applyFallbackDefaults(config);
    normalizeSandboxFlag(config);

    if (configError && !dbRow) {
      console.warn("shop_configs read:", configError);
    }

    const consumerKey = String(config.mpesa_consumer_key || "");
    const consumerSecret = String(config.mpesa_consumer_secret || "");
    const passkey = String(config.mpesa_passkey || "");
    let baseUrl = (String(config.mpesa_base_url || "https://api.safaricom.co.ke")).replace(/\/$/, "");
    const sandbox =
      config.mpesa_is_sandbox === true ||
      String(config.mpesa_is_sandbox) === "true";
    if (sandbox) {
      baseUrl = "https://sandbox.safaricom.co.ke";
    }
    const callbackUrl = String(config.mpesa_callback_url || "");
    const transactionType = String(config.mpesa_transaction_type || "CustomerBuyGoodsOnline");
    const shortcodeRaw = String(config.mpesa_shortcode || "").trim();
    const tillRaw = String(config.mpesa_till_number || "").trim();

    // STK Password = Base64(BusinessShortCode + Passkey + Timestamp). Daraja validates this against the same identifiers used in PartyB for your transaction type.
    // CustomerBuyGoodsOnline: use Till for both password (BusinessShortCode field) and PartyB when till is set — avoids paybill/till mismatch "Merchant does not exist".
    // CustomerPayBillOnline: Paybill (shortcode) for both.
    let businessShortCode: string;
    let partyB: string;
    const isPayBill = transactionType === "CustomerPayBillOnline";
    if (isPayBill) {
      businessShortCode = shortcodeRaw || tillRaw;
      partyB = businessShortCode;
    } else {
      // Buy Goods: prefer Till for BusinessShortCode + PartyB so password matches receiver.
      businessShortCode = tillRaw || shortcodeRaw;
      partyB = businessShortCode;
    }

    if (!consumerKey || !consumerSecret || !passkey || !callbackUrl || !businessShortCode) {
      return new Response(
        JSON.stringify({
          error: "M-Pesa incomplete. Set Consumer Key, Consumer Secret, Passkey, Callback URL, and Till/Shortcode in Shop Settings (or MPESA_* secrets on the function).",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const auth = base64Encode(`${consumerKey}:${consumerSecret}`);
    const tokenRes = await fetch(`${baseUrl}/oauth/v1/generate?grant_type=client_credentials`, {
      method: "GET",
      headers: { Authorization: `Basic ${auth}` },
    });

    if (!tokenRes.ok) {
      const text = await tokenRes.text();
      return new Response(
        JSON.stringify({
          error: "OAuth failed",
          detail: text,
          hint: sandbox
            ? "Use sandbox Consumer Key/Secret with Sandbox enabled (or sandbox host)."
            : "Check Consumer Key/Secret match production Daraja app.",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;
    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: "No access_token from OAuth" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const timestamp = getTimestamp();
    const password = base64Encode(`${businessShortCode}${passkey}${timestamp}`);

    const phoneNum = String(phone).replace(/\D/g, "");
    const partyA = phoneNum.startsWith("254") ? phoneNum : `254${phoneNum.replace(/^0/, "")}`;
    const amountInt = Math.round(Number(amount));

    const stkBody = {
      BusinessShortCode: Number(businessShortCode),
      Password: password,
      Timestamp: timestamp,
      TransactionType: transactionType,
      Amount: amountInt,
      PartyA: Number(partyA),
      PartyB: Number(partyB),
      PhoneNumber: Number(partyA),
      CallBackURL: callbackUrl,
      AccountReference: (reference || "POS").slice(0, 12),
      TransactionDesc: "POS Payment",
    };

    const stkRes = await fetch(`${baseUrl}/mpesa/stkpush/v1/processrequest`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(stkBody),
    });

    let stkData: Record<string, unknown>;
    try {
      stkData = await stkRes.json();
    } catch {
      const t = await stkRes.text();
      return new Response(
        JSON.stringify({ error: "Invalid JSON from Daraja STK", detail: t }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Daraja sometimes returns HTTP 200 with { errorCode, errorMessage } and no CheckoutRequestID
    if (stkData.errorCode || stkData.errorMessage) {
      const msg = String(stkData.errorMessage ?? stkData.errorCode ?? "STK error");
      return new Response(
        JSON.stringify({
          error: "STK Push request failed",
          message: msg,
          detail: stkData,
          hint:
            msg.includes("Merchant") || msg.includes("500.001.1001")
              ? "Check: (1) Sandbox vs production keys. (2) Passkey from Lipa Na M-Pesa Online for this shortcode/till. (3) Buy Goods: put Till in Till Number (password uses Till when set). (4) Callback URL reachable."
              : undefined,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const nestedFault = extractStkErrorMessage(stkData);
    if (!stkRes.ok) {
      const msg = nestedFault || JSON.stringify(stkData);
      return new Response(
        JSON.stringify({
          error: "STK Push request failed",
          detail: stkData,
          message: msg,
          hint:
            String(msg).includes("Merchant does not exist") || String(msg).includes("500.001.1001")
              ? "Check: (1) Consumer Key/Secret match this environment (sandbox vs production). (2) Shortcode matches the passkey in Daraja. (3) For Buy Goods, set Paybill in Shortcode and Till in Till Number. (4) Turn on Sandbox in Shop Settings if using sandbox keys."
              : undefined,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!responseCodeOk(stkData)) {
      const responseDesc = String(stkData.ResponseDescription || "");
      const merchantErr =
        responseDesc.includes("Merchant") ||
        responseDesc.includes("does not exist") ||
        responseDesc.includes("500.001.1001");
      return new Response(
        JSON.stringify({
          error: responseDesc || "STK push rejected",
          responseCode: stkData.ResponseCode,
          checkoutRequestId: stkData.CheckoutRequestID || null,
          hint: merchantErr
            ? "Merchant/shortcode mismatch: for Buy Goods ensure Till Number matches Daraja; passkey must be for the same Lipa Na M-Pesa credentials as Consumer Key."
            : undefined,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const checkoutRequestId = stkData.CheckoutRequestID;
    const merchantRequestId = stkData.MerchantRequestID;

    return new Response(
      JSON.stringify({
        success: true,
        checkoutRequestId,
        merchantRequestId,
        message: "STK push sent. Ask customer to enter PIN.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
