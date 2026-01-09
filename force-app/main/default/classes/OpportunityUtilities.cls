public class OpportunityUtilities { 
    
    public static List<OpportunityTeamMember> insertAccTeamMemberAsOppTeam(List<Opportunity> opptyList){
        List<OpportunityTeamMember> oppTeamMemberList = new List<OpportunityTeamMember>();
        Map<Id,Id> opportunityIdToAccountId = new Map<Id,Id>();
        Map<Id, List<AccountTeamMember>> accountIdToAccountTeamMembers = new  Map<Id, List<AccountTeamMember>>();
       	system.debug('In Opty Trigger');
        
        try{
            for(Opportunity opp : opptyList){
                opportunityIdToAccountId.put(opp.Id,opp.AccountId);
            }
            
            List<AccountTeamMember> accWithAccTeam = new List<AccountTeamMember>
            (
					[select Id,UserId,TeamMemberRole,AccountId,OpportunityAccessLevel
                     from AccountTeamMember 
                     where AccountId in : opportunityIdToAccountId.values()
                       	AND User.IsActive = true]
            );

            if(!accWithAccTeam.isEmpty()){
                for(AccountTeamMember atm : accWithAccTeam){
                    if (!accountIdToAccountTeamMembers.containsKey(atm.AccountId))
                    {
                        accountIdToAccountTeamMembers.put(atm.AccountId, new List<AccountTeamMember>());
                    }
                    
                    accountIdToAccountTeamMembers.get(atm.AccountId).add(atm);
                }                
                for(Opportunity opp : opptyList){
                    Id AccountId = opportunityIdToAccountId.get(opp.Id);
                    for(AccountTeamMember atm : accountIdToAccountTeamMembers.get(AccountId)){
                            OpportunityTeamMember oppTeamMember = new OpportunityTeamMember();
                            oppTeamMember.userId = atm.userId;
                            oppTeamMember.TeamMemberRole = atm.TeamMemberRole;
                            oppTeamMember.OpportunityAccessLevel = atm.OpportunityAccessLevel;
                            oppTeamMember.OpportunityId = opp.Id;
                            oppTeamMemberList.add(oppTeamMember);
                    }
                } 
            } 
        }
        catch(Exception ex){
            System.debug('Execption occured:'+ex.getStackTraceString());
        }
        
        return oppTeamMemberList;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    public static List<Opportunity> getWonOpportunities(){
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name from Opportunity WHERE StageName = 'Closed Won' and CreatedDate >= YESTERDAY]);
        return oppList;
    }
    public static void createTasksForOpportunities(List<Opportunity> oppList){
        List<Task> taskList = new List<Task>();
        if(oppList != null && oppList.size() > 0){
            for(Opportunity opp : oppList){
                Task tsk = new Task(subject = 'Opportunity Closed Won Task', WHATID = opp.Id, ActivityDate = System.today()+7, Status = 'Not Started');
                taskList.add(tsk);
            }
        }
        if(taskList.size() > 0){
            insert taskList;
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}