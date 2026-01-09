trigger ProjectTrigger on Project__c (after insert, after update) {
    
    Set<Id> accountIds = new Set<Id>();
    if(trigger.isInsert || trigger.isUpdate){
        if(trigger.isAfter){
            for(Project__c proj : trigger.New){
                if((trigger.isInsert && proj.Cost__c > 0) || (proj.Cost__c != null && proj.Cost__c > 0 && 
                   trigger.newMap.get(proj.Id).Cost__c != trigger.oldMap.get(proj.Id).Cost__c)){
                    accountIds.add(proj.Acc__c);
                }
            }
            if(accountIds.size() > 0){
               ProjectHandler.calculateTotalCost(accountIds); 
            }
        }
    }
}