import { LightningElement, api, track } from 'lwc';

export default class RouteFilters extends LightningElement {
    @api loadingCountryFilter;
    @api deliveryCountryFilter;
    @api loadingCountryOptions;
    @api deliveryCountryOptions;
    @api currentPage;
    @api totalPages;
    @api showPagination;
    @api totalRecords;
    @api startRecord;
    @api endRecord;
    @api isSearchActive;

    // Use internal tracked property for search term
    @track _searchTerm = '';

    @api
    get searchTerm() {
        return this._searchTerm;
    }
    set searchTerm(value) {
        this._searchTerm = value;
    }

    get showRecordCount() {
        return this.totalRecords > 0;
    }

    handleLoadingCountryChange(event) {
        this.dispatchEvent(new CustomEvent('loadingcountrychange', {
            detail: { value: event.detail.value }
        }));
    }

    handleDeliveryCountryChange(event) {
        this.dispatchEvent(new CustomEvent('deliverycountrychange', {
            detail: { value: event.detail.value }
        }));
    }

    handleSearchChange(event) {
        this.dispatchEvent(new CustomEvent('searchchange', {
            detail: { value: event.target.value }
        }));
    }

    handlePageChange(event) {
        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: event.detail
        }));
    }
}