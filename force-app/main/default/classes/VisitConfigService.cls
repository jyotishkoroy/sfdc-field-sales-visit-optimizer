public class VisitConfigService {
    public class Config {
        public Integer allowedRadiusMeters;
        public Boolean requireReason;
    }

    public static Config getConfig() {
        Config c = new Config();
        c.allowedRadiusMeters = 250;
        c.requireReason = true;

        List<Visit_Config__mdt> rows = [
            SELECT AllowedRadiusMeters__c, RequireReasonWhenOutOfRadius__c
            FROM Visit_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        if (!rows.isEmpty()) {
            c.allowedRadiusMeters = (Integer)rows[0].AllowedRadiusMeters__c;
            c.requireReason = rows[0].RequireReasonWhenOutOfRadius__c;
        }
        return c;
    }
}
