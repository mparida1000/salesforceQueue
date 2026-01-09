public with sharing class OpportunityLineItemTriggerHandler {
    public static void updateTotalProductsInAccount(Set<id> oppIds){
        List<Opportunity> oppList = new List<Opportunity>([SELECT AccountId, Account.Number_of_products__c FROM Opportunity WHERE Id IN : oppIds]);
        Map<Id, Account> accMap = new Map<Id, Account>();
        for(Opportunity opp : oppList){
            Account acc = new Account();
            if(opp.AccountId != null){
                acc.Id = opp.AccountId;
                System.debug('Account id'+acc.id);
                acc.Number_of_products__c = opp.Account.Number_of_products__c;
                accMap.put(acc.Id, acc);
            }
        }
        List<AggregateResult> aggList = new List<AggregateResult>();
        if(!accMap.isEmpty()){
            aggList = [SELECT Opportunity.AccountId ids, count(id) totalProducts FROM OpportunityLineItem WHERE 
                        Opportunity.AccountId IN : accMap.keySet() GROUP BY Opportunity.AccountId];
            if(!aggList.isEmpty()){
                for(AggregateResult ar : aggList){
                    Account acc = accMap.get((Id)ar.get('ids'));
                    acc.Number_of_products__c = (Decimal)ar.get('totalProducts');
                }
            }else{
                for(Account acc : accMap.values()){
                    acc.Number_of_products__c = 0;
                }
            }
        }

        if(!accMap.isEmpty()){
            update accMap.values();
        }

    }
}