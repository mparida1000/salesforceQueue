public class OpportunityHandler {

    public static void afterInsertEventHandler(List<Opportunity> newList){
		try
        {
			 List<OpportunityTeamMember> oppTeamMemList = OpportunityUtilities.insertAccTeamMemberAsOppTeam(newList);
            system.debug('In Opty Trigger Handler');
            if(!oppTeamMemList.isEmpty()){
            	Insert(oppTeamMemList);
            }
        }catch(Exception e){
            System.debug('Exception occured==:'+e.getMessage()+e.getLineNumber());
        }
	}
    
    public static void UpdateCountOnAccount(Map<Id, Opportunity> oppMap){
        Id accID = oppMap.values()[0].AccountId;
        List<Opportunity> opList =new List<Opportunity> ( [Select ID from Opportunity where AccountID  =: accID and StageName = 'Closed Won']);
        System.debug('Size:'+opList.size());
    }
}