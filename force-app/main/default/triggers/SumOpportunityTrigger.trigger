/*
Your company wants to keep track of the total amount of opportunities associated with each account in a Salesforce org. 
This information could be useful for sales and marketing teams to identify high-value accounts and prioritize their 
efforts accordingly.
*/

/*Questions:
1. You want the Account's Opportunity value to be updated?
2. Assumption, If it is deleted, Undeleted, and Account is changed, then also we need to address
*/
trigger SumOpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    Set<Id> accIds = new Set<Id>();
    if(trigger.isAfter && (trigger.isInsert || trigger.isUndelete)){
        for(Opportunity opp : trigger.new){
            if(opp.AccountId != null){
                accIds.add(opp.AccountId);
            }
        }
    }

    if(trigger.isAfter && trigger.isUpdate){
        for (Opportunity opp : trigger.new) {
            if (opp.AccountId != trigger.oldMap.get(opp.Id).AccountId) {
                accIds.add(opp.AccountId);
                accIds.add(trigger.oldMap.get(opp.Id).AccountId);
            }else{
                accIds.add(opp.AccountId);
            }
        }
    }

    if(trigger.isAfter && trigger.isDelete){
        for(Opportunity opp : trigger.old){
            if(opp.AccountId !=null){
                accIds.add(trigger.oldMap.get(opp.Id).AccountId);
            }
        }
    }

    List<AggregateResult> accWithOppList = new List<AggregateResult> (
        [select AccountId ids, SUM(Amount) amnt from Opportunity where AccountId in : accIds group by AccountId]);
    Map<Id, Account> accMap = new Map<Id, Account>();
    if(!accWithOppList.isEmpty()){
        for(AggregateResult ar : accWithOppList){
            Account acc = new Account();
            acc.Id = (Id)ar.get('ids');
            acc.Amount__c = (Decimal)ar.get('amnt');
            accMap.put(acc.Id, acc);
        }
    }else{
        for(Id accId : accIds){
            Account acc = new Account();
            acc.Id = accId;
            acc.Amount__c = 0;
            accMap.put(acc.Id, acc);
        }
    }

    if(!accMap.isEmpty()){
        update accMap.values();
    }
    
}