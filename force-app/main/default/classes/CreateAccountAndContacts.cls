public class CreateAccountAndContacts {
    
    public static void createAccount(String name, String street, String city, String postalCode, String state){
        Account acc = new Account();
        acc.name = name;
        acc.BillingStreet = street;
        acc.BillingCity = city;
        acc.BillingPostalCode = postalCode;
        acc.BillingState = state;
        
        insert acc;
    }

}