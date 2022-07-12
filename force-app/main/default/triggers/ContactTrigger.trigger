trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            ContactTriggerHandler.handleAfterInsert(Trigger.new);
        }
        
        when AFTER_UPDATE {
            ContactTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }

        when AFTER_DELETE {
            ContactTriggerHandler.handleAfterDelete(Trigger.old);
        }

        when AFTER_UNDELETE {
             ContactTriggerHandler.handleAfterUndelete(Trigger.new);
        }
    }
}