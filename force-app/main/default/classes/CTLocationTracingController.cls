public with sharing class CTLocationTracingController {
   public static List<Location_Tracing__c> getVisitors(String locationId) {
       return [SELECT Id, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c
               FROM Location_Tracing__c
               WHERE Id =: locationId
               ORDER BY Visit_Date__c DESC];
   }
  
   public static List<Location_Tracing__c> getLoctionsByPersonIds(Set<Id> personIds) {
       return [SELECT Id, Person__c, Location__c
               FROM Location_Tracing__c
               WHERE Person__c IN :personIds
               AND Visit_Date__c = LAST_N_DAYS:10];
   }

   public static List<Location_Tracing__c> getLocationsByLocationIds(Set<Id> locationIds) {
         return [SELECT Id, Person__c, Location__c
               FROM Location_Tracing__c
               WHERE Location__c IN :locationIds
               AND Visit_Date__c = LAST_N_DAYS:10
               AND Person__r.Health_Status__c = 'Green'];
   }

   public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> newlocationTraces) {

     Set<Id> locations = new Set<Id>();
     Set<Id> people = new Set<Id>();
     Map<Id,Set<Id>> locationTracesMap = new Map<Id,Set<Id>>();
     List<Location_Tracing__c> existingLocationTraces = new List<Location_Tracing__c>();
     List<Location_Tracing__c> dupLicateTraces = new List<Location_Tracing__c>();

     for(Location_Tracing__c trace : newlocationTraces) {
         locations.add(trace.Location__c);
         people.add(trace.Person__c);
     }

      existingLocationTraces = [SELECT Id, Person__c, Location__c
                                FROM Location_Tracing__c
                                WHERE Location__c IN :locations
                                AND Person__c IN :people];

     if(existingLocationTraces !=null && existingLocationTraces.size() > 0) {                           
                for(Location_Tracing__c trace : existingLocationTraces) {
                    if(!locationTracesMap.containsKey(trace.Location__c)) {
                        locationTracesMap.put(trace.Location__c, new Set<Id>());
                    }
                    locationTracesMap.get(trace.Location__c).add(trace.Person__c);
                }

                for(Location_Tracing__c newTrace : newlocationTraces) {
                    if(locationTracesMap.containsKey(newTrace.Location__c) 
                    && locationTracesMap.get(newTrace.Location__c).contains(newTrace.Person__c)) {
                        dupLicateTraces.add(newTrace);
                    }
                }      
    }
     
     return dupLicateTraces;
   }

}