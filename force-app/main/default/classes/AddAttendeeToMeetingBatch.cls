global class AddAttendeeToMeetingBatch implements Database.Batchable<Sobject>{

    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = '';
        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext bc, List<Sobject> scope){

    }

    public void finish(Database.BatchableContext bc){

    }
}