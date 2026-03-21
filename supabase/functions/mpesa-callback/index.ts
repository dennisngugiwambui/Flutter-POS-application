// Supabase Edge Function: M-Pesa STK callback (Lipa Na M-Pesa Online)
// Safaricom POSTs the payment result here. We store it in mpesa_callback_results
// so the app can poll by checkout_request_id.
// Register this URL in Daraja portal: https://YOUR_PROJECT.supabase.co/functions/v1/mpesa-callback

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function extractMpesaReceiptNumber(stkCallback: Record<string, unknown>): string {
  const meta = stkCallback.CallbackMetadata as { Item?: Array<{ Name?: string; Value?: unknown }> } | undefined;
  const items = meta?.Item;
  if (!Array.isArray(items)) return "";
  const found = items.find((x) => x.Name === "MpesaReceiptNumber");
  return found?.Value != null ? String(found.Value) : "";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ ResultCode: 0, ResultDesc: "Accepted" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const body = await req.json();

    // Daraja STK callback format: { Body: { stkCallback: { ... } } }
    const stkCallback = body?.Body?.stkCallback as Record<string, unknown> | undefined;
    if (!stkCallback) {
      return new Response(
        JSON.stringify({ ResultCode: 0, ResultDesc: "Accepted" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const checkoutRequestId = String(stkCallback.CheckoutRequestID || "");
    const merchantRequestId = String(stkCallback.MerchantRequestID || "");
    const resultCode = Number(stkCallback.ResultCode ?? -1);
    const resultDesc = String(stkCallback.ResultDesc || "");
    const mpesaReceiptNumber = extractMpesaReceiptNumber(stkCallback);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    await supabase.from("mpesa_callback_results").upsert(
      {
        checkout_request_id: checkoutRequestId,
        result_code: resultCode,
        result_desc: resultDesc,
        merchant_request_id: merchantRequestId,
        mpesa_receipt_number: mpesaReceiptNumber,
        payload: body,
      },
      { onConflict: "checkout_request_id" }
    );

    return new Response(
      JSON.stringify({
        ResultCode: 0,
        ResultDesc: "Success",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("mpesa-callback error:", e);
    return new Response(
      JSON.stringify({ ResultCode: 0, ResultDesc: "Accepted" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
