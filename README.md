# Field Sales Visit Optimizer — Mobile Check-in/out + Route Planning + Exceptions

A mini Salesforce app for field reps to:
- **Check in/out** to planned visits with device geolocation
- Generate a **daily optimized route** via a pluggable route provider (mock provider included)
- Track **distance/time** and surface **exceptions** (GPS off, out-of-radius)

## Core flows
1. **Today’s Visits**: see visit list + status badges
2. **Check-in**: capture GPS → validate radius → stamp time + coordinates
3. **Check-out**: stamp time + coordinates → compute duration
4. **Route Plan**: generate route order + leg distances/time, store as `Route_Plan__c` + `Route_Stop__c`
5. **Exceptions**:
   - GPS denied/unavailable → record exception
   - Out-of-radius (geofence) → record exception and require reason

## What’s in the repo
- Custom objects: `Visit__c`, `Route_Plan__c`, `Route_Stop__c`
- Apex services:
  - `VisitCheckInService` (geofence validation + exception handling)
  - `RoutePlanner` (daily route generation)
  - `IRouteProvider` + `MockRouteProvider` (route API abstraction)
- Mobile-first LWC:
  - `fieldVisitMobile` (check-in/out UI)
  - `routePlanner` (route generation + stop list)
- Unit tests (Apex + Jest) + CI (lint + Jest)

## Demo UI
- App Page: **Field Visit Mobile**
- App Page: **Route Planner**
(see `force-app/main/default/flexipages/`)

## Configuration
- `Visit_Config__mdt`:
  - `AllowedRadiusMeters__c` (default: 250m)
  - `RequireReasonWhenOutOfRadius__c` (default: true)

## Notes on route provider
A real integration (Google Routes/Mapbox/etc.) is represented as `RoutesApiProvider` (stub).
`MockRouteProvider` is deterministic, fast, and testable so the module works without external dependencies.
