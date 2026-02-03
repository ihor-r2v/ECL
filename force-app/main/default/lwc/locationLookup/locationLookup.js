import { LightningElement, track, wire, api } from 'lwc';
import getDeliveryLocations from '@salesforce/apex/LaneSelectorController.getDeliveryLocations';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LocationLookup extends LightningElement {
    @api selectedLocationId = '';
    @api typeValue;
    @api picklistLabel;

    @track locations = [];
    @track locationOptions = [];
    @track isLoading = false;
    @track error;
    searchKey = '';

    connectedCallback() {
        this.loadLocations();
    }

    handleSearch(event) {
        const inputValue = event.target.value;
        if (inputValue && inputValue !== this.searchKey) {
            this.searchKey = inputValue;
            this.loadLocations();
        }
    }

    loadLocations() {
        this.isLoading = true;
        
        getDeliveryLocations({ type: this.typeValue, searchKey: this.searchKey })
            .then(result => {
                this.locations = result;
                this.locationOptions = result.map(loc => ({
                    label: loc.Name,
                    value: loc.Id
                }));
                this.isLoading = false;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : error.message;
                this.isLoading = false;
            });
    }

    handleSelection(event) {
        this.selectedLocationId = event.detail.value;
        this.showDeleteButton = true;
        this.dispatchEvent(
            new FlowAttributeChangeEvent('selectedLocationId', this.selectedLocationId)
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}