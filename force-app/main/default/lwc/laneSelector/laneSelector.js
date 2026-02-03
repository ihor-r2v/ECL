import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getTenderSeasons from '@salesforce/apex/LaneSelectorController.getTenderSeasons';
import getLocations from '@salesforce/apex/LaneSelectorController.getLocations';
import getMatchingLanes from '@salesforce/apex/LaneSelectorController.getMatchingLanes';
import getTrailerTypePicklistValues from '@salesforce/apex/LaneSelectorController.getTrailerTypePicklistValues';

// CSV Field Configuration
const CSV_FIELD_CONFIG = [
    { label: 'Rating', path: 'displayIndex' },
    { label: 'Lane Name', path: 'laneName' },
    { label: 'Carrier Name', path: 'accountName' },
    { label: 'Lane Price €', path: 'lanePrice' },
    { label: 'Preferred Carrier', path: 'preferredCarrier', format: (value) => value ? '✓' : ''  },
    { label: 'Trailer Type', path: 'trailerType' },
    { label: 'Loading Postal Code', path: 'loadingPC' },
    { label: 'Delivery Postal Code', path: 'deliveryPC' },

    { label: 'Dangerous goods €', path: 'dangerousGoods' },
    { label: 'Direct ferry €', path: 'priceFerry' },
    { label: 'ETS - price p/ton €', path: 'ets' },
    { label: 'Fuel surcharge percentage %', path: 'fuelSurchargePercentage' },
    { label: 'Harbour dues - price p/ton €', path: 'harbourDues' },
    { label: 'Overnight charges price €', path: 'overnightPrice' },
    { label: 'Pallet exchange price p/pallet €', path: 'palletExchange' },
    { label: 'Pallet jack €', path: 'palletJack' },
    { label: 'Plug-in €', path: 'plugIn' },
    { label: 'Price Per Stop €', path: 'pricePerStop' },
    { label: 'Seasonal surcharge €', path: 'seasonalSurcharge' },
    { label: 'Tail lift €', path: 'tailLift' },
    { label: 'Two Drivers €', path: 'price2ndDriver' },
    { label: 'Waiting costs p/hour €', path: 'waitingHour' },
    { label: 'Weekend charges €', path: 'weekendCharges' }
];

export default class LaneSelector extends NavigationMixin(LightningElement) {
    @api savedFilters;
    @track selectedSeason = '';
    @track selectedTrailerType = '';
    @track selectedLoadingLocation = '';
    @track selectedDeliveryLocation = '';
    @track matchingLanes = [];
    @track isLoading = false;
    @track showResults = false;
    @track showNoResults = false;
    
    @track loadingLocationOptions = [];
    @track deliveryLocationOptions = [];
    @track seasonOptions = [];
    @track trailerTypeOptions = [];

    @api
    get laneSelectorInfo() {
        return this.matchingLanes;
    }
    set laneSelectorInfo(value) {
        if (value && value.length > 0) {
            const firstLane = value[0];
            if (firstLane) {
                this.selectedSeason = firstLane.seasonId || this.selectedSeason;
                this.selectedTrailerType = firstLane.trailerType || this.selectedTrailerType;
                this.selectedLoadingLocation = firstLane.loadingLocationId || this.selectedLoadingLocation;
                this.selectedDeliveryLocation = firstLane.deliveryLocationId || this.selectedDeliveryLocation;
            }
            
            this.matchingLanes = value.map(account => ({
                ...account,
                cardClass: account.selectedAccount ? 'account-column-lane-selector selected' : 'account-column-lane-selector',
                totalPrice: this.recalculateTotalPrice(account)
            }));
            
            this.showResults = true;
            this.showNoResults = false;
        }
    }

    get isTrailerTypeDisabled() {
        return !this.selectedSeason;
    }

    get isLoadingLocationDisabled() {
        return !this.selectedSeason || !this.selectedTrailerType;
    }

    get isCSVDownloadDisabled() {
        return !this.selectedSeason || !this.selectedTrailerType || !this.selectedLoadingLocation || !this.selectedDeliveryLocation || this.showNoResults;
    }

