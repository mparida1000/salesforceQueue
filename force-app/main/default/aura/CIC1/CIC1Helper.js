({
	calculateInterest : function(component) {
        let principalAmount = component.get("v.principalAmount");
        let interestRate = component.get("v.interestRate");
        let years = component.get("v.years");
        //considering n = 1 as it was not given P (1 + r/n)^(nt)
        let tempVal = principalAmount*(1+ interestRate);
        let finalVal = Math.pow(tempVal, years);
        component.set("v.totalAmount", finalVal);
    }
})