global class ConcurrentSessionPolicyCondition implements TxnSecurity.EventCondition {
	public static integer MAX_ADMIN_SESSIONS = 10;
    public static integer MAX_USER_SESSIONS = 2;    
    public boolean evaluate(SObject event){
        LoginEvent e = (LoginEvent)event;
        //upsert e;
        List<User> users = [SELECT ProfileId from User WHERE Id =: e.UserId];
        String profileId = (String)users.get(0).get('ProfileId');
        List<Profile> profiles = [SELECT Name from Profile WHERE id =: profileId];
        String profileName = (String)profiles.get(0).get('Name');
        
        List<AuthSession> sessions = [SELECT Id, CreatedDate, LastModifiedDate, NumSecondsValid, SessionType
                                     	FROM AuthSession 
                                     	WHERE UsersId =: e.UserId and ParentId = NULL];
        if(profileName.equals('System Administrator')){
            return evaluateMaxSession(sessions, MAX_ADMIN_SESSIONS);
        }else{
            return evaluateMaxSession(sessions, MAX_USER_SESSIONS);
        }
    }
    
    public boolean evaluateMaxSession(List<AuthSession> sessions, integer maxSession){
        Map<String, String> sessionToIgnore = (Map<String, String>)Auth.SessionManagement.ignoreForConcurrentSessionLimit(sessions);
        System.debug('sessionToIgnore map:'+sessionToIgnore);
        Integer activeSessions = 0;
        for(AuthSession s : sessions){
            DateTime d = (DateTime)s.get('LastModifiedDate');
            Integer n = (Integer)s.get('NumSecondsValid');
            String sessionId = (String)s.get('Id');
            if(sessionToIgnore.get(sessionId).equals('false')){
                if(d.addSeconds(n) >= DateTime.now()){
                    activeSessions+=1;
                }
                if(activeSessions > maxSession){
                    return true;
                }
            }
        }
        return false;
    }
}