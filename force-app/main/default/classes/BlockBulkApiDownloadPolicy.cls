global class BlockBulkApiDownloadPolicy implements TxnSecurity.EventCondition{

    public boolean evaluate(SObject event){
        System.debug('BlockBulkApiDownloadPolicy hit');
        BulkApiResultEventStore bare = (BulkApiResultEventStore)event;
        return shouldBlockDownLoad(bare.Query);
    }

    public boolean shouldBlockDownLoad(String query){
        System.debug('BlockBulkApiDownloadPolicy hit2:'+query);
        if(query.containsIgnoreCase('Employee__c')){
            System.debug('ShouldBlock');
            return true;
        }
        return false;
    }
}