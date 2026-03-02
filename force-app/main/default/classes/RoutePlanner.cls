public with sharing class RoutePlanner {

    public class PlanRequest {
        @AuraEnabled public Date planDate;
        @AuraEnabled public Id ownerUserId;
    }

    public class PlanResponse {
        @AuraEnabled public Id routePlanId;
        @AuraEnabled public Decimal totalDistanceKm;
        @AuraEnabled public Integer totalDurationMin;
        @AuraEnabled public Integer stopCount;
    }

    @AuraEnabled
    public static PlanResponse generate(PlanRequest req) {
        if (req == null) throw new AuraHandledException('Request required.');
        Date d = (req.planDate == null) ? Date.today() : req.planDate;
        Id uid = (req.ownerUserId == null) ? UserInfo.getUserId() : req.ownerUserId;

        List<Visit__c> visits = [
            SELECT Id, Name, TargetLat__c, TargetLng__c, Status__c, PlannedStart__c
            FROM Visit__c
            WHERE OwnerId = :uid
              AND DAY_ONLY(PlannedStart__c) = :d
              AND Status__c = 'Planned'
            ORDER BY PlannedStart__c ASC
            LIMIT 50
        ];

        // Build waypoints
        List<IRouteProvider.RouteWaypoint> wps = new List<IRouteProvider.RouteWaypoint>();
        for (Visit__c v : visits) {
            if (v.TargetLat__c == null || v.TargetLng__c == null) continue;
            IRouteProvider.RouteWaypoint w = new IRouteProvider.RouteWaypoint();
            w.visitId = v.Id;
            w.lat = v.TargetLat__c;
            w.lng = v.TargetLng__c;
            w.label = v.Name;
            wps.add(w);
        }

        IRouteProvider provider = new MockRouteProvider();
        IRouteProvider.RoutePlanResult plan = provider.plan(wps);

        Route_Plan__c rp = new Route_Plan__c();
        rp.Name = 'Route ' + String.valueOf(d);
        rp.PlanDate__c = d;
        rp.OwnerUser__c = uid;
        rp.TotalDistanceKm__c = plan.totalDistanceKm;
        rp.TotalDurationMin__c = plan.totalDurationMin;
        rp.Status__c = 'Generated';
        insert rp;

        // Stops
        List<Route_Stop__c> stops = new List<Route_Stop__c>();
        for (Integer i = 0; i < plan.ordered.size(); i++) {
            Route_Stop__c s = new Route_Stop__c();
            s.Name = 'Stop ' + (i+1);
            s.RoutePlan__c = rp.Id;
            s.Sequence__c = i+1;
            s.Visit__c = plan.ordered[i].visitId;
            stops.add(s);
        }

        // Leg metrics applied to stop i (from i-1 -> i)
        Map<Id, IRouteProvider.RouteLeg> legByTo = new Map<Id, IRouteProvider.RouteLeg>();
        for (IRouteProvider.RouteLeg l : plan.legs) {
            legByTo.put(l.toVisitId, l);
        }
        for (Route_Stop__c s : stops) {
            if (legByTo.containsKey(s.Visit__c)) {
                IRouteProvider.RouteLeg l = legByTo.get(s.Visit__c);
                s.LegDistanceKm__c = l.distanceKm;
                s.LegDurationMin__c = l.durationMin;
            }
        }
        insert stops;

        PlanResponse resp = new PlanResponse();
        resp.routePlanId = rp.Id;
        resp.totalDistanceKm = plan.totalDistanceKm;
        resp.totalDurationMin = plan.totalDurationMin;
        resp.stopCount = stops.size();
        return resp;
    }

    @AuraEnabled(cacheable=true)
    public static List<Route_Stop__c> getStops(Id routePlanId) {
        if (routePlanId == null) return new List<Route_Stop__c>();
        return [
            SELECT Id, Name, Sequence__c, LegDistanceKm__c, LegDurationMin__c,
                   Visit__r.Name
            FROM Route_Stop__c
            WHERE RoutePlan__c = :routePlanId
            ORDER BY Sequence__c ASC
        ];
    }
}
