## Design

### Entitlement Provider

`SubhEntitlementStore` remains the centralized source for entitlement state. It keeps the persisted/raw `snapshot` for the current Free/Plus/Complete tier, and exposes `effectiveSnapshot` for UI and feature access decisions.

In Debug builds only, `effectiveSnapshot` may return a temporary Complete-equivalent development profile so active feature work can be exercised on simulator and physical devices. Release builds compile to the raw `snapshot` path.

The debug override can be disabled for gate testing through a debug-only environment flag. This preserves the ability to verify locked/preview states without scattering local `#if DEBUG` checks across Month Planning views.

### Month Planning Views

Home Plan Ahead tiles, Month Picker, Month Detail, the Monthly Fajrcast placeholder, and Month Planning Day Detail source context read the centralized `effectiveSnapshot`. The locked preview UI remains available when the effective entitlement does not allow Month Planning.

### Production Gating

This pass intentionally does not add final purchase or subscription behavior. Production gating continues through the existing entitlement service shape. A later pricing/entitlement pass can replace the placeholder tier source without changing Month Planning's access surface.

### Guardrails

- Do not create a parallel entitlement checker inside Month Planning.
- Do not calculate Fajr, Hijri, wake state, persistence, or scheduling behavior in the entitlement layer.
- Do not create stored day records or schedule platform alarms when month data is browsed.
- Do not change the active MVP wake-mode language: `Suhoor | Fajr | Quiet`.
