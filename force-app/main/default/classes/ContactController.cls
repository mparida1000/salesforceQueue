public with sharing class ContactController {
    @AuraEnabled(cacheable=true)
    public static ContactPage getContacts(Id accountId, Integer pageSize, Integer pageNumber) {
        // Initialize result object
        ContactPage result = new ContactPage();
        
        // Check if accountId is not null
        if (accountId != null) {
            // Query contacts related to the account with pagination
            List<Contact> contacts = [
                SELECT Id, FirstName, LastName, Email 
                FROM Contact 
                WHERE AccountId = :accountId
                ORDER BY LastName
                LIMIT :pageSize OFFSET :((pageNumber - 1) * pageSize)
            ];

            // Query total number of records for pagination
            Integer totalRecords = [SELECT COUNT() FROM Contact WHERE AccountId = :accountId];
            
            // Assign the queried data to the result object
            result.contacts = contacts;
            result.totalRecords = totalRecords;
        } else {
            // If accountId is null, return an empty list
            result.contacts = new List<Contact>();
            result.totalRecords = 0;
        }

        return result;
    }

    // Inner class to structure the response
    public class ContactPage {
        @AuraEnabled public List<Contact> contacts;
        @AuraEnabled public Integer totalRecords;
    }
}