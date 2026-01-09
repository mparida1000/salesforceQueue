public class TriggerDispatcher {
    public static void execute(List<SObject> newRecords, Map<Id, SObject> oldRecords, String eventType, Type handlerType){
        ItriggerHandler handler = (ItriggerHandler)handlerType.newInstance(); 
        handler.initialize(newRecords, oldRecords);

        switch on eventType {
            when 'BEFORE_INSERT' {
                handler.beforeInsert();
            }
            when 'AFTER_INSERT' {
                handler.afterInsert();
            }
            when 'BEFORE_UPDATE' {
                handler.beforeUpdate();
            }
            when 'AFTER_UPDATE' {
                handler.afterUpdate();
            }
            when 'BEFORE_DELETE' {
                handler.beforeDelete();
            }
            when 'AFTER_DELETE' {
                handler.afterDelete();
            }
            when else {
                handler.aftereUndelete();
            }
        }
    }
}