public class CaseTriggerHandler extends BaseTriggerHandler{
    public CaseTriggerHandler() {

    }
    public override void beforeInsert(){
        List<SObject> newR = (List<Case>)newRecords;
        Map<Id, SObject> oldM = (Map<Id, SObject>)this.oldMap;
        System.debug('METHOD - beforeInsert'+newR + '--'+oldM);
    }
    public override void afterInsert(){
        List<SObject> newR = (List<Case>)newRecords;
        Map<Id, SObject> oldM = (Map<Id, SObject>)this.oldMap;
        System.debug('METHOD - afterInsert'+newR + '--'+oldM);
    }
    public override void beforeUpdate(){
        List<SObject> newR = (List<Case>)newRecords;
        Map<Id, SObject> oldM = (Map<Id, SObject>)this.oldMap;
        System.debug('METHOD - beforeUpdate'+newR + '--'+oldM);
    }
    public override void afterUpdate(){
        List<SObject> newR = (List<Case>)newRecords;
        Map<Id, SObject> oldM = (Map<Id, SObject>)this.oldMap;
        System.debug('METHOD - afterUpdate'+newR + '--'+oldM);
    }
    public override void beforeDelete(){
        List<SObject> newR = (List<Case>)newRecords;
        Map<Id, SObject> oldM = (Map<Id, SObject>)this.oldMap;
        System.debug('METHOD - beforeDelete'+newR + '--'+oldM);
    }
    public override void afterDelete(){
        List<SObject> newR = (List<Case>)newRecords;
        Map<Id, SObject> oldM = (Map<Id, SObject>)this.oldMap;
        System.debug('METHOD - afterDelete'+newR + '--'+oldM);
    }
    public override void aftereUndelete(){
        List<SObject> newR = (List<Case>)newRecords;
        Map<Id, SObject> oldM = (Map<Id, SObject>)this.oldMap;
        System.debug('METHOD - aftereUndelete'+newR + '--'+oldM);
    }

    
}