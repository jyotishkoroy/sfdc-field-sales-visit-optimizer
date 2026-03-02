public class RoutesApiProvider implements IRouteProvider, Database.AllowsCallouts {

    // Stub for a real routes API integration (Google Routes/Mapbox/etc.).
    // Expected responsibilities:
    // - Build request from waypoints
    // - Call Named Credential endpoint
    // - Parse response into ordered waypoints + legs
    public IRouteProvider.RoutePlanResult plan(List<IRouteProvider.RouteWaypoint> waypoints) {
        throw new AuraHandledException('Routes API provider not configured. Use MockRouteProvider in this version.');
    }
}
