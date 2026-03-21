// Supabase Edge Function: initiate M-Pesa STK Push
// Invoke with: { "amount": 100.50, "phone": "254712345678", "reference": "POS001" }
// Requires shop_configs to have M-Pesa credentials and mpesa_callback_url set.

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { amount, phone, reference } = await req.json();
    if (!amount || !phone) {
      return new Response(
        JSON.stringify({ error: "amount and phone required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: config, error: configError } = await supabase
      .from("shop_configs")
      .select("*")
      .limit(1)
      .single();

    if (configError || !config) {
      return new Response(
        JSON.stringify({ error: "M-Pesa not configured. Set shop_configs." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const consumerKey = config.mpesa_consumer_key || "";
    const consumerSecret = config.mpesa_consumer_secret || "";
    const passkey = config.mpesa_passkey || "";
    let baseUrl = (config.mpesa_base_url || "https://api.safaricom.co.ke").replace(/\/$/, "");
    // Sandbox credentials MUST call sandbox host or Daraja returns e.g. 500.001.1001 "Merchant does not exist"
    if (config.mpesa_is_sandbox === true) {
      baseUrl = "https://sandbox.safaricom.co.ke";
    }
    const callbackUrl = config.mpesa_callback_url || "";
    const transactionType = config.mpesa_transaction_type || "CustomerBuyGoodsOnline";
    const shortcodeRaw = String(config.mpesa_shortcode || "").trim();
    const tillRaw = String(config.mpesa_till_number || "").trim();

    // Passkey is issued for a specific BusinessShortCode (Paybill / head office).
    // Buy Goods: BusinessShortCode = Paybill, PartyB = Till.
    // Pay Bill: PartyB is typically the same as BusinessShortCode (Paybill).
    let businessShortCode: string;
    let partyB: string;
    const isPayBill = transactionType === "CustomerPayBillOnline";
    if (isPayBill) {
      businessShortCode = shortcodeRaw || tillRaw;
      partyB = businessShortCode;
    } else if (shortcodeRaw && tillRaw) {
      businessShortCode = shortcodeRaw;
      partyB = tillRaw;
    } else {
      businessShortCode = tillRaw || shortcodeRaw;
      partyB = businessShortCode;
    }

    if (!consumerKey || !consumerSecret || !passkey || !callbackUrl || !businessShortCode) {
      return new Response(
        JSON.stringify({
          error: "M-Pesa incomplete. Set Consumer Key, Consumer Secret, Passkey, Callback URL, and Till/Shortcode.",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. OAuth token
    const auth = base64Encode(`${consumerKey}:${consumerSecret}`);
    const tokenRes = await fetch(`${baseUrl}/oauth/v1/generate?grant_type=client_credentials`, {
      method: "GET",
      headers: { Authorization: `Basic ${auth}` },
    });

    if (!tokenRes.ok) {
      const text = await tokenRes.text();
      return new Response(
        JSON.stringify({ error: "OAuth failed", detail: text }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;
    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: "No access_token from OAuth" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. STK Push
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

    const stkData = await stkRes.json();

    if (!stkRes.ok) {
      const nested = stkData?.requestId ? stkData : (stkData?.detail ?? stkData);
      const msg = nested?.errorMessage ?? nested?.message ?? stkData?.errorMessage ?? JSON.stringify(stkData);
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
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const checkoutRequestId = stkData.CheckoutRequestID;
    const merchantRequestId = stkData.MerchantRequestID;
    const responseCode = stkData.ResponseCode;
    const responseDesc = stkData.ResponseDescription || "";

    if (responseCode !== "0") {
      return new Response(
        JSON.stringify({
          error: responseDesc || "STK push rejected",
          responseCode,
          checkoutRequestId: checkoutRequestId || null,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        checkoutRequestId,
        merchantRequestId,
        message: "STK push sent. Ask customer to enter PIN.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
