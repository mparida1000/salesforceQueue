trigger MaxAndMinSalaryTrigger on Employee__c (after insert, after update, after delete, after undelete) {
    Set<Id> companyIds = new Set<Id>();
    List<Employee__c> empList = new List<Employee__c>();
    boolean isNewPresent = false;
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate || trigger.isUndelete){
            empList.addAll(trigger.new);
            isNewPresent = true;
        }else{
            empList.addAll(trigger.old);
        }
    }
    if(!empList.isEmpty()){
        for(Employee__c emp : empList){
            Employee__c oldEmp = trigger.oldMap != null ? trigger.oldMap.get(emp.Id) : null;
            if(isNewPresent && oldEmp != null && oldEmp.Salary__c != emp.Salary__c){//Update case
                companyIds.add(emp.Tech_Firm__c);
            }else if(!isNewPresent){//Delete Case
                companyIds.add(oldEmp.Tech_Firm__c);
            }else{//Insert & Undelete
                companyIds.add(emp.Tech_Firm__c);
            }
        }
    }
    if(!companyIds.isEmpty()){
        MaxAndMinSalaryTriggerHandler.calculateMinAndMaxSalary(companyIds);
    }
}