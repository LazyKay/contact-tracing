public with sharing class CTPeopleTracingController {
  public static List<People_Tracing__c> getTraces(String personId) {
    return [
      SELECT
        Id,
        Name,
        Contact_Date__c,
        Contact_Type__c,
        Person_1__c,
        Person_1__r.Health_Status__c,
        Person_1__r.Token__c,
        Person_2__c,
        Person_2__r.Health_Status__c,
        Person_2__r.Token__c
      FROM People_Tracing__c
      WHERE
        (Person_1__c = :personId
        OR Person_2__c = :personId)
        AND Contact_Date__c = LAST_N_DAYS:30
      ORDER BY Contact_Date__c DESC
    ];
  }

  public static List<People_Tracing__c> checkDuplicates(
    List<People_Tracing__c> newPeopleTraces
  ) {
    Set<Id> personIds = new Set<Id>();
    List<People_Tracing__c> existingTraces = new List<People_Tracing__c>();
    List<People_Tracing__c> duplicateTraces = new List<People_Tracing__c>();
    Map<Id, Set<Id>> existingTracesMap = new Map<Id, Set<Id>>();

    for (People_Tracing__c trace : newPeopleTraces) {
      personIds.add(trace.Person_1__c);
      personIds.add(trace.Person_2__c);
    }

    existingTraces = [
      SELECT Id, Person_1__c, Person_2__c
      FROM People_Tracing__c
      WHERE Person_1__c IN :personIds AND Person_2__c IN :personIds
    ];

    if (existingTraces != null && existingTraces.size() > 0) {
      for (People_Tracing__c trace : existingTraces) {
        if (!existingTracesMap.containsKey(trace.Person_1__c)) {
          existingTracesMap.put(trace.Person_1__c, new Set<Id>());
        }
        existingTracesMap.get(trace.Person_1__c).add(trace.Person_2__c);

        if (!existingTracesMap.containsKey(trace.Person_2__c)) {
          existingTracesMap.put(trace.Person_2__c, new Set<Id>());
        }
        existingTracesMap.get(trace.Person_2__c).add(trace.Person_1__c);
      }

      for (People_Tracing__c trace : newPeopleTraces) {
        if (
          (existingTracesMap.containsKey(trace.Person_1__c) &&
          existingTracesMap.get(trace.Person_1__c)
            .contains(trace.Person_2__c)) ||
          existingTracesMap.containsKey(trace.Person_2__c) &&
          existingTracesMap.get(trace.Person_2__c).contains(trace.Person_2__c)
        ) {
          duplicateTraces.add(trace);
        }
      }
    }
    return duplicateTraces;
  }
}
