({
	principalChanged : function(component, event, helper) {
		let principal = event.getSource().get("v.value");
        component.set("v.principalAmount", principal);
        helper.calculateInterest(component);
	},
    
    interestChanged : function(component, event, helper) {
		let interest = event.getSource().get("v.value");
        component.set("v.interestRate", interest);
        helper.calculateInterest(component);
	},
    
    yearChanged : function(component, event, helper) {
        let years = event.getSource().get("v.value");
        component.set("v.years", years);
        helper.calculateInterest(component);
    }
})