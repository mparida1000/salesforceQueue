trigger OpportunityLineItemTrigger2 on OpportunityLineItem (after insert) {
    Set<Id> prodIds = new Set<Id>();
    if(trigger.isAfter && trigger.isInsert){
        for(OpportunityLineItem oli : trigger.new){
            prodIds.add(oli.Product2Id);
        }
    }
    if(!prodIds.isEmpty()){
        //OpportunityLineItemTriggerHandler2.updateProductQuantity(prodIds);
        OpportunityLineItemTriggerHandler2 ol = new OpportunityLineItemTriggerHandler2();
        ol.updateProductQuantity(prodIds);
    }
}