 public class AccountsController {

     @AuraEnabled
    public static List <Contact> getAccounts(String aid) {
        system.debug('aid: ' +aid);
        List <Contact> Contacts = [SELECT Id, name,Email,Phone,Active__c  FROM Contact where AccountId=:aid ORDER BY createdDate ASC];
        System.debug('Contacts: CCCCC 333333 333' +Contacts);
        return Contacts;
    }
    @AuraEnabled
    public static void updateContact(string contactId,boolean status){
        try{
            contact objCon=[select Id, name,Email,Phone,Active__c  FROM Contact where Id=:contactId limit 1];
            if(objCon !=null){
                objCon.Active__c = status;
                update objCon;
            }
            
        }
        catch(Exception ex){}
    }
}
