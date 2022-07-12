public with sharing class CTPersonViewController {
  @AuraEnabled
  public static void updateHealthStatus(String personId) {
    update new Person__c(Id = personId, Health_Status__c = 'Red');
  }
}
