import { LightningElement, track, wire, api } from 'lwc';
import getDeliveryLocations from '@salesforce/apex/LaneSelectorController.getDeliveryLocations';
import deleteLocation from '@salesforce/apex/LaneSelectorController.deleteLocation';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class FlowLocationPicker extends LightningElement {
    @api selectedDeliveryLocationId = '';
    @api typeValue;

    @track locations = [];
    @track locationOptions = [];
    @track isLoading = false;
    @track error;
    searchKey = '';
    showDeleteButton = false;

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
        this.selectedDeliveryLocationId = event.detail.value;
        this.showDeleteButton = true;
        this.dispatchEvent(
            new FlowAttributeChangeEvent('selectedDeliveryLocationId', this.selectedDeliveryLocationId)
        );
    }

    handleDelete() {
        if(!this.selectedDeliveryLocationId) {
            this.showToast('Error', 'Please select a Location to delete.', 'error');
            return;
        }

        this.isLoading = true;
        deleteLocation({ locationId: this.selectedDeliveryLocationId, type: this.typeValue })
            .then(() => {
                this.showToast('Success', 'Location deleted successfully.', 'success');
                this.locationOptions = [];;
            })
            .catch(error => {
                this.showToast('Error', error.body ? error.body.message : error.message, 'error');
            })
            .finally(() => {
                this.showDeleteButton = false;
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}