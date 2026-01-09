global class ReportEventPolicyForConfidentialField implements TxnSecurity.EventCondition{
    public boolean evaluate(SObject event) {
        ReportEvent e = (ReportEvent)event;
        return hasConfidentialDataInReport(e.QueriedEntities, e.ColumnHeaders, e.Operation);
    }

    private boolean hasConfidentialDataInReport(String entities, String query, String Operation){
        List<String> confFields = getConfidentialFieldsInObject('Case');
        for(String field : confFields){
            if(query.containsIgnoreCase(field) && Operation.equals('ReportExported')){
                return true;
            }
        }
        return false;
    }

    private List<String> getConfidentialFieldsInObject(String entity){
        List<String>  confFields = new List<String>();
        List<FieldDefinition> fieldDefinitions = [SELECT DeveloperName, SecurityClassification FROM  
                                                    FieldDefinition WHERE EntityDefinitionId =: entity AND 
                                                    SecurityClassification = 'Confidential'];
        for(FieldDefinition fd : fieldDefinitions){
            confFields.add(fd.DeveloperName.toLowerCase());
        }
        return confFields;
    }

}