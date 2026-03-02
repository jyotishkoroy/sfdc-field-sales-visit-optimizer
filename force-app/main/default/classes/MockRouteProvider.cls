public class MockRouteProvider implements IRouteProvider {

    // Simple nearest-neighbor ordering using haversine distance.
    // Deterministic and test-friendly. Replace with a real provider when integrating an API.
    public IRouteProvider.RoutePlanResult plan(List<IRouteProvider.RouteWaypoint> waypoints) {
        IRouteProvider.RoutePlanResult res = new IRouteProvider.RoutePlanResult();
        res.ordered = new List<IRouteProvider.RouteWaypoint>();
        res.legs = new List<IRouteProvider.RouteLeg>();

        if (waypoints == null || waypoints.isEmpty()) {
            res.totalDistanceKm = 0;
            res.totalDurationMin = 0;
            return res;
        }

        List<IRouteProvider.RouteWaypoint> remaining = new List<IRouteProvider.RouteWaypoint>();
        remaining.addAll(waypoints);

        // Pick first as start (planned order not available in MVP)
        IRouteProvider.RouteWaypoint current = remaining.remove(0);
        res.ordered.add(current);

        Decimal totalKm = 0;
        Integer totalMin = 0;

        while (!remaining.isEmpty()) {
            Integer bestIdx = 0;
            Decimal bestDist = null;

            for (Integer i = 0; i < remaining.size(); i++) {
                Decimal dM = LocationUtil.haversineMeters(current.lat, current.lng, remaining[i].lat, remaining[i].lng);
                if (bestDist == null || dM < bestDist) {
                    bestDist = dM;
                    bestIdx = i;
                }
            }

            IRouteProvider.RouteWaypoint next = remaining.remove(bestIdx);

            Decimal km = (bestDist == null) ? 0 : (bestDist / 1000);
            // Use rough duration estimate: 25 km/h average => minutes = km / 25 * 60
            Integer min = (Integer)Math.round((Double)(km / 25 * 60));

            IRouteProvider.RouteLeg leg = new IRouteProvider.RouteLeg();
            leg.fromVisitId = current.visitId;
            leg.toVisitId = next.visitId;
            leg.distanceKm = km.setScale(2);
            leg.durationMin = Math.max(1, min);
            res.legs.add(leg);

            totalKm += leg.distanceKm;
            totalMin += leg.durationMin;

            res.ordered.add(next);
            current = next;
        }

        res.totalDistanceKm = totalKm.setScale(2);
        res.totalDurationMin = totalMin;
        return res;
    }
}
