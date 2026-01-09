trigger CaseTrigger on Case (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    System.debug(Trigger.operationType.name());
    String eventType = Trigger.operationType.name();
    
    TriggerDispatcher.execute(
        Trigger.new, 
        Trigger.oldMap, 
        eventType, 
        CaseTriggerHandler.class
    );
}