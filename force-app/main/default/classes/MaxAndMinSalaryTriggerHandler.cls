public class MaxAndMinSalaryTriggerHandler {
    public static void calculateMinAndMaxSalary(Set<Id> companyIds) {
        List<Tech_Firm__c> firmsToUpd = new List<Tech_Firm__c>();
        for(AggregateResult aggr : [SELECT Tech_Firm__c, MAX(Salary__c) maximum, MIN(Salary__c) minimum from 
                                    Employee__c WHERE Tech_Firm__c IN : companyIds GROUP BY Tech_Firm__c] ){
            Tech_Firm__c tf = new Tech_Firm__c();
            tf.Id = (Id)aggr.get('Tech_Firm__c');
            tf.Max_Salary__c = (Decimal)aggr.get('maximum');
            tf.Min_Salary__c = (Decimal)aggr.get('minimum');
            firmsToUpd.add(tf);
        }
        if(!firmsToUpd.isEmpty()){
            try{
                update firmsToUpd;
            }catch(Exception e){
                System.debug('Error while updating the firms : '+e.getStackTraceString());
            }
        }
    }
}