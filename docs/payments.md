# Real Estate Iraq — Payments

Two independent services, each **30,000 IQD** by default (editable by super admin in `payment_settings`, every change audit-logged):

| service_type | trigger | unlocks |
|---|---|---|
| PROPERTY_PUBLISHING | submitting a listing whose transaction type/category requires a fee (default: sale only) | property → `pending_approval` (moderation still required) |
| AI_VIDEO_GENERATION | confirming an AI Video Maker order | ai_job → `queued` |

## 1. Engine flow (provider-agnostic)
```
Flutter                 Backend /api/v1/payments                    Provider
  │ POST /orders {service, property_id|ai_job_id, provider}
  │   Idempotency-Key: <uuid generated once per checkout screen>
  │───────────────────────►│ 1 auth + ownership check
  │                        │ 2 price read from payment_settings (server, never client)
  │                        │ 3 reuse existing open order for same subject OR insert new
  │                        │ 4 adapter.createPayment(order) ───────────────►│
  │                        │◄─────────── provider payment id, links/QR/form │
  │◄── order + instructions│ 5 store payment_transaction, status=pending
  │ open FIB app link / Qi form (in-app browser)
  │                                                     user pays
  │                        │◄────────── webhook/callback (FIB status cb, Qi webhook)
  │                        │ 6 store raw event (dedup key) → NEVER trust payload alone
  │                        │ 7 adapter.getStatus(provider_payment_id) ─────►│ authoritative
  │                        │ 8 if PAID & amount==order.amount & currency==IQD:
  │                        │      SQL payment_mark_paid() (row lock, idempotent)
  │ poll GET /orders/:id (every 3s, max 10 min) or Realtime on own order row
  │◄── status=paid → success screen
```
Safety nets: a cron reconciler re-checks every `pending` transaction older than 2 min until expiry; expired provider payments mark the order `expired`; daily reconciliation report for admins.

## 2. Guarantees
- **No double charge:** partial unique index allows only one open-or-paid order per property publishing / per AI job; idempotency key unique; webhook events deduped by provider event key; `payment_mark_paid` is a no-op if already paid.
- **No fake success:** status only changes inside `payment_mark_paid`, executable by `service_role` only, after a server-to-server status call. Client "success" redirects are ignored except as a hint to poll.
- **Amount tampering:** mismatched amount/currency → order flagged `failed` with reason `AMOUNT_MISMATCH`, admin alerted, no unlock.
- **Integer money:** IQD as `bigint` (exponent 0); adapters convert to provider formats as strings.
- **Immutable history:** `payment_audit_logs` and `payment_provider_events` are append-only.
- **Refunds:** AI job permanently failed after free retries → `refund_pending` → finance admin approves → adapter.refund() where supported, else manual refund recorded with reference. Never silently kept.

## 3. Adapter interface (backend/src/payments/providers)
```ts
interface PaymentProviderAdapter {
  readonly id: 'FIB' | 'QI_CARD';
  mode(): 'unconfigured' | 'sandbox' | 'live';
  createPayment(o: { orderId: string; reference: string; amount: bigint; currency: 'IQD';
                     description: string; callbackUrl: string; redirectUrl: string; locale: string })
    : Promise<CreatedPayment>;          // providerPaymentId, appLinks?, qr?, formUrl?, validUntil
  getStatus(providerPaymentId: string): Promise<ProviderStatus>; // PAID | UNPAID | DECLINED | ...
  cancel?(providerPaymentId: string): Promise<void>;
  refund?(providerPaymentId: string, amount?: bigint): Promise<RefundResult>;
  verifyWebhook(req: Request): Promise<VerifiedEvent>;   // throws on invalid
}
```
When `mode()==='unconfigured'` the API returns `PAYMENT_PROVIDER_NOT_CONFIGURED` and the app shows "This payment method is not available yet" — nothing pretends to work.

## 4. FIB (First Iraqi Bank) — from public FIB Online Payments docs/SDKs
- Onboarding: register for the **sandbox** first; FIB issues production credentials after review (contact: FIB merchant / support@fib-payment.com, docs at fib.iq/integrations/web-payments).
- Auth: OAuth2 client credentials — `POST /auth/realms/fib-online-shop/protocol/openid-connect/token` (client_id, client_secret).
- Create: `POST /protected/v1/payments` → `paymentId`, `qrCode`, `readableCode`, `personalAppLink`, `businessAppLink`, `corporateAppLink`, `validUntil`.
- Status: `GET /protected/v1/payments/{id}/status`; Cancel: `POST /protected/v1/payments/{id}/cancel`; Refund: `POST /protected/v1/payments/{id}/refund`.
- Stage host: `fib.stage.fib.iq`; production host provided with credentials.
- Callback: FIB calls our `statusCallbackUrl` with id+status → we always re-query status (callback is not signed by default, so treat as a trigger only).
- Official TS SDK exists: `@first-iraqi-bank/sdk` — evaluate during Phase 6; otherwise thin fetch client.
- Mobile UX: show "Open in FIB app" (personalAppLink deep link), QR (for paying from another phone) and readable code.
- **To confirm with FIB at onboarding:** exact refund rules/window, callback IP ranges or signing, payment validity duration, whether `description` supports Kurdish/Arabic text.

## 5. Qi Card — from developers-gate.qi.iq
- QiCard Payment Gateway: PCI-DSS hosted form with 3-D Secure; supports cards, saved-card tokens and Pay with SuperQi wallet; web and mobile SDKs.
- Sandbox base: `https://uat-sandbox-3ds-api.qi.iq/api/v1`; production host given at onboarding.
- Auth: Basic Auth or signature-based (we will use **signature-based**); header `X-Terminal-Id` per merchant terminal.
- Create: `POST /api/v1/payment` → payment object with `formUrl` (hosted payment page). App opens it in an in-app browser; redirect URL returns to the app.
- Webhooks & events available; we verify signature (per docs) then still query payment status.
- Refunds supported via API (confirm terms with Qi).
- **To confirm with Qi at onboarding:** terminal id + credentials, webhook signing key, status endpoint and status vocabulary, refund API and limits, whether the native mobile SDK is preferable to hosted form.

## 6. Error codes returned to clients (localized in app)
`PAYMENT_PROVIDER_NOT_CONFIGURED, PAYMENT_ALREADY_PAID, PAYMENT_ORDER_EXPIRED, PAYMENT_AMOUNT_MISMATCH, PAYMENT_PROVIDER_ERROR, PAYMENT_NOT_REQUIRED, PROPERTY_NOT_SUBMITTABLE, AI_JOB_NOT_PAYABLE, RATE_LIMITED`.

## 7. Test plan (Phase 6)
create (both providers) · verify via status · failure/decline · duplicate webhook · duplicate create with same idempotency key · concurrent create from two devices · amount mismatch (mocked provider) · unverified callback (forged) rejected · expiry · refund · reconciliation catches a missed webhook. Sandbox only until live credentials are tested end-to-end.
