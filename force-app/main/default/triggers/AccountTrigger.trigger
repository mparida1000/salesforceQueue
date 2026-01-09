trigger AccountTrigger on Account (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountTriggerHandler.handleDistributorOptions(Trigger.new, Trigger.oldMap);
    }
}