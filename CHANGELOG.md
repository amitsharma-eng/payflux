## 0.1.0

- Initial release.
- `PayFlux` facade with `register`, `registerAll`, `configure`, `pay`, `disposeAll`.
- `PayFluxGateway` abstract interface for pluggable providers.
- Built-in gateways: Stripe (`PayFluxStripeGateway`), Razorpay
  (`PayFluxRazorpayGateway`), PayPal (`PayFluxPayPalGateway`).
- Normalized `PayFluxRequest` / `PayFluxResult` / `PayFluxStatus` models.
- Android & iOS support.
