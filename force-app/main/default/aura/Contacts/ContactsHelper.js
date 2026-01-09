({
// Fetch the accounts from the Apex controller
      getContactList: function(component) {
        var action = component.get('c.getAccounts');
        action.setParams({
            "aid": component.get("v.recordId")
        });
        // Set up the callback
        var self = this;
        action.setCallback(this, function(actionResult) {
         component.set('v.contacts', actionResult.getReturnValue());
        });
        $A.enqueueAction(action);
      },
    
    updateContact: function(component,event) {
        var status= event.getSource().get("v.value");
        var contactId= event.getSource().get("v.name");
        var action = component.get('c.updateContact');
        action.setParams({
            "contactId": contactId,
            "status" : status
        });
        
        var self = this;
        action.setCallback(this, function(actionResult) {
            var state= actionResult.getState();
            if(state=='SUCCESS'){
                //add message or something
            }
        });
        $A.enqueueAction(action);
      },
    
})