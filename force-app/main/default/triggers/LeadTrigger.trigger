trigger LeadTrigger on Lead (after update) {
	System.debug('Lead Updated');
    /*for(Lead l : trigger.new){
        Lead oLead = trigger.oldMap.get(l.Id);
        if(l.EmailBouncedDate != oLead.EmailBouncedDate){
            System.debug('EmailBouncedDate is called...');
        }
    }*/
}