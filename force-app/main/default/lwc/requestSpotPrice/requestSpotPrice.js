import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getSpotSeasons from '@salesforce/apex/LaneSelectorController.getSpotSeasons';
import getLocations from '@salesforce/apex/LaneSelectorController.getLocations';
import getTrailerTypePicklistValues from '@salesforce/apex/LaneSelectorController.getTrailerTypePicklistValues';
import getCarriersForSpotPrice from '@salesforce/apex/LaneSelectorController.getCarriersForSpotPrice';
import createPriceRequests from '@salesforce/apex/LaneSelectorController.createPriceRequests';

export default class RequestSpotPrice extends NavigationMixin(LightningElement) {
    @api savedFilters;
    @track selectedSeason = '';
    @track selectedTrailerType = '';
    @track selectedLoadingLocation = '';
    @track selectedDeliveryLocation = '';
    @track potentialCarriers = [];
    @track availablePrices = [];
    @track spotLaneSelectorInfo = [];
    @track isLoading = false;
    @track showResults = false;
    @track showNoResults = false;
    activeTab = 'available';
    @track laneName = '';
    @track showSpotLanePrice = false;
    
    @track loadingLocationOptions = [];
    @track deliveryLocationOptions = [];
    @track seasonOptions = [];
    @track trailerTypeOptions = [];

    get isTrailerTypeDisabled() {
        return !this.selectedSeason;
    }

    get isLoadingLocationDisabled() {
        return !this.selectedSeason || !this.selectedTrailerType;
    }

    get isDeliveryLocationDisabled() {
        return !this.selectedSeason || !this.selectedTrailerType || !this.selectedLoadingLocation;
    }

    get isSendDisabled() {
        return !this.potentialCarriers.some(carrier => carrier.selected === true);
    }

    get isNextDisabled() {
        return !this.availablePrices.some(lane => lane.selectedAccount === true);
    }

    get selectedDeliveryLocationName() {
        const option = this.deliveryLocationOptions.find(opt => opt.value === this.selectedDeliveryLocation);
        return option ? option.label : '';
    }

    get selectedLoadingLocationName() {
        const option = this.loadingLocationOptions.find(opt => opt.value === this.selectedLoadingLocation);
        return option ? option.label : '';
    }

    get hasPotentialCarriers() {
        return this.potentialCarriers && this.potentialCarriers.length > 0;
    }

    get hasAvailablePrices() {
        return this.availablePrices && this.availablePrices.length > 0;
    }

    get isAvailableTab() {
        return this.activeTab === 'available';
    }

    get formattedAvailablePrices() {
        return this.availablePrices.map(lane => ({
            ...lane,
            formattedLanePrice: Number(parseFloat(lane.lanePrice) || 0).toFixed(2),
            formattedTotalPrice: Number(parseFloat(lane.totalPrice) || 0).toFixed(2)
        }));
    }

    areAllFiltersSelected() {
        return this.selectedSeason && this.selectedTrailerType && 
               this.selectedLoadingLocation && this.selectedDeliveryLocation;
    }

    @wire(getSpotSeasons)
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
                type: location.Type__c,
                countryCode: location.Country_Code__c
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

    handleShowAvailablePrices() {
        this.activeTab = 'available';
    }

    handleShowPotentialCarriers() {
        this.activeTab = 'potential';
    }

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    handleSeasonChange(event) {
        this.selectedSeason = event.detail.value;
        this.showResults = false;
        this.showNoResults = false;
        this.potentialCarriers = [];
        this.availablePrices = [];
        
        if (this.areAllFiltersSelected()) {
            this.loadMatchingCarriers();
        }
    }

    handleTrailerTypeChange(event) {
        this.selectedTrailerType = event.detail.value;
        this.showResults = false;
        this.showNoResults = false;
        this.potentialCarriers = [];
        this.availablePrices = [];
        
        if (this.areAllFiltersSelected()) {
            this.loadMatchingCarriers();
        }
    }

    handleLoadingLocationChange(event) {
        this.selectedLoadingLocation = event.detail.value;
        this.showResults = false;
        this.showNoResults = false;
        this.potentialCarriers = [];
        this.availablePrices = [];
        
        if (this.areAllFiltersSelected()) {
            this.loadMatchingCarriers();
        }
    }

    handleDeliveryLocationChange(event) {
        this.selectedDeliveryLocation = event.detail.value;
        
        if (this.areAllFiltersSelected()) {
            this.loadMatchingCarriers();
        }
    }

    async loadMatchingCarriers() {
        this.isLoading = true;
        this.showResults = false;
        this.showNoResults = false;

        try {
            const deliveryLocation = this.deliveryLocationOptions.find(
                loc => loc.value === this.selectedDeliveryLocation
            );

            const loadingLocation = this.loadingLocationOptions.find(
                loc => loc.value === this.selectedLoadingLocation
            );
            
            this.laneName = `${loadingLocation.label} → ${deliveryLocation.label}`;
            
            const result = await getCarriersForSpotPrice({
                deliveryCountryCode: deliveryLocation.countryCode,
                seasonId: this.selectedSeason,
                trailerType: this.selectedTrailerType,
                loadingLocationId: this.selectedLoadingLocation,
                deliveryLocationId: this.selectedDeliveryLocation
            });

            if (!result.potentialCarriers || result.potentialCarriers.length === 0) {
                if (!result.availablePrices || result.availablePrices.length === 0) {
                    this.showNoResults = true;
                    this.potentialCarriers = [];
                    this.availablePrices = [];
                    return;
                }
            }
            
            // Map potential carriers
            this.potentialCarriers = result.potentialCarriers.map((carrier, i) => ({
                ...carrier,
                displayIndex: i + 1,
                selected: false,
                cardClass: 'account-column-lane-selector'
            }));

            // SORT LOGIC: preferredCarrier first, then by lane price ascending
            const sortedPrices = result.availablePrices.sort((a, b) => {
                // Preferred carrier always comes first
                if (a.preferredCarrier && !b.preferredCarrier) return -1;
                if (!a.preferredCarrier && b.preferredCarrier) return 1;
                
                // If both or neither are preferred, sort by lane price (ascending)
                const priceA = a.lanePrice || 0;
                const priceB = b.lanePrice || 0;
                return priceA - priceB;
            });

            // Map available prices - first one selected by default
            this.availablePrices = sortedPrices.map((account, i) => {
                const isSelected = i === 0;
                const lanePrice = account.lanePrice || 0;
                
                return {
                    ...account,
                    displayIndex: i + 1,
                    preferredCarrierLabel: account.preferredCarrier ? ' ✓ Preferred' : '',
                    trailerType: this.selectedTrailerType,
                    loadingLocationId: this.selectedLoadingLocation,
                    deliveryLocationId: this.selectedDeliveryLocation,
                    seasonId: this.selectedSeason,
                    lanePrice: Number(lanePrice.toFixed(2)),
                    lanePriceId: account.trailerTypes?.[0]?.laneId || null,
                    totalPrice: lanePrice ? this.calculateTotalPrice(account, lanePrice) : 0,
                    expanded: false,
                    chevronIcon: 'utility:chevronright',
                    selectedAccount: isSelected,
                    cardClass: isSelected ? 'account-column-lane-selector selected' : 'account-column-lane-selector',
                    
                    fuelSurchargePercentageIncluded: !!lanePrice,
                    priceAdditionalStopsIncluded: !!lanePrice,
                    priceAdditionalStops: account.pricePerStop || 0,
                    additionalStopsQuantity: 2,
                    additionalStopsDisabled: false,
                    
                    accountScores: {
                        availabilityScore: account.accountScores?.[0]?.availabilityScore || 0,
                        priceScore: account.accountScores?.[0]?.priceScore || 0,
                        reliabilityScore: account.accountScores?.[0]?.reliabilityScore || 0
                    }
                };
            });
            
            this.showResults = true;
            
        } catch (error) {
            this.showToast('Error', 'Failed to load carriers: ' + error.body?.message, 'error');
            console.error('Error loading carriers:', error);
            this.potentialCarriers = [];
            this.availablePrices = [];
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

    handleSelectCarrier(event) {
        const accountId = event.target.dataset.id;
        
        this.potentialCarriers = this.potentialCarriers.map(carrier => {
            if (carrier.accountId === accountId) {
                const isSelected = !carrier.selected;
                return {
                    ...carrier,
                    selected: isSelected,
                    cardClass: isSelected ? 'account-column-lane-selector selected' : 'account-column-lane-selector'
                };
            }
            return carrier;
        });
    }

    handleSelectAvailablePrice(event) {
        const accountId = event.target.dataset.id;
        
        this.availablePrices = this.availablePrices.map(account => {
            const isSelected = account.accountId === accountId;
            return {
                ...account,
                selectedAccount: isSelected,
                cardClass: isSelected ? 'account-column-lane-selector selected' : 'account-column-lane-selector'
            };
        });
    }

    handleTotalPriceClick(event) {
        const accountId = event.target.dataset.accountId;

        this.availablePrices = this.availablePrices.map(account => {
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

    handleCheckboxChange(event) {
        const accountId = event.target.dataset.accountId;
        const field = event.target.dataset.field;
        const isChecked = event.target.checked;
                
        this.availablePrices = this.availablePrices.map(account => {
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
                
        this.availablePrices = this.availablePrices.map(account => {
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

        this.availablePrices = this.availablePrices.map(account => {
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

    handleNextToSpotLanePrice() {
        const selectedLane = this.availablePrices.find(lane => lane.selectedAccount === true);
        
        if (!selectedLane) {
            this.showToast('Selection Required', 'Please select an account before proceeding', 'error');
            return;
        }

        // Sort order: 1) selectedAccount first, 2) preferredCarrier second, 3) rest by lane price
        const mappedAndSortedLanes = this.availablePrices
            .map(lane => ({
                ...lane,
                lanePrice: Number(parseFloat(lane.lanePrice || 0).toFixed(2)),
                totalPrice: Number(parseFloat(lane.totalPrice || 0).toFixed(2)),
                expanded: lane.expanded || false,
                chevronIcon: lane.chevronIcon || 'utility:chevronright',
                
                // Pass current price variable states from requestSpotPrice
                fuelSurchargePercentageIncluded: lane.fuelSurchargePercentageIncluded ?? false,
                priceAdditionalStopsIncluded: lane.priceAdditionalStopsIncluded ?? false,
                additionalStopsQuantity: lane.additionalStopsQuantity || 2,
                
                // Initialize other price variables with defaults
                seasonalSurchargeIncluded: false,
                overnightPriceIncluded: false,
                harbourDuesIncluded: false,
                waitingHourIncluded: false,
                palletJackIncluded: false,
                plugInIncluded: false,
                weekendChargesIncluded: false,
                dangerousGoodsIncluded: false,
                palletExchangeIncluded: false,
                tailLiftIncluded: false,
                etsIncluded: false,
                priceFerryIncluded: false,
                price2ndDriverIncluded: false,
                waitingHourQuantity: 1,
                palletExchangeQuantity: 1
            }))
            .sort((a, b) => {
                // 1. Selected account always comes first
                if (a.selectedAccount && !b.selectedAccount) return -1;
                if (!a.selectedAccount && b.selectedAccount) return 1;
                
                // 2. If neither or both are selected, preferredCarrier comes next
                if (a.preferredCarrier && !b.preferredCarrier) return -1;
                if (!a.preferredCarrier && b.preferredCarrier) return 1;
                
                // 3. Sort remaining by lane price (ascending)
                const priceA = parseFloat(a.lanePrice) || 0;
                const priceB = parseFloat(b.lanePrice) || 0;
                return priceA - priceB;
            })
            .map((lane, index) => ({
                ...lane,
                displayIndex: index + 1
            }));

        this.spotLaneSelectorInfo = mappedAndSortedLanes;
        this.showSpotLanePrice = true;
    }

    handlePreviousFromSpotLanePrice(event) {
        const updatedLanes = event.detail;
        
        this.showSpotLanePrice = false;
        
        // Re-sort when coming back: selectedAccount first, then preferredCarrier, then by price
        const sortedLanes = updatedLanes.sort((a, b) => {
            // 1. Selected account first
            if (a.selectedAccount && !b.selectedAccount) return -1;
            if (!a.selectedAccount && b.selectedAccount) return 1;
            
            // 2. Preferred carrier second
            if (a.preferredCarrier && !b.preferredCarrier) return -1;
            if (!a.preferredCarrier && b.preferredCarrier) return 1;
            
            // 3. Sort by lane price (ascending)
            const priceA = parseFloat(a.lanePrice) || 0;
            const priceB = parseFloat(b.lanePrice) || 0;
            return priceA - priceB;
        });
        
        this.availablePrices = sortedLanes.map((lane, index) => {
            const recalculatedTotal = this.recalculateTotalPrice({
                lanePrice: parseFloat(lane.lanePrice) || 0,
                fuelSurchargePercentage: parseFloat(lane.fuelSurchargePercentage) || 0,
                fuelSurchargePercentageIncluded: lane.fuelSurchargePercentageIncluded,
                priceAdditionalStops: parseFloat(lane.priceAdditionalStops) || 0,
                priceAdditionalStopsIncluded: lane.priceAdditionalStopsIncluded,
                additionalStopsQuantity: lane.additionalStopsQuantity || 2
            });
            
            return {
                ...lane,
                displayIndex: index + 1,
                lanePrice: Number(parseFloat(lane.lanePrice || 0).toFixed(2)),
                totalPrice: recalculatedTotal,
                cardClass: lane.selectedAccount ? 'account-column-lane-selector selected' : 'account-column-lane-selector',
                expanded: lane.expanded || false,
                chevronIcon: lane.chevronIcon || 'utility:chevronright'
            };
        });
    }

    handleSelectedAccountUpdate(event) {
        const updatedLanes = event.detail;
        
        this.spotLaneSelectorInfo = updatedLanes;
    }

    handleSpotSuccess() {
        this.dispatchEvent(new CustomEvent('success'));
    }

    async handleCreatePriceRequest() {
        const selectedCarriers = this.potentialCarriers.filter(c => c.selected);
        
        if (selectedCarriers.length === 0) {
            this.showToast('Error', 'Please select at least one carrier', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const accountIds = selectedCarriers.map(c => c.accountId);
            
            await createPriceRequests({
                accountIds: accountIds,
                seasonId: this.selectedSeason,
                trailerType: this.selectedTrailerType,
                loadingLocationId: this.selectedLoadingLocation,
                deliveryLocationId: this.selectedDeliveryLocation
            });

            this.showToast('Success', `Price requests sent to ${selectedCarriers.length} carrier(s)`, 'success');
            this.dispatchEvent(new CustomEvent('success'));
            
        } catch (error) {
            this.showToast('Error', 'Failed to create price requests: ' + error.body?.message, 'error');
            console.error('Error creating price requests:', error);
        } finally {
            this.isLoading = false;
        }
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