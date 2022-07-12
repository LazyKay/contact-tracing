public with sharing class CTLocationController {
  public static List<Location__c> getRecentStatusChanges() {
    return [
      SELECT
        Id,
        Name,
        Address__c,
        Pincode__c,
        Red_Score__c,
        Status_Update_Date__c,
        Status__c
      FROM Location__c
      ORDER BY Status_Update_Date__c DESC NULLS LAST
      LIMIT 100
    ];
  }

  public static List<Location__c> searchLocations(String searchTerm) {
    searchTerm += '%';
    return [
      SELECT
        Id,
        Name,
        Address__c,
        Pincode__c,
        Red_Score__c,
        Status_Update_Date__c,
        Status__c
      FROM Location__c
      WHERE
        Name LIKE :searchTerm
        OR Pincode__c LIKE :searchTerm
        OR Address__c LIKE :searchTerm
      ORDER BY Status_Update_Date__c DESC NULLS LAST
      LIMIT 100
    ];
  }

  public static Location__c getLocationById(String locationId) {
    List<Location__c> locations = [
      SELECT
        Id,
        Name,
        Address__c,
        Pincode__c,
        Red_Score__c,
        Status_Update_Date__c,
        Status__c
      FROM Location__c
      WHERE Id = :locationId
    ];
    if (locations != null && locations.size() > 0) {
      return locations[0];
    }
    return null;
  }

  public static Map<String, Integer> getStatusCount() {
    Map<String, Integer> resultMap = new Map<String, Integer>();

    for (AggregateResult result : [
      SELECT COUNT(Id) NumberOfLocation, Status__c
      FROM Location__c
      GROUP BY Status__c
    ]) {
      resultMap.put(
        String.valueOf(result.get('Status__c')),
        Integer.valueOf(result.get('NumberOfLocation'))
      );
    }

    return resultMap;
  }

  public static void updateRedScore(Set<Id> locationIds) {
    List<Location__c> locationsToUpdate = new List<Location__c>();
    List<AggregateResult> redPeoplePerLocation = [
      SELECT Location__c, COUNT(Id) Total
      FROM Location_Tracing__c
      WHERE
        Location__c IN :locationIds
        AND Person__r.Health_Status__c = 'Red'
        AND Visit_Date__c = LAST_N_DAYS:10
      GROUP BY Location__c
    ];

    for (AggregateResult result : redPeoplePerLocation) {
      String id = String.valueOf(result.get('Location__c'));
      Integer redScore = Integer.valueOf(result.get('Total'));
      String status = getStatus(redScore);
      locationsToUpdate.add(
        new Location__c(Id = id, Red_Score__c = redScore, Status__c = status)
      );
    }

    if (locationsToUpdate != null && locationsToUpdate.size() > 0) {
      update locationsToUpdate;
    }
  }

  public static String getStatus(Integer redScore) {
    if (redScore == 0) {
      return 'Green';
    } else if (redScore <= 5) {
      return 'Yellow';
    } else if (redScore <= 10) {
      return 'Orange';
    }
    return 'Red';
  }

  public static Map<String, Integer> getHealthStatusCount() {
    List<AggregateResult> aggregateResults = [
      SELECT COUNT(Id) Total, Status__c
      FROM Location__c
      GROUP BY Status__c
    ];

    if (aggregateResults != null && aggregateResults.size() > 0) {
      Map<String, Integer> resultMap = new Map<String, Integer>();
      for (AggregateResult item : aggregateResults) {
        resultMap.put(
          String.valueOf(item.get('Status__c')),
          Integer.valueOf(item.get('Total'))
        );
      }
      return resultMap;
    }
    return null;
  }
}