    get isDeliveryLocationDisabled() {
        return !this.selectedSeason || !this.selectedTrailerType || !this.selectedLoadingLocation;
    }

    get isNextDisabled() {
        return !this.matchingLanes.some(lane => lane.selectedAccount === true);
    }

    get selectedLoadingLocationName() {
        const option = this.loadingLocationOptions.find(opt => opt.value === this.selectedLoadingLocation);
        return option ? option.label : '';
    }

    get selectedDeliveryLocationName() {
        const option = this.deliveryLocationOptions.find(opt => opt.value === this.selectedDeliveryLocation);
        return option ? option.label : '';
    }

    get formattedMatchingLanes() {
        return this.matchingLanes.map(lane => ({
            ...lane,
            formattedLanePrice: Number(parseFloat(lane.lanePrice) || 0).toFixed(2),
            formattedTotalPrice: Number(parseFloat(lane.totalPrice) || 0).toFixed(2)
        }));
    }

    @wire(getTenderSeasons)
    wiredSeasons({ error, data }) {
        if (data) {
            this.seasonOptions = data.map(season => ({
                label: season.Name,
                value: season.Id
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load seasons', 'error');
        }
    }

    @wire(getTrailerTypePicklistValues)
    wiredTrailerTypes({ error, data }) {
        if (data) {
            this.trailerTypeOptions = data.map(type => ({
                label: type,
                value: type
            }));
            
            // Set default trailer type to "Frigo - chilled" if not already set
            if (!this.selectedTrailerType && data.includes('Frigo - chilled')) {
                this.selectedTrailerType = 'Frigo - chilled';
            }
        } else if (error) {
            this.showToast('Error', 'Failed to load trailer types', 'error');
        }
    }

    @wire(getLocations)
    wiredLocations({ error, data }) {
        if (data) {
            const locationOptions = data.map(location => ({
                label: location.Name,
                value: location.Id,
                type: location.Type__c
            }));
            
            this.loadingLocationOptions = locationOptions.filter(
                loc => loc.type === 'Loading'
            );
            this.deliveryLocationOptions = locationOptions.filter(
                loc => loc.type === 'Delivery'
            );
        } else if (error) {
            this.showToast('Error', 'Failed to load locations', 'error');
        }
    }

    connectedCallback() {
        if (this.matchingLanes && this.matchingLanes.length > 0) {
            return;
        }
        
        if (this.savedFilters && Object.keys(this.savedFilters).length > 0) {
            this.selectedSeason = this.savedFilters.selectedSeason || '';
            this.selectedTrailerType = this.savedFilters.selectedTrailerType || '';
            this.selectedLoadingLocation = this.savedFilters.selectedLoadingLocation || '';
            this.selectedDeliveryLocation = this.savedFilters.selectedDeliveryLocation || '';
            
            if (this.selectedSeason && this.selectedTrailerType && 
                this.selectedLoadingLocation && this.selectedDeliveryLocation) {
                this.loadMatchingLanes();
            }
        }
    }

    handlePreviousToMode() {
        this.dispatchEvent(new CustomEvent('previoustomode'));
    }

    handleSeasonChange(event) {
        this.selectedSeason = event.detail.value;
        this.selectedLoadingLocation = '';
        this.selectedDeliveryLocation = '';
        this.showResults = false;
        this.showNoResults = false;
        this.matchingLanes = [];
    }

    handleTrailerTypeChange(event) {
        this.selectedTrailerType = event.detail.value;
        this.showResults = false;
        this.showNoResults = false;
        this.matchingLanes = [];
        
        if (this.selectedSeason && this.selectedTrailerType && 
            this.selectedLoadingLocation && this.selectedDeliveryLocation) {
            this.loadMatchingLanes();
        }
    }

    handleLoadingLocationChange(event) {
        this.selectedLoadingLocation = event.detail.value;
        this.showResults = false;
        this.showNoResults = false;
        this.matchingLanes = [];
        
        if (this.selectedSeason && this.selectedTrailerType && 
            this.selectedLoadingLocation && this.selectedDeliveryLocation) {
            this.loadMatchingLanes();
        }
    }

    handleDeliveryLocationChange(event) {
        this.selectedDeliveryLocation = event.detail.value;
        
        if (this.selectedSeason && this.selectedTrailerType && 
            this.selectedLoadingLocation && this.selectedDeliveryLocation) {
            this.loadMatchingLanes();
        }
    }

    handleCSVDownload() {
        try {
            const csvContent = this.buildCsvForTableData(this.matchingLanes);         
            this.downloadCSVForProduct(csvContent, `${this.matchingLanes[0].laneName} ${this.matchingLanes[0].seasonName}.csv`);
            this.showToast('Success', 'CSV file downloaded successfully', 'success'); 
        } catch (error) {
            console.error('Error generating CSV:', error);
            this.showToast('Error', 'Failed to download CSV file', 'error'); 
        }
    }

    buildCsvForTableData(records) {
        const csvHeaders = CSV_FIELD_CONFIG.map(config => config.label);
        const lines = [csvHeaders.join(',')];
        records.forEach(record => {
            const row = CSV_FIELD_CONFIG.map(config => {
                let value = this.getNestedValue(record, config.path);
                if (config.format && value !== undefined && value !== null) value = config.format(value);
                return (value === undefined || value === null) ? '' : this.escapeCSVField(value);
            });
            lines.push(row.join(','));
        });
        return lines.join('\n');
    }

    getNestedValue(obj, path) {
        return path.split('.').reduce((current, prop) => current?.[prop], obj);
    }

    escapeCSVField(field) {
        const str = field.toString();
        if (str.includes(',') || str.includes('"') || str.includes('\n')) {
            return '"' + str.replace(/"/g, '""') + '"';
        }
        return str;
    }

    downloadCSVForProduct(csvContent, fileName) {
        const blob = new Blob([csvContent], { type: 'text/plain' });

        const link = document.createElement('a');
        if (link.download !== undefined) {
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', fileName);
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    }

    async loadMatchingLanes() {
        this.isLoading = true;
        this.showResults = false;
        this.showNoResults = false;

        try {
            const lanes = await getMatchingLanes({
                loadingLocationId: this.selectedLoadingLocation,
                deliveryLocationId: this.selectedDeliveryLocation,
                seasonId: this.selectedSeason,
                trailerTypeName: this.selectedTrailerType
            });

            if (lanes.length === 0) {
                this.showNoResults = true;
                this.matchingLanes = [];
                return;
            }
            
            // Sort lanes: preferredCarrier first, then by index
            const sortedLanes = lanes.sort((a, b) => {
                if (a.preferredCarrier && !b.preferredCarrier) return -1;
                if (!a.preferredCarrier && b.preferredCarrier) return 1;
                return 0;
            });
            
            this.matchingLanes = sortedLanes.map((lane, i) => {
               
                const trailer = lane.trailerTypes?.[0];

                const lanePrice = lane?.lanePrice || 0;

                const isSelected = i === 0;
                return { 
                    ...lane,
                    displayIndex: i + 1,
                    loadingLocationId: this.selectedLoadingLocation,
                    deliveryLocationId: this.selectedDeliveryLocation,
                    seasonId: this.selectedSeason,
                    trailerType: this.selectedTrailerType,
                    lanePrice: Number(lanePrice.toFixed(2)),
                    lanePriceId: trailer?.laneId || null,
                    totalPrice: lanePrice ? this.calculateTotalPrice(lane, lanePrice) : 0,
                    expanded: false,
                    chevronIcon: 'utility:chevronright',
                    selectedAccount: isSelected,
                    cardClass: isSelected ? 'account-column-lane-selector selected' : 'account-column-lane-selector',
                    fuelSurchargePercentageIncluded: lanePrice,
                    priceAdditionalStopsIncluded: lanePrice,
                    priceAdditionalStops: lane.pricePerStop || 0,
                    additionalStopsQuantity: 2,
                    waitingHourQuantity: 1,
                    palletExchangeQuantity: 1,
                    accountScores: {
                        availabilityScore: lane.accountScores?.[0]?.availabilityScore || 0,
                        priceScore: lane.accountScores?.[0]?.priceScore || 0,
                        reliabilityScore: lane.accountScores?.[0]?.reliabilityScore || 0
                    },
                    preferredCarrierLabel: lane.preferredCarrier ? ' ✓ Preferred' : ''
                };
            });
            
            this.showResults = true;
            
        } catch (error) {
            this.showToast('Error', 'Failed to load matching lanes: ' + error.body?.message, 'error');
            console.error('Error loading lanes:', error);
            this.matchingLanes = [];
            this.showNoResults = true;
        } finally {
            this.isLoading = false;
        }
    }

    calculateTotalPrice(lane, lanePrice) {
        let totalPrice = parseFloat(lanePrice) || 0;

        if (lane.fuelSurchargePercentage) {
            totalPrice += (parseFloat(lanePrice) * parseFloat(lane.fuelSurchargePercentage) / 100);
        }
        
        if (lane.pricePerStop) {
            totalPrice += (parseFloat(lane.pricePerStop) * 2);
        }

        return Number((Math.round(totalPrice * 100) / 100).toFixed(2));
    }

    handleTotalPriceClick(event) {
        const accountId = event.target.dataset.accountId;

        this.matchingLanes = this.matchingLanes.map(account => {
            if (account.accountId === accountId) {
                return { 
                    ...account, 
                    expanded: !account.expanded, 
                    chevronIcon: !account.expanded ? 'utility:chevrondown' : 'utility:chevronright' 
                };
            }
            return account;
        });
    }

    handleSelect(event) {
        const accountId = event.target.dataset.id;
        
        this.matchingLanes = this.matchingLanes.map(account => {
            const isSelected = account.accountId === accountId;
            return {
                ...account,
                selectedAccount: isSelected,
                cardClass: isSelected ? 'account-column-lane-selector selected' : 'account-column-lane-selector'
            };
        });
    }

    handleCheckboxChange(event) {
        const accountId = event.target.dataset.accountId;
        const field = event.target.dataset.field;
        const isChecked = event.target.checked;
                
        this.matchingLanes = this.matchingLanes.map(account => {
            if (account.accountId === accountId) {
                const includedFieldName = `${field}Included`;
                const updatedAccount = { 
                    ...account,
                    [includedFieldName]: isChecked
                };
                
                updatedAccount.totalPrice = this.recalculateTotalPrice(updatedAccount);
                
                return updatedAccount;
            }
            return account;
        });
    }

    handleQuantityChange(event) {
        const accountId = event.target.dataset.accountId;
        const field = event.target.dataset.field;
        const quantity = parseInt(event.target.value, 10) || 1;
                
        this.matchingLanes = this.matchingLanes.map(account => {
            if (account.accountId === accountId) {
                const updatedAccount = { 
                    ...account,
                    [field]: quantity
                };
                
                updatedAccount.totalPrice = this.recalculateTotalPrice(updatedAccount);
                
                return updatedAccount;
            }
            return account;
        });
    }

    handleSelectAll(event) {
        const isChecked = event.target.checked;
        const accountId = event.currentTarget.dataset.accountId;

        this.matchingLanes = this.matchingLanes.map(account => {
            if (account.accountId === accountId) {
                const updatedAccount = { 
                    ...account, 
                    fuelSurchargePercentageIncluded: isChecked,
                    priceAdditionalStopsIncluded: isChecked
                };

                updatedAccount.totalPrice = this.recalculateTotalPrice(updatedAccount);
                
                return updatedAccount;
            }
            return account;
        });
    }

    recalculateTotalPrice(account) {
        let totalPrice = parseFloat(account.lanePrice) || 0;

        if (account.fuelSurchargePercentage && account.fuelSurchargePercentageIncluded) {
            totalPrice += (parseFloat(account.lanePrice) * parseFloat(account.fuelSurchargePercentage) / 100);
        }
        
        if (account.priceAdditionalStopsIncluded && account.priceAdditionalStops) {
            totalPrice += (parseFloat(account.priceAdditionalStops) * (account.additionalStopsQuantity || 2));
        }

        return Number((Math.round(totalPrice * 100) / 100).toFixed(2));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('updatelaneselector', {
            detail: this.matchingLanes
        }));
    }

    handleNavigateToRecord(event) {
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
        
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}