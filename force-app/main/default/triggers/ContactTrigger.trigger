trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter) {
        ContactTriggerHandler.updateAccountContactCounts(Trigger.new, Trigger.oldMap, Trigger.isDelete);
    }
}