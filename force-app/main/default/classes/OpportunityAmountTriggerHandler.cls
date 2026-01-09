public class OpportunityAmountTriggerHandler {
    public static void calculateMaxValuedOpportunity(Set<Id> accIds){
        List<Account> accUpdList = new List <Account>();
        for(AggregateResult aggr : [SELECT max(Amount) maxValOpp, Opportunity.AccountId FROM Opportunity 
                                        WHERE Opportunity.AccountId in : accIds GROUP BY Opportunity.AccountId]){
            Account acc = new Account();
            acc.Id = (Id)aggr.get('AccountId');
            acc.Max_Opportunity_Amount__c = (Decimal)aggr.get('maxValOpp');
            accUpdList.add(acc);
        }

        if(!accUpdList.isEmpty()){
            try{
                update accUpdList;
            }catch(Exception e){
                System.debug('Error while updating Accounts : '+e.getStackTraceString());
            }
        }
    }
}