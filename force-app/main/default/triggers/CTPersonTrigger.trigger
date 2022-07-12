trigger CTPersonTrigger on Person__c (before insert, before update) {
  switch on Trigger.operationType {
	  when BEFORE_INSERT {
		 CTPersonTriggerHandler.handleBeforeInsert(Trigger.new); 
          }

	  when BEFORE_UPDATE {
		  CTPersonTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
	  }

	  when AFTER_UPDATE {
		  CTPersonTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
	  }
	 
  }
}