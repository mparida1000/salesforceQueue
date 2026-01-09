global with sharing class UserTriedToDownLoadBulkData implements TxnSecurity.EventCondition{
    
    public boolean evaluate(SObject event){
        System.debug('Coming inside UserTriedToDownLoadBulkData');
        switch on event {
            when  ApiEvent apiEvent{
                return evaluate(apiEvent); 
            }
            when ReportEvent reportEvent {
                return false;
            }
            when ListViewEvent listViewEvent {
                return false;
            }
            when LoginEvent loginEvent {
                return false;
            }
            when null{
                return true;
            }
            when else {
                return true;
            }
        }
    }

    private boolean evaluate(ApiEvent apiEvent){
        System.debug('AdditionalInfo: '+apiEvent.AdditionalInfo);
        System.debug('ApiType: '+apiEvent.ApiType);
        System.debug('ApiVersion: '+apiEvent.ApiVersion);
        System.debug('Application: '+apiEvent.Application);
        System.debug('Client: '+apiEvent.Client);
        System.debug('ConnectedAppId: '+apiEvent.ConnectedAppId);
        System.debug('ElapsedTime: '+apiEvent.ElapsedTime);
        System.debug('EvaluationTime: '+apiEvent.EvaluationTime);
        System.debug('EventDate: '+apiEvent.EventDate);
        System.debug('EventIdentifier: '+apiEvent.EventIdentifier);
        System.debug('LoginHistoryId: '+apiEvent.LoginHistoryId);
        System.debug('LoginKey: '+apiEvent.LoginKey);
        System.debug('Operation: '+apiEvent.Operation);
        System.debug('Platform: '+apiEvent.Platform);
        System.debug('PolicyId: '+apiEvent.PolicyId);
        System.debug('PolicyOutcome: '+apiEvent.PolicyOutcome);
        System.debug('QueriedEntities: '+apiEvent.QueriedEntities);
        System.debug('Query: '+apiEvent.Query);
        System.debug('Records: '+apiEvent.Records);
        System.debug('RelatedEventIdentifier: '+apiEvent.RelatedEventIdentifier);
        System.debug('RowsProcessed: '+apiEvent.RowsProcessed);
        System.debug('RowsReturned: '+apiEvent.RowsReturned);
        System.debug('SessionKey: '+apiEvent.SessionKey);
        System.debug('SessionLevel: '+apiEvent.SessionLevel);
        System.debug('SourceIp: '+apiEvent.SourceIp);
        System.debug('UserAgent: '+apiEvent.UserAgent);
        System.debug('UserId: '+apiEvent.UserId);
        System.debug('Username: '+apiEvent.Username);
        
        User user = [SELECT Profile.Name from USER where ID =: apiEvent.UserId];
        if(user.profile.Name == 'Custom Admin' && (apiEvent.Query.contains('Employee__c') ||  apiEvent.Query.contains('Tech_Firm__c') ) && 
         apiEvent.rowsProcessed > 50){
            return true;
        }
        return false;
    }
}