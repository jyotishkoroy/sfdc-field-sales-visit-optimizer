# ADR 0002: Geofence exception policy

## Context
Field check-in must be trustworthy, but GPS accuracy varies.
Hard-failing check-in creates operational friction.

## Decision
- Compute distance-from-target (meters)
- If distance > allowed radius:
  - record exception
  - optionally require a reason
  - still allow check-in (configurable approach)

## Consequences
- audit-friendly exceptions
- fewer blocked check-ins
- clear governance via CMDT
