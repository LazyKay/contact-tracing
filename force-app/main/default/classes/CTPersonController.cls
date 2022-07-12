public with sharing class CTPersonController {
  public static String getToken(String mobileNumber) {
    return EncodingUtil.base64Encode(
      (Crypto.generateDigest('MD5', Blob.valueOf(mobileNumber)))
    );
  }

  public static List<Person__c> getRecentHealthChanges() {
    return [
      SELECT
        Id,
        Name,
        Mobile__c,
        Token__c,
        Health_Status__c,
        Status_Update_Date__c
      FROM Person__c
      ORDER BY Status_Update_Date__c DESC NULLS LAST
      LIMIT 100
    ];
  }

  public static List<Person__c> searchPeople(String searchTerm) {
    searchTerm += '%';
    return [
      SELECT
        Id,
        Name,
        Mobile__c,
        Token__c,
        Health_Status__c,
        Status_Update_Date__c
      FROM Person__c
      WHERE
        Name LIKE :searchTerm
        OR Mobile__c LIKE :searchTerm
        OR Token__c LIKE :searchTerm
      ORDER BY Status_Update_Date__c DESC NULLS LAST
    ];
  }

  public static Person__c getPersonById(String personId) {
    List<Person__c> people = [
      SELECT
        Id,
        Name,
        Mobile__c,
        Token__c,
        Health_Status__c,
        Status_Update_Date__c
      FROM Person__c
      WHERE Id = :personId
    ];
    if (people != null && people.size() > 0) {
      return people[0];
    }
    return null;
  }

  public static Map<String, Integer> getHealthStatusCount() {
    Map<String, Integer> resultMap = new Map<String, Integer>();

    for (AggregateResult result : [
      SELECT COUNT(Id) NumberOfPerson, Health_Status__c
      FROM Person__c
      GROUP BY Health_Status__c
    ]) {
      resultMap.put(
        String.valueOf(result.get('Health_Status__c')),
        Integer.valueOf(result.get('NumberOfPerson'))
      );
    }

    return resultMap;
  }

  public static Set<Id> getCohabitants(
    Set<Id> redStatusSet,
    Set<Id> alreadyProcessedSet
  ) {
    List<String> healthStatusList = new List<String>{ 'Green', 'Yellow' };
    Set<Id> cohabitants = new Set<Id>();
    List<People_Tracing__c> peopleTrace = [
      SELECT Contact_Type__c, Id, Contact_Date__c, Person_1__c, Person_2__c
      FROM People_Tracing__c
      WHERE
        (Person_1__c IN :redStatusSet
        OR Person_2__c IN :redStatusSet)
        AND (Person_1__r.Health_Status__c IN :healthStatusList
        OR Person_2__r.Health_Status__c IN :healthStatusList)
        AND Contact_Type__c = 'Cohabitant'
    ];

    for (People_Tracing__c trace : peopleTrace) {
      if (!alreadyProcessedSet.contains(trace.Person_1__c)) {
        cohabitants.add(trace.Person_1__c);
        alreadyProcessedSet.add(trace.Person_1__c);
      }

      if (!alreadyProcessedSet.contains(trace.Person_2__c)) {
        cohabitants.add(trace.Person_2__c);
        alreadyProcessedSet.add(trace.Person_2__c);
      }
    }
    return cohabitants;
  }

  public static Set<Id> getNeighbours(
    Set<Id> redStatusSet,
    Set<Id> alreadyProcessedSet
  ) {
    Set<Id> neighbours = new Set<Id>();
    List<People_Tracing__c> peopleTrace = [
      SELECT Contact_Type__c, Id, Contact_Date__c, Person_1__c, Person_2__c
      FROM People_Tracing__c
      WHERE
        (Person_1__c IN :redStatusSet
        OR Person_2__c IN :redStatusSet)
        AND (Person_1__r.Health_Status__c = 'Green'
        OR Person_2__r.Health_Status__c = 'Green')
        AND Contact_Type__c = 'Neighbour'
    ];

    for (People_Tracing__c trace : peopleTrace) {
      if (!alreadyProcessedSet.contains(trace.Person_1__c)) {
        neighbours.add(trace.Person_1__c);
        alreadyProcessedSet.add(trace.Person_1__c);
      }

      if (!alreadyProcessedSet.contains(trace.Person_2__c)) {
        neighbours.add(trace.Person_2__c);
        alreadyProcessedSet.add(trace.Person_2__c);
      }
    }
    return neighbours;
  }
  public static Set<Id> getPrimaryContacts(
    Set<Id> redStatusSet,
    Set<Id> alreadyProcessedSet
  ) {
    Set<Id> primaryContacts = new Set<Id>();
    List<String> healthStatusList = new List<String>{ 'Green', 'Yellow' };
    List<People_Tracing__c> peopleTrace = [
      SELECT Contact_Type__c, Id, Contact_Date__c, Person_1__c, Person_2__c
      FROM People_Tracing__c
      WHERE
        (Person_1__c IN :redStatusSet
        OR Person_2__c IN :redStatusSet)
        AND (Person_1__r.Health_Status__c IN :healthStatusList
        OR Person_2__r.Health_Status__c IN :healthStatusList)
        AND Contact_Type__c = 'Other'
        AND Contact_Date__c = LAST_N_DAYS:10
    ];

    for (People_Tracing__c trace : peopleTrace) {
      if (!alreadyProcessedSet.contains(trace.Person_1__c)) {
        primaryContacts.add(trace.Person_1__c);
        alreadyProcessedSet.add(trace.Person_1__c);
      }

      if (!alreadyProcessedSet.contains(trace.Person_2__c)) {
        primaryContacts.add(trace.Person_2__c);
        alreadyProcessedSet.add(trace.Person_2__c);
      }
    }
    return primaryContacts;
  }

  public static Set<Id> getSecondaryContacts(
    Set<Id> primaryContacts,
    Set<Id> alreadyProcessedSet
  ) {
    Set<Id> secondaryContacts = new Set<Id>();
    List<People_Tracing__c> peopleTrace = [
      SELECT Contact_Type__c, Id, Contact_Date__c, Person_1__c, Person_2__c
      FROM People_Tracing__c
      WHERE
        (Person_1__c IN :primaryContacts
        OR Person_2__c IN :primaryContacts)
        AND (Person_1__r.Health_Status__c = 'Green'
        OR Person_2__r.Health_Status__c = 'Green')
        AND Contact_Type__c = 'Other'
        AND Contact_Date__c = LAST_N_DAYS:10
    ];

    for (People_Tracing__c trace : peopleTrace) {
      if (!alreadyProcessedSet.contains(trace.Person_1__c)) {
        secondaryContacts.add(trace.Person_1__c);
        alreadyProcessedSet.add(trace.Person_1__c);
      }

      if (alreadyProcessedSet.contains(trace.Person_2__c)) {
        secondaryContacts.add(trace.Person_2__c);
        alreadyProcessedSet.add(trace.Person_2__c);
      }
    }
    return secondaryContacts;
  }

  public static Map<String, Integer> getPersonHealthStatusCount() {
    List<AggregateResult> aggregateResults = [
      SELECT Health_Status__c, COUNT(Id) Total
      FROM Person__c
      GROUP BY Health_Status__c
    ];

    if (aggregateResults != null && aggregateResults.size() > 0) {
      Map<String, Integer> resultMap = new Map<String, Integer>();
      for (AggregateResult item : aggregateResults) {
        resultMap.put(
          String.valueOf(item.get('Health_Status__c')),
          Integer.valueOf(item.get('Total'))
        );
      }
      return resultMap;
    }

    return null;
  }
}
