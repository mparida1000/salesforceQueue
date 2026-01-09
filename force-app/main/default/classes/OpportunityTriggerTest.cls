@isTest
public class OpportunityTriggerTest {

    @isTest static void addATMasOTM(){
        List<Opportunity> opptnty = new List<Opportunity>();
        User usr1 = TestdataUtility.createUser('System Administrator');
        insert usr1;
        
        User usr2 = TestdataUtility.createUser('System Administrator');
        usr2.UserName = 'unique_tes111t@mfstest.com';
        usr2.Lastname = 'Parida';
        usr2.Email = 'test@iiiiiim.com';
        insert usr2;
            
        Account acc = TestDataUtility.createAccount();
        insert acc;
        
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        atmList.add(TestdataUtility.createACTM(acc.Id, 'Sales Manager',usr1.Id));
        atmList.add(TestdataUtility.createACTM(acc.Id, 'Account Manager',usr2.Id));
        insert atmList;
        system.debug('atmList size:'+atmList);

        List<Opportunity> oppList = TestDataUtility.createBulkOpportunities(acc.Id, 10);
        insert oppList;
        
        	List<Id> opportunityTeamMemberUserIdList = new List<Id>();
            List<AccountTeamMember> act = new List<AccountTeamMember>([select UserId,AccountId from AccountTeamMember where AccountId =: acc.ID]);
            List<Id> accountTeamMemberUserIdLIst = new List<Id>();
            for(AccountTeamMember atm : act)
            {
                accountTeamMemberUserIdLIst.add(atm.UserId);
            }
            System.debug('accountTeamMemberUserIdLIst..'+accountTeamMemberUserIdLIst);
            List<OpportunityTeamMember> otm = new List<OpportunityTeamMember>([Select UserId,OpportunityId from OpportunityTeamMember where OpportunityId =: oppList[0].Id]);
            for(OpportunityTeamMember opp : otm)
            {
                opportunityTeamMemberUserIdList.add(opp.UserId);
            }

        system.debug('opportunityTeamMemberUserIdList:::'+opportunityTeamMemberUserIdList);
        //system.assertEquals(accountTeamMember.values(), opportunityTeamMember.values(), 'ACT and OPT are same');
        
    }
}