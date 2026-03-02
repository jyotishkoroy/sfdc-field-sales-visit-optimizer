public with sharing class FieldVisitController {

    @AuraEnabled(cacheable=true)
    public static List<Visit__c> getTodayVisits() {
        Date d = Date.today();
        return [
            SELECT Id, Name, Status__c, PlannedStart__c, PlannedEnd__c, Account__r.Name,
                   DistanceFromTargetM__c, GpsStatus__c, Exception__c, ExceptionReason__c
            FROM Visit__c
            WHERE OwnerId = :UserInfo.getUserId()
              AND DAY_ONLY(PlannedStart__c) = :d
            ORDER BY PlannedStart__c ASC
            LIMIT 50
        ];
    }
}
