-- Optional M-Pesa receipt number (extracted from STK callback metadata)
alter table public.mpesa_callback_results
  add column if not exists mpesa_receipt_number text default '';

comment on column public.mpesa_callback_results.mpesa_receipt_number is 'MpesaReceiptNumber from Safaricom STK callback metadata';
