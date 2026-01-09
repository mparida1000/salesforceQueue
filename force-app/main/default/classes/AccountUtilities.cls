public class AccountUtilities {


    public static List<Account> getAccWithContacts(String name){
        List<Account> accList = new List<Account> ([SELECT Id, Name, (select LastName, FirstName from Contacts) from Account where Name = : name]);
        return accList;
    }
}