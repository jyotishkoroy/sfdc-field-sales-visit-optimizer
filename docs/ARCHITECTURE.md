# Architecture

## Data model
- **Visit__c**
  - Planned time + target coordinates
  - Check-in/out time + captured coordinates
  - Status + exception fields
- **Route_Plan__c**
  - Owner + date + totals (distance/time)
- **Route_Stop__c**
  - Master-detail to Route Plan
  - Sequence + leg metrics + Visit lookup

## Services
- **VisitCheckInService**
  - Captures check-in/out timestamps + coordinates
  - Computes distance-from-target (haversine)
  - Applies geofence rules from CMDT
  - Writes exceptions for denied GPS / out-of-radius
- **RoutePlanner**
  - Pulls today’s planned visits
  - Calls `IRouteProvider` to order stops + compute legs
  - Writes Route Plan + Stops

## UI
- **fieldVisitMobile (LWC)**
  - Fetches today's visits
  - Calls browser geolocation
  - Calls Apex check-in/out and handles error UX
- **routePlanner (LWC)**
  - Generates and displays route
  - Exports CSV (optional) for navigation apps
