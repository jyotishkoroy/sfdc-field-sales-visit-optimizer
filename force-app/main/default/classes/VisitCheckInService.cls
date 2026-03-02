public with sharing class VisitCheckInService {

    public class CheckRequest {
        @AuraEnabled public Id visitId;
        @AuraEnabled public Decimal lat;
        @AuraEnabled public Decimal lng;
        @AuraEnabled public String gpsStatus; // OK/Denied/Unavailable/Timeout
        @AuraEnabled public String exceptionReason;
    }

    public class CheckResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Decimal distanceFromTargetM;
        @AuraEnabled public Boolean outOfRadius;
        @AuraEnabled public Integer allowedRadiusM;
        @AuraEnabled public String gpsStatus;
    }

    @AuraEnabled
    public static CheckResponse checkIn(CheckRequest req) {
        return applyCheck(req, true);
    }

    @AuraEnabled
    public static CheckResponse checkOut(CheckRequest req) {
        return applyCheck(req, false);
    }

    private static CheckResponse applyCheck(CheckRequest req, Boolean isCheckIn) {
        if (req == null || req.visitId == null) {
            throw new AuraHandledException('visitId is required.');
        }

        VisitConfigService.Config cfg = VisitConfigService.getConfig();

        Visit__c v = [
            SELECT Id, Name, Status__c, TargetLat__c, TargetLng__c, Exception__c, ExceptionReason__c
            FROM Visit__c
            WHERE Id = :req.visitId
            LIMIT 1
        ];

        CheckResponse resp = new CheckResponse();
        resp.allowedRadiusM = cfg.allowedRadiusMeters;
        resp.gpsStatus = String.isBlank(req.gpsStatus) ? 'OK' : req.gpsStatus;

        // GPS issues
        if (resp.gpsStatus != 'OK') {
            v.GpsStatus__c = resp.gpsStatus;
            v.Exception__c = 'GPS error: ' + resp.gpsStatus;
            if (!String.isBlank(req.exceptionReason)) v.ExceptionReason__c = req.exceptionReason;

            // Still allow check-in/out timestamp to be recorded (policy choice)
            if (isCheckIn) {
                v.CheckInTime__c = System.now();
                v.Status__c = 'CheckedIn';
            } else {
                v.CheckOutTime__c = System.now();
                v.Status__c = 'CheckedOut';
            }
            update v;

            resp.success = true;
            resp.message = (isCheckIn ? 'Checked in' : 'Checked out') + ' with GPS exception (' + resp.gpsStatus + ').';
            return resp;
        }

        // Compute distance to target if available
        Decimal dist = LocationUtil.haversineMeters(req.lat, req.lng, v.TargetLat__c, v.TargetLng__c);
        resp.distanceFromTargetM = dist;
        resp.outOfRadius = (dist != null && dist > cfg.allowedRadiusMeters);

        if (resp.outOfRadius && cfg.requireReason && String.isBlank(req.exceptionReason)) {
            resp.success = false;
            resp.message = 'Out of radius (' + String.valueOf(dist.setScale(1)) + 'm). Reason required.';
            return resp;
        }

        // Apply fields
        if (isCheckIn) {
            v.CheckInTime__c = System.now();
            v.CheckInLat__c = req.lat;
            v.CheckInLng__c = req.lng;
            v.Status__c = 'CheckedIn';
        } else {
            v.CheckOutTime__c = System.now();
            v.CheckOutLat__c = req.lat;
            v.CheckOutLng__c = req.lng;
            v.Status__c = 'CheckedOut';
        }
        v.DistanceFromTargetM__c = dist;
        v.GpsStatus__c = 'OK';

        if (resp.outOfRadius) {
            v.Exception__c = 'Out of radius: ' + String.valueOf(dist.setScale(1)) + 'm';
            v.ExceptionReason__c = req.exceptionReason;
        } else {
            // Clear exception if previous run had it
            v.Exception__c = null;
            v.ExceptionReason__c = null;
        }

        update v;

        resp.success = true;
        resp.message = (isCheckIn ? 'Checked in' : 'Checked out') + (resp.outOfRadius ? ' (out-of-radius recorded).' : '.');
        return resp;
    }
}
