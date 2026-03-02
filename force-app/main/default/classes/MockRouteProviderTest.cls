@IsTest
private class MockRouteProviderTest {
    @IsTest
    static void plansRouteDeterministically() {
        List<IRouteProvider.RouteWaypoint> wps = new List<IRouteProvider.RouteWaypoint>();

        IRouteProvider.RouteWaypoint a = new IRouteProvider.RouteWaypoint();
        a.visitId = 'a00000000000001';
        a.lat = 12.0; a.lng = 77.0; a.label = 'A';
        wps.add(a);

        IRouteProvider.RouteWaypoint b = new IRouteProvider.RouteWaypoint();
        b.visitId = 'a00000000000002';
        b.lat = 12.01; b.lng = 77.01; b.label = 'B';
        wps.add(b);

        IRouteProvider.RouteWaypoint c = new IRouteProvider.RouteWaypoint();
        c.visitId = 'a00000000000003';
        c.lat = 13.0; c.lng = 78.0; c.label = 'C';
        wps.add(c);

        IRouteProvider p = new MockRouteProvider();
        IRouteProvider.RoutePlanResult res = p.plan(wps);

        System.assertEquals(3, res.ordered.size(), 'Expected 3 waypoints');
        System.assertEquals(2, res.legs.size(), 'Expected 2 legs');
        System.assert(res.totalDistanceKm >= 0, 'Expected totals');
    }
}
