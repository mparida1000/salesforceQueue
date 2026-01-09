global class FileEventTransactionHandler implements TxnSecurity.EventCondition{
    public boolean evaluate(SObject event) {
        switch on event {
            when FileEventStore fileEventStore{
                return evaluateFileEventPolicy(fileEventStore);
            }
            when else {
                System.debug('No FileEventStore Policy Applied');
                return false;
            }
        }
    }

    private boolean evaluateFileEventPolicy(FileEventStore fileEventStore){
        if(fileEventStore.FileAction != null && (fileEventStore.FileAction == 'UI_DOWNLOAD' || fileEventStore.FileAction == 'PREVIEW' || fileEventStore.FileAction == 'API_DOWNLOAD')){
            return shouldFileDownLoadBeBlocked(fileEventStore.DocumentId);
        }   
        return false;
    }

    private boolean shouldFileDownLoadBeBlocked(String documentId){
        List<ContentDocumentLink> documentList = [SELECT Id, LinkedEntityId from ContentDocumentLink WHERE ContentDocumentId =: documentId];
        if(documentList.size() == 0 ){
            return false;
        }
        Set<Id> parentIds = new Set<Id>();
        for(ContentDocumentLink cdl : documentList)
            parentIds.add(cdl.LinkedEntityId);//We can check if prefix also starts with 003, then return true
        List<Case> caseList = [SELECT Id from Case WHERE Id in : parentIds and status = 'Closed'];
        if(caseList.size() == 0)
            return false;
        return true;
    }
}