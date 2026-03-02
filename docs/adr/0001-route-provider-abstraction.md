# ADR 0001: Route provider abstraction

## Context
Route optimization typically depends on external APIs (Google Routes, Mapbox, OSRM).
Directly coupling the planner to a specific API makes testing slow and brittle.

## Decision
Introduce `IRouteProvider` and ship a deterministic `MockRouteProvider`:
- unit tests are reliable and fast
- external API integration is a drop-in provider (`RoutesApiProvider`)

## Consequences
- slightly more code up-front
- significantly better testability and long-term maintainability
