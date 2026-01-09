({
    handlePrincipal : function(component, event, helper){
        let value = event.getSource().get("v.value");
    },
    
    calculate : function(component, event, helper){
        let principal = component.find("principal").get("v.value");
        let interest = component.find("int").get("v.value");
        let sld = component.find("slider").get("v.value");
        
        let compoundInterest = principal * ( 1 + interest / 1 );
        console.log(interest);
        
        component.find("returns").set("v.value", compoundInterest);
    }
})