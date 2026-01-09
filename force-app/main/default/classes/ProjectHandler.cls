public class ProjectHandler {

    public static void calculateTotalCost(Set<Id> acctIds){
        AggregateResult [] agrList = [SELECT Acc__c, Sum(Cost__c) sum from Project__c where Acc__c IN : acctIds GROUP BY Acc__c];
        List<Account> listAcc = new List<Account>();
        for(AggregateResult agr : agrList){
            Account acc = new Account();
            Id accId = (Id)agr.get('Acc__c');
            Decimal sum = (Decimal)agr.get('sum');
            acc.Id = accId;
            acc.Total_Cost__c = sum;
            listAcc.add(acc);
        }
        update listAcc;
    }
}