public class LocationUtil {
    private static final Decimal EARTH_RADIUS_M = 6371000;

    public static Decimal haversineMeters(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2) {
        if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;

        Double dLat = Math.toRadians((Double)(lat2 - lat1));
        Double dLon = Math.toRadians((Double)(lon2 - lon1));
        Double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(Math.toRadians((Double)lat1)) * Math.cos(Math.toRadians((Double)lat2)) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
        Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        Double d = (Double)EARTH_RADIUS_M * c;
        return (Decimal)d;
    }
}
