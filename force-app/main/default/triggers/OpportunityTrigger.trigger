trigger OpportunityTrigger on Opportunity (after insert, after update) {
    
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            system.debug('In Opty Trigger');
            OpportunityHandler.afterInsertEventHandler(trigger.new);
        }else if(Trigger.isUpdate){
            OpportunityHandler.UpdateCountOnAccount(trigger.newMap);
        }
    }

}