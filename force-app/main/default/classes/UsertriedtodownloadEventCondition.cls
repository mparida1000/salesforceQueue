global class UsertriedtodownloadEventCondition implements TxnSecurity.EventCondition {

	public boolean evaluate(SObject event) {
		return false;
	}

}