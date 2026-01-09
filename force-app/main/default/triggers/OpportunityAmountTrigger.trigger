trigger OpportunityAmountTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    List<Opportunity> oppList = new List<Opportunity>();
    boolean isNewPresent = false;
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate || trigger.isUndelete){
            oppList.addAll(trigger.new);
            isNewPresent = true;
        }else{
            oppList.addAll(trigger.old);
        }
    }
    Set<Id> accIds  = new Set<Id>();
    for(Opportunity opp : oppList){
        Opportunity oldOpp = trigger.oldMap != null ? trigger.oldMap.get(opp.Id) : null;
        if(isNewPresent && oldOpp != null && (oldOpp.ForecastCategoryName != opp.ForecastCategoryName && 
            (opp.ForecastCategoryName == 'Closed' || opp.ForecastCategoryName != 'Closed'))){ //Update case
            accIds.add(opp.AccountId);
        }else if(!isNewPresent){//Delete Case
            accIds.add(opp.AccountId);
        }else{//Undelete & New Case
            accIds.add(opp.AccountId);
        }
    }
    OpportunityAmountTriggerHandler.calculateMaxValuedOpportunity(accIds);
}