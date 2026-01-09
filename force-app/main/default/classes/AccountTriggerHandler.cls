public class AccountTriggerHandler {

    public static void handleDistributorOptions(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        if (System.Label.enableStateChangeCleanup.equals('Y') && oldAccountsMap != null) {
            System.debug('222222');
            handleStateChangeCleanup(newAccounts, oldAccountsMap);
        }
        createDistributorOptions(newAccounts, oldAccountsMap);
    }

    private static void handleStateChangeCleanup(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Map<Id, String> changedAccounts = new Map<Id, String>();

        for (Account newAcc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(newAcc.Id);
            if (oldAcc != null &&
                    newAcc.BillingState != oldAcc.BillingState &&
                    String.isNotBlank(oldAcc.BillingState)) {
                changedAccounts.put(newAcc.Id, oldAcc.BillingState);
            }
        }

        if (changedAccounts.isEmpty()) return;

        List<Distributor_Option__c> optionsToDelete = [
                SELECT Id
                FROM Distributor_Option__c
                WHERE Account__c IN :changedAccounts.keySet()
        ];
        System.debug('delete size??'+optionsToDelete.size());

        if (!optionsToDelete.isEmpty()) {
            delete optionsToDelete;
        }
    }

    private static void createDistributorOptions(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Set<Id> accountIdsToProcess = new Set<Id>();
        Set<String> statesToQuery = new Set<String>();

        for (Account acc : newAccounts) {
            if (oldAccountsMap == null ||
                    (oldAccountsMap != null &&
                            (acc.BillingState != oldAccountsMap.get(acc.Id).BillingState))) {
                accountIdsToProcess.add(acc.Id);
                if (String.isNotBlank(acc.BillingState)) {
                    statesToQuery.add(acc.BillingState);
                }
            }
        }

        if (accountIdsToProcess.isEmpty() || statesToQuery.isEmpty()) return;

        Map<Id, Set<Id>> existingOptionsMap = getExistingOptionsMap(accountIdsToProcess);

        List<Distributor_Option__c> optionsToInsert = new List<Distributor_Option__c>();

        Map<Id, Account> accountsMap = new Map<Id, Account>([
                SELECT Id, BillingState
                FROM Account
                WHERE Id IN :accountIdsToProcess
                AND BillingState IN :statesToQuery // Filter only relevant states
        ]);

        Map<String, List<Distributor__c>> stateToDistributors = new Map<String, List<Distributor__c>>();
        for (Distributor__c dist : [
                SELECT Id, State__c
                FROM Distributor__c
                WHERE State__c IN :statesToQuery
        ]) {
            if (!stateToDistributors.containsKey(dist.State__c)) {
                stateToDistributors.put(dist.State__c, new List<Distributor__c>());
            }
            stateToDistributors.get(dist.State__c).add(dist);
        }

        for (Account acc : accountsMap.values()) {
            if (stateToDistributors.containsKey(acc.BillingState)) {
                for (Distributor__c dist : stateToDistributors.get(acc.BillingState)) {
                    if (!existingOptionsMap.containsKey(acc.Id) ||
                            !existingOptionsMap.get(acc.Id).contains(dist.Id)) {
                        optionsToInsert.add(new Distributor_Option__c(
                                Account__c = acc.Id,
                                Distributor__c = dist.Id,
                                Selected_by_Customer__c = true
                        ));
                    }
                }
            }
        }

        if (!optionsToInsert.isEmpty()) {
            insert optionsToInsert;
        }
    }

    private static Map<Id, Set<Id>> getExistingOptionsMap(Set<Id> accountIds) {
        Map<Id, Set<Id>> optionsMap = new Map<Id, Set<Id>>();
        for (Distributor_Option__c option : [
                SELECT Account__c, Distributor__c
                FROM Distributor_Option__c
                WHERE Account__c IN :accountIds
        ]) {
            if (!optionsMap.containsKey(option.Account__c)) {
                optionsMap.put(option.Account__c, new Set<Id>());
            }
            optionsMap.get(option.Account__c).add(option.Distributor__c);
        }
        return optionsMap;
    }
}
