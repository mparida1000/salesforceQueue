//Test Bed
public class TestDataUtility {
    public static User createUser(String profileName){ 
        Profile prf = [select id from Profile where name = :profileName];
        User usr = new User(UserName = 'unique_test@iiiitm.com', Lastname = 'Last', FirstName = 'First', Email = 'test@iitm111.com', ProfileId = prf.id, Alias = 'test', 
                            TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US' );
        return usr;
    }
    
    //Create single Account record
    public static Account createAccount(){
        Account acc = new Account(Name = 'TestAccount', BillingStreet = 'testStreet', BillingState = '', BillingCity = 'testcity', BillingPostalCode = '0000', BillingCountry = 'India', 
                                  ShippingStreet = 'testStreet', ShippingState = '', ShippingCity = 'tstcity', ShippingPostalCode = '1111', ShippingCountry = 'India');
        return acc; 
    }
    
    //Create Opportunity records in bulk
    public static List<Opportunity> createBulkOpportunities(Id acctid, Integer numOppties){
        List<Opportunity> opptyLst = new List<Opportunity>();
        for(Integer i=0; i<numOppties; i++)
        {
            opptyLst.add(new Opportunity(Name='TestOpportunity', StageName ='Needs Analysis', CloseDate=Date.newInstance(2016,08,20), AccountId = acctid, Amount=55000));
        }
        return opptyLst;
    }
    
    public static AccountTeamMember createACTM(Id acctid, String role, Id userId){
        AccountTeamMember atm = new AccountTeamMember();
        atm.UserId = userId;
        atm.OpportunityAccessLevel = 'Edit';
        atm.AccountId = acctid;
        atm.TeamMemberRole = role;
        return atm;
    }

}