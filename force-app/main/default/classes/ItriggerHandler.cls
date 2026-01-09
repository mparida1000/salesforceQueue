public interface ItriggerHandler {
    void initialize(List<SObject> newRecords, Map<Id, SObject> oldRecords);
    void beforeInsert();
    void afterInsert();
    void beforeUpdate();
    void afterUpdate();
    void beforeDelete();
    void afterDelete();
    void aftereUndelete();
}