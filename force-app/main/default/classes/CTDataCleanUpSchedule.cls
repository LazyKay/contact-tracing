public with sharing class CTDataCleanUpSchedule implements Schedulable {
  public static final String CROM = '0 0 2 * * ?';
  public void execute(SchedulableContext sc) {
    CTPeopleTracingDataCleanUpBatch peopleTracingBatch = new CTPeopleTracingDataCleanUpBatch();
    Database.executeBatch(peopleTracingBatch, 2000);
  }
}
