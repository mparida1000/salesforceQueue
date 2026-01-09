public abstract class BaseTriggerHandler implements ItriggerHandler{
    public List<SObject> newRecords;
    public Map<Id, SObject> oldMap;
    public BaseTriggerHandler(){}
    public void initialize(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }
    public virtual void beforeInsert(){}
    public virtual void afterInsert(){}
    public virtual void beforeUpdate(){}
    public virtual void afterUpdate(){}
    public virtual void beforeDelete(){}
    public virtual void afterDelete(){}
    public virtual void aftereUndelete(){}
}