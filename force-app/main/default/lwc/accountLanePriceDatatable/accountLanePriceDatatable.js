import { api, LightningElement, track, wire } from 'lwc';
import getLanePricesByAccountId from '@salesforce/apex/LanePriceController.getLanePricesByAccountId';
import getSeasons from '@salesforce/apex/LaneSelectorController.getSeasons';

const COLUMNS = [
    { label: 'Price Request', fieldName: 'priceUrl', type: 'url',
      typeAttributes: { label: { fieldName: 'priceRequestName' }, target: '_blank' }, initialWidth: 140 },
    { label: 'Lane Name', fieldName: 'laneName', type: 'text', initialWidth: 160 },
    { label: 'Price', fieldName: 'freightPrice', type: 'currency', initialWidth: 100 },
    { label: 'Trailer Type', fieldName: 'typeOfTrailer', type: 'text', initialWidth: 120 },
    { label: 'Request Date', fieldName: 'requestDate', type: 'date', initialWidth: 110 }
];

const INITIAL_RECORDS = 10;
const LOAD_MORE_RECORDS = 10;

export default class accountLanePriceDatatable extends LightningElement {
    columns = COLUMNS;
    sortDirection = 'asc';
    defaultSortDirection = 'asc';
    
    @api recordId;
    @track data = [];
    @track allData = [];
    @track filteredData = [];
    @track seasonOptions = [];
    @track selectedSeasonId = '';
    @track searchKey = '';
    
    recordsToShow = INITIAL_RECORDS;
    isLoading = false;

    @wire(getSeasons)
    wiredSeasons({ error, data }) {
        if (data) {
            this.seasonOptions = [
                { label: 'All Seasons', value: '' },
                ...data.map(season => ({
                    label: season.Name,
                    value: season.Id
                }))
            ];
        } else if (error) {
            console.error('Failed to load seasons', error);
        }
    }

    @wire(getLanePricesByAccountId, { accountId: '$recordId' })
    wiredLanePrices({ error, data }) {
        if (data) {
            const formattedData = data.map(item => {
                return {...item, priceUrl : '/lightning/r/Price_Request__c/' + item.priceRequestId + '/view'};
            });
            this.allData = formattedData;
            this.filteredData = formattedData;
            this.updateDisplayedData();
        } else if (error) {
            console.error(error);
        }
    }

    handleSeasonChange(event) {
        this.selectedSeasonId = event.target.value;
        this.recordsToShow = INITIAL_RECORDS; // Reset to initial records
        this.applyFilters();
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.recordsToShow = INITIAL_RECORDS; // Reset to initial records
        this.applyFilters();
    }

    applyFilters() {
        let filtered = [...this.allData];
        
        if (this.selectedSeasonId) {
            filtered = filtered.filter(item => {
                return item.seasonId && item.seasonId === this.selectedSeasonId;
            });
        }
        
        if (this.searchKey) {
            filtered = filtered.filter(item => {
                return item.laneName && item.laneName.toLowerCase().includes(this.searchKey);
            });
        }
        
        this.filteredData = filtered;
        this.updateDisplayedData();
    }

    updateDisplayedData() {
        this.data = this.filteredData.slice(0, this.recordsToShow);
    }

    handleLoadMore(event) {
        // Prevent multiple simultaneous loads
        if (this.isLoading) {
            return;
        }

        this.isLoading = true;
        const currentLength = this.data.length;
        
        // Check if we have more records to load
        if (currentLength >= this.filteredData.length) {
            this.isLoading = false;
            return;
        }

        // Simulate async loading for smooth UX
        setTimeout(() => {
            this.recordsToShow += LOAD_MORE_RECORDS;
            this.updateDisplayedData();
            this.isLoading = false;
        }, 200);
    }

    get totalRecords() {
        return this.filteredData.length;
    }

    get recordInfo() {
        return `Showing ${this.data.length} of ${this.totalRecords} records`;
    }
}