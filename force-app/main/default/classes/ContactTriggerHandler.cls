public class ContactTriggerHandler {
    public static void updateAccountContactCounts(List<Contact> newContacts, Map<Id, Contact> oldContactMap, Boolean isDelete) {
        Set<Id> accountIds = new Set<Id>();

        if (isDelete) {
            for (Contact oldCon : oldContactMap.values()) {
                if (oldCon.AccountId != null) {
                    accountIds.add(oldCon.AccountId);
                }
            }
        } else {
            for (Contact con : newContacts) {
                if (con.AccountId != null) {
                    accountIds.add(con.AccountId);
                }
            }
            //We need to take care of old account ids too.
            if (oldContactMap != null) {
                for (Contact newCon : newContacts) {
                    Contact oldCon = oldContactMap.get(newCon.Id);
                    if (oldCon != null && oldCon.AccountId != null && oldCon.AccountId != newCon.AccountId) {
                        accountIds.add(oldCon.AccountId);
                    }
                }
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> accountContactCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
                SELECT AccountId, COUNT(Id) cnt
                FROM Contact
                WHERE AccountId IN :accountIds
                GROUP BY AccountId
        ]) {
            accountContactCountMap.put((Id)ar.get('AccountId'), (Integer)ar.get('cnt'));
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Id accId : accountIds) {
            Integer count = accountContactCountMap.containsKey(accId) ? accountContactCountMap.get(accId) : 0;
            accountsToUpdate.add(new Account(Id=accId, Total_Contacts__c = count));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}