@IsTest
private class LocationUtilTest {
    @IsTest
    static void haversineReturnsDistance() {
        Decimal d = LocationUtil.haversineMeters(12.9716, 77.5946, 12.9352, 77.6245);
        System.assert(d != null && d > 0, 'Distance should be positive');
    }
}
