public interface IRouteProvider {
    RoutePlanResult plan(List<RouteWaypoint> waypoints);

    public class RouteWaypoint {
        public Id visitId;
        public Decimal lat;
        public Decimal lng;
        public String label;
    }

    public class RouteLeg {
        public Id fromVisitId;
        public Id toVisitId;
        public Decimal distanceKm;
        public Integer durationMin;
    }

    public class RoutePlanResult {
        public List<RouteWaypoint> ordered;
        public List<RouteLeg> legs;
        public Decimal totalDistanceKm;
        public Integer totalDurationMin;
    }
}
