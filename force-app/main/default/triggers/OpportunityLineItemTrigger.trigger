trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after delete) {
    Set<Id> oppIds = new Set<Id>();
    if(trigger.isAfter && trigger.isInsert){
        for(OpportunityLineItem product : trigger.new){
            if(product.opportunityId != null){
                oppIds.add(product.opportunityId);
            }
        }
    }
    if(trigger.isAfter && trigger.isDelete){
        for(OpportunityLineItem product : trigger.old){
            if(product.opportunityId != null){
                oppIds.add(product.opportunityId);
            }
        }
    }
    if(!oppIds.isEmpty()){
        System.debug('Calling Handler');
        OpportunityLineItemTriggerHandler.updateTotalProductsInAccount(oppIds);
    }
}