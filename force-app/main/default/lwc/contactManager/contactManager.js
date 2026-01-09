import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getContacts from '@salesforce/apex/ContactController.getContacts';

export default class ContactManager extends LightningElement {
    @track contacts = []; // Track the list of contacts
    @track accountId; // Track the selected Account ID
    @track totalPages;
    @track isFirstPage = true;
    @track isLastPage = false;

    sortedBy;
    sortedDirection = 'asc';
    currentPage = 1;
    pageSize = 5;

    columns = [
        { label: 'First Name', fieldName: 'FirstName', sortable: true },
        { label: 'Last Name', fieldName: 'LastName', sortable: true },
        { label: 'Email', fieldName: 'Email', sortable: true }
    ];

    wiredContactsResult; // Store the wired result for refreshApex

    // Handle successful contact creation
    handleSuccess(event) {
        const evt = new ShowToastEvent({
            title: 'Contact Created',
            message: 'Contact record has been created successfully.',
            variant: 'success',
        });
        this.dispatchEvent(evt);
        this.refreshContacts(); // Refresh the contact list after creation
    }

    // Wire the Apex method to fetch contacts related to the selected account
    @wire(getContacts, { accountId: '$accountId', pageSize: '$pageSize', pageNumber: '$currentPage' })
    wiredContacts(result) {
        this.wiredContactsResult = result; // Store the wire result for refreshApex
        if (result.data) {
            this.contacts = result.data.contacts; // Assign contacts to the tracked variable
            this.totalPages = Math.ceil(result.data.totalRecords / this.pageSize);
            this.isFirstPage = this.currentPage === 1;
            this.isLastPage = this.currentPage === this.totalPages;
        } else if (result.error) {
            this.contacts = [];
            this.totalPages = 0;
            this.isFirstPage = true;
            this.isLastPage = true;
        }
    }

    // Refresh the contact list after creation or pagination
    refreshContacts() {
        refreshApex(this.wiredContactsResult);
    }

    // Handle sorting of the contact list
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;
        this.contacts = this.sortData(this.contacts, sortedBy, sortDirection);
    }

    // Sort data utility function
    sortData(data, fieldName, sortDirection) {
        let parsedData = JSON.parse(JSON.stringify(data));
        let keyValue = (a) => {
            return a[fieldName];
        };
        let isReverse = sortDirection === 'asc' ? 1 : -1;

        parsedData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        return parsedData;
    }

    // Navigate to the next page of contacts
    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.refreshContacts();
        }
    }

    // Navigate to the previous page of contacts
    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.refreshContacts();
        }
    }

    // Handle the account change event
    handleAccountChange(event) {
        this.accountId = event.target.value;
        this.currentPage = 1; // Reset to first page on account change
        this.refreshContacts();
    }
}