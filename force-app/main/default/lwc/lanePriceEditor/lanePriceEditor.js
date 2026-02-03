import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
// Apex imports
import getLanePrices from '@salesforce/apex/PriceRequestController.getLanePrices';
import updateFreightPrices from '@salesforce/apex/PriceRequestController.updateFreightPrices';
import getPriceRequestById from '@salesforce/apex/PriceRequestController.getPriceRequestById';
import getCountryCodeToNameMap from '@salesforce/apex/PriceRequestController.getCountryCodeToNameMap';
import getAccountByLanePrice from '@salesforce/apex/PriceRequestController.getAccountByLanePrice';
import updateAccountByLanePrice from '@salesforce/apex/PriceRequestController.updateAccountByLanePrice';
import requestPermissionToChange from '@salesforce/apex/PriceRequestController.requestPermissionToChange';
import getAccessCodeFromAccount from '@salesforce/apex/PriceRequestController.getAccessCodeFromAccount';
import getExistingLanePrices from '@salesforce/apex/PriceRequestController.getExistingLanePrices';
import updateExistingLanePrices from '@salesforce/apex/PriceRequestController.updateExistingLanePrices';
// Static resources
import Logo from '@salesforce/resourceUrl/Logo_2';
import ECL_Logo from '@salesforce/resourceUrl/ECL_Logo';
import backgroundPhoto from '@salesforce/resourceUrl/backgroundPhoto';

// CONFIGURATION CONSTANTS
const TRAILER_TYPE_OPTIONS = [
    { label: 'Cooled', value: 'Cooled' },
    { label: 'Frigo', value: 'Frigo' },
    { label: 'Dual Temp', value: 'Dual Temp' }
];
const BASE_COLUMNS = [
    { label: 'Lane', fieldName: 'laneName', initialWidth: 280 },
    { label: 'Loading(PC)', fieldName: 'loadingPostalCode' },
    { label: 'Loading (CC)', fieldName: 'loadingCountryCode' },
    { label: 'Delivery(PC)', fieldName: 'deliveryPostalCode' },
    { label: 'Delivery (CC)', fieldName: 'deliveryCountryCode' },
    { label: 'Type Of Trailer', fieldName: 'typeOfTrailer', 
        type: 'picklistColumn',
        editable: false,
        typeAttributes: {
            placeholder: 'Choose Type',
            options: TRAILER_TYPE_OPTIONS,
        }
    },
    { label: '€ Price', fieldName: 'freightPrice', type: 'number', editable: true, 
      cellAttributes: { alignment: 'left' }, initialWidth: 150, 
      typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 } }
];
const EXISTING_PRICES_COLUMNS = [
    { label: 'Lane', fieldName: 'laneName', initialWidth: 280 },
    { label: 'Source PR', fieldName: 'sourcePriceRequestName', initialWidth: 150 },
    { label: 'Loading(PC)', fieldName: 'loadingPostalCode' },
    { label: 'Loading (CC)', fieldName: 'loadingCountryCode' },
    { label: 'Delivery(PC)', fieldName: 'deliveryPostalCode' },
    { label: 'Delivery (CC)', fieldName: 'deliveryCountryCode' },
    { label: 'Type Of Trailer', fieldName: 'typeOfTrailer', 
        type: 'picklistColumn',
        editable: true,
        typeAttributes: {
            placeholder: 'Choose Type',
            options: TRAILER_TYPE_OPTIONS,
        }
    },
    { label: '€ Price', fieldName: 'freightPrice', type: 'number', editable: true, 
      cellAttributes: { alignment: 'left' }, initialWidth: 150, 
      typeAttributes: { minimumFractionDigits: 2, maximumFractionDigits: 2 } }
];

export default class LanePriceEditor extends LightningElement {
    
    // STATIC RESOURCES
    logo = Logo;
    ECL_background = ECL_Logo;

    // DATA PROPERTIES
    baseColumns = BASE_COLUMNS;
    existingPricesColumns = EXISTING_PRICES_COLUMNS;

    lanePrices = [];
    allLanePrices = [];
    filteredLanePrices = [];
    draftValues = [];
    accountDraftValues = [];
    loadingCountryOptions = [];
    deliveryCountryOptions = [];
    countryCodeToName = {};
    account;
    priceRequest;
    existingLanePrices = [];
    allExistingLanePrices = [];
    filteredExistingLanePrices = [];
    hasExistingPrices = false;
    existingLanePricesDraftValues = [];
    
    // STATE PROPERTIES
    isLoading = false;
    isLoadingPage = true;
    isSubmitPage = false;
    isWorkPage = false;
    allowChanges = true;
    allowChangesWasSend = false;
    hasTemporarySave = false;
    showAdditionalInfo = true;
    
    // Notification state
    showNotification = false;
    notificationTitle = '';
    notificationMessage = '';
    notificationVariant = 'success';
    
    // Feature visibility flags
    showAdditionalStops = false;
    showDirectFerry = false;
    showTwoDrivers = false;
    showFuelSurchargePercentage = false;
    showOvernightCharges = false;
    showPlugIn = false;
    showWaitingHour = false;
    showHarbourDues = false;
    showETS = false;
    showSeasonalSurcharge = false;
    showWeekendCharges = false;
    showDangerousGoods = false;
    showPalletExchange = false;
    showTailLift = false;
    showPalletJack = false;

    // Filter and search state
    searchTerm = '';
    isSearchActive = false;
    loadingCountryFilter = '';
    deliveryCountryFilter = '';
    
    // Pagination state
    currentPage = 1;
    recordsPerPage = 200;
    totalRecords = 0;
    numOfMandatoryLanes = 0;
    activeTab = 'mandatory';
    
    // Sorting state
    sortedBy = 'mandatory';
    sortDirection = 'desc';
    
    // ID PROPERTIES
    priceRequestId;
    accountId;
    error;
    
    // SECURITY PROPERTIES
    secretCode = '';
    secretCodeIsNotValid = false;
    codeFromUser = '';
    
    // UI TEXT CONSTANTS
    temporarySave = 'This is a temporary save. Please submit your prices';
    requestEditAccessText = 'Prices have already been submitted. To make changes, please request edit access';

    // LIFECYCLE HOOKS
    connectedCallback() {
        this.isLoadingPage = true;
        this.isWorkPage = false;
        const bypass = sessionStorage.getItem('bypassCode');
        if (bypass === 'true') {
            this.isLoadingPage = false;
            this.isWorkPage = true;
        }
        this.isSubmitPage = false;
    }

    // WIRE ADAPTERS
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state.id) {
            this.priceRequestId = currentPageReference.state.id;
            this.loadPriceRequestData();
        }
    }
  
    // Page state getters
    get getIsLoadingPage() {
        return this.isLoadingPage;
    }

    get getIsWorkPage() {
        return this.isWorkPage;
    }

    get showSubmitPage() {
        return this.isSubmitPage;
    }

    get currentColumns() {
        return this.activeTab === 'existing' ? this.existingPricesColumns : this.baseColumns;
    }
    get shouldShowTabs() {
        // Show tabs if we have any lanes in any category
        return this.allLanePrices.length > 0 || this.hasExistingPrices;
    }
    
    // Permission getters
    get getAllowChanges() {
        return !this.allowChanges;
    }

    get getAllowChangesWasSend() {
        return this.allowChangesWasSend;
    }
    
    // Validation getters
    get thisCodeCheckingIfValid() {
        return this.secretCodeIsNotValid;
    }

    get isTermporarySave() {
        return this.hasTemporarySave;
    }

    // Data getters
    get title() {
        return this.account.Name + ' - ' + this.priceRequest.Season__r.Name;
    }
    
    // Pagination getters
    get totalPages() {
        if (this.activeTab === 'charges') {
            return 0;
        }
        
        let recordsToCount;
        if (this.activeTab === 'existing') {
            recordsToCount = this.filteredExistingLanePrices.length;
        } else {
            recordsToCount = this.activeTab === 'mandatory' 
                ? this.getMandatoryRecords().length 
                : this.getNonMandatoryRecords().length;
        }
        
        return Math.ceil(recordsToCount / this.recordsPerPage);
    }

    get showPagination() {
        if (this.activeTab === 'charges') {
            return false;
        }
        
        const recordsToCount = this.activeTab === 'mandatory' 
            ? this.getMandatoryRecords().length 
            : this.getNonMandatoryRecords().length;
        
        return recordsToCount > this.recordsPerPage;
    }

    get totalRecords() {
        if (this.activeTab === 'charges') {
            return 0;
        }
        
        if (this.activeTab === 'existing') {
            return this.filteredExistingLanePrices.length;
        }
        
        return this.activeTab === 'mandatory' 
            ? this.getMandatoryRecords().length 
            : this.getNonMandatoryRecords().length;
    }

    get startRecord() {
        if (this.activeTab === 'charges') {
            return 0;
        }
        
        const recordsToCount = this.activeTab === 'mandatory' 
            ? this.getMandatoryRecords().length 
            : this.getNonMandatoryRecords().length;
        
        if (recordsToCount === 0) return 0;
        
        return ((this.currentPage - 1) * this.recordsPerPage) + 1;
    }

    get endRecord() {
        if (this.activeTab === 'charges') {
            return 0;
        }
        
        const recordsToCount = this.activeTab === 'mandatory' 
            ? this.getMandatoryRecords().length 
            : this.getNonMandatoryRecords().length;
        
        if (recordsToCount === 0) return 0;
        
        const calculatedEnd = this.currentPage * this.recordsPerPage;
        return calculatedEnd > recordsToCount ? recordsToCount : calculatedEnd;
    }
    
    // Style getters
    get loginContainerStyle() {
        return `background-image: url(${this.ECL_background}); background-size: cover; background-position: center; background-repeat: no-repeat; background-attachment: fixed;`;
    }

    get containerStyle() {
        return `background-image: url(${backgroundPhoto}); background-size: cover; background-position: center; background-repeat: no-repeat; background-attachment: fixed;`;
    }
    
    // Notification getters
    get notificationClass() {
        const baseClasses = 'custom-notification slds-notify slds-notify_alert';
        const variantClass = {
            'success': 'slds-alert_success',
            'error': 'slds-alert_error',
            'info': 'slds-alert_info',
            'warning': 'slds-alert_warning'
        };
        return `${baseClasses} ${variantClass[this.notificationVariant] || variantClass.info}`;
    }

    get notificationIcon() {
        const icons = {
            'success': 'utility:success',
            'error': 'utility:error',
            'info': 'utility:info',
            'warning': 'utility:warning'
        };
        return icons[this.notificationVariant] || icons.info;
    }

    // DATA LOADING METHODS
    loadPriceRequestData() {
        if (!this.priceRequestId) return;
        
        this.isLoading = true;
        
        getPriceRequestById({ priceRequestId: this.priceRequestId })
            .then(priceRequestData => {
                this.accountId = priceRequestData.Account__c;
                this.priceRequest = priceRequestData;
                this.setCheckboxVisibility(priceRequestData);
                this.allowChanges = priceRequestData.Stage__c === 'Answer received' ? false : true;
                this.loadAllData();
            })
            .catch(error => {
                this.showCustomNotification(
                    'Error Loading Price Request',
                    this.reduceErrors(error).join(', '),
                    'error'
                );
                this.isLoading = false;
            });
    }

    async loadAllData() {
        if (!this.priceRequestId) return;
        this.isLoading = true;
        
        try {
            const laneData = await getLanePrices({ 
                priceRequestId: this.priceRequestId, 
                howMany: 1000000, 
                offset: 0 
            });

            this.countryCodeToName = await getCountryCodeToNameMap();
            
            const transformedData = laneData.map(lane => {
                return {
                    ...lane,
                    id: lane.Id || lane.id,
                    typeOfTrailer: lane.typeOfTrailer || '',
                    additionalStops: lane.additionalStops !== undefined ? lane.additionalStops : '',
                    twoDrivers: lane.twoDrivers !== undefined ? lane.twoDrivers : null,
                    directFerry: lane.directFerry !== undefined ? lane.directFerry : null,
                    freightPrice: lane.freightPrice !== undefined ? lane.freightPrice : ''
                };
            });
            
            this.allLanePrices = transformedData;
            
            if (transformedData.length > 0) {
                this.numOfMandatoryLanes = transformedData.filter(lane => lane.mandatory === true).length;
            }

            // Load existing prices
            const existingData = await getExistingLanePrices({ priceRequestId: this.priceRequestId });
            if (existingData && existingData.length > 0) {
                const transformedExistingData = existingData.map(lane => {
                    return {
                        ...lane,
                        id: lane.currentPriceRequestLaneId, // Use current PR lane ID for updates
                        originalId: lane.id, // Keep original for reference
                        typeOfTrailer: lane.typeOfTrailer || '',
                        freightPrice: lane.freightPrice !== undefined ? lane.freightPrice : ''
                    };
                });
                
                this.allExistingLanePrices = transformedExistingData;
                this.filteredExistingLanePrices = transformedExistingData;
                this.hasExistingPrices = true;
            } else {
                this.hasExistingPrices = false;
            }

            // Initialize filters based on available data
            if (transformedData.length > 0) {
                this.initFilterOptions(transformedData);
                this.accountId = transformedData[0].accountID;
            } else if (existingData && existingData.length > 0) {
                // If only existing prices, use them for filter initialization
                this.initFilterOptions(existingData);
                this.accountId = existingData[0].accountID;
            }
            
            // Load account data
            if (this.showAdditionalInfo && this.accountId) {
                const accountData = await getAccountByLanePrice({ accountId: this.accountId });
                if (accountData) {
                    this.account = accountData;
                }
            }
            
            this.loadTemporaryData();
            this.applyFiltersAndPagination();
            this.error = undefined;
        } catch (error) {
            this.showCustomNotification(
                'Error Loading Data',
                this.reduceErrors(error).join(', '),
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    setCheckboxVisibility(priceRequest) {
        this.showAdditionalInfo = priceRequest.Show_Additional_Information__c || false;        
        this.showAdditionalStops = priceRequest.Additional_stops__c || false;
        this.showDirectFerry = priceRequest.Direct_Ferry__c || false;
        this.showTwoDrivers = priceRequest.Two_drivers__c || false;
        this.showFuelSurchargePercentage = priceRequest.Fuel_surcharge_percentage__c || false;
        this.showOvernightCharges = priceRequest.Overnight_charges__c || false;
        this.showPlugIn = priceRequest.Plug_in__c || false;
        this.showWaitingHour = priceRequest.Waiting_hours__c || false;
        this.showHarbourDues = priceRequest.Harbour_dues__c || false;
        this.showETS = priceRequest.ETS__c || false;
        this.showSeasonalSurcharge = priceRequest.Seasonal_surcharge__c || false;
        this.showWeekendCharges = priceRequest.Weekend_charges__c || false;
        this.showDangerousGoods = priceRequest.Dangerous_Goods__c || false;
        this.showPalletExchange = priceRequest.Pallet_exchange__c || false;
        this.showTailLift = priceRequest.Tail_lift__c || false;
        this.showPalletJack = priceRequest.Pallet_jack__c || false;
    }

    // LOCAL STORAGE METHODS
    getStorageKey() {
        return `priceRequest_${this.priceRequestId}`;
    }

    loadTemporaryData() {
        try {
            const storageKey = this.getStorageKey();
            const savedData = localStorage.getItem(storageKey);
            
            if (savedData) {
                const parsedData = JSON.parse(savedData);
                
                if (parsedData.laneDraftValues && parsedData.laneDraftValues.length > 0) {
                    this.draftValues = parsedData.laneDraftValues;
                    
                    this.allLanePrices = this.allLanePrices.map(lane => {
                        const draft = this.draftValues.find(d => d.id === lane.id);
                        return draft ? { ...lane, ...draft } : lane;
                    });
                }
                
                // Load existing lane prices draft values
                if (parsedData.existingLanePricesDraftValues && parsedData.existingLanePricesDraftValues.length > 0) {
                    this.existingLanePricesDraftValues = parsedData.existingLanePricesDraftValues;
                    
                    this.allExistingLanePrices = this.allExistingLanePrices.map(lane => {
                        const draft = this.existingLanePricesDraftValues.find(d => d.id === lane.id);
                        return draft ? { ...lane, ...draft } : lane;
                    });
                }
                
                if (parsedData.accountDraftValues && parsedData.accountDraftValues.length > 0) {
                    this.accountDraftValues = parsedData.accountDraftValues;
                    
                    if (this.account && this.accountDraftValues.length > 0) {
                        this.account = { ...this.account, ...this.accountDraftValues[0] };
                    }
                }
                
                this.hasTemporarySave = true;
            }
        } catch (error) {
            console.error('Error loading temporary data:', error);
        }
    }

    saveTemporaryData() {
        try {
            const storageKey = this.getStorageKey();
            
            const dataToSave = {
                laneDraftValues: this.draftValues,
                existingLanePricesDraftValues: this.existingLanePricesDraftValues,
                accountDraftValues: this.accountDraftValues,
                timestamp: new Date().toISOString()
            };
            
            localStorage.setItem(storageKey, JSON.stringify(dataToSave));
            this.hasTemporarySave = true;
            
            return true;
        } catch (error) {
            console.error('Error saving temporary data:', error);
            return false;
        }
    }

    clearTemporaryData() {
        try {
            const storageKey = this.getStorageKey();
            localStorage.removeItem(storageKey);
            this.hasTemporarySave = false;
        } catch (error) {
            console.error('Error clearing temporary data:', error);
        }
    }

    // FILTER & PAGINATION METHODS
    initFilterOptions(data) {
        const loadingCountries = [...new Set(data.map(item => item.loadingLocationCode))].filter(code => code);
        const deliveryCountries = [...new Set(data.map(item => item.destinationLocationCode))].filter(code => code);

        this.loadingCountryOptions = [
            { label: '-- All --', value: '' }, 
            ...loadingCountries.map(code => ({ 
                label: `${this.countryCodeToName[code] || code} (${code})`, 
                value: code 
            }))
        ];
        
        this.deliveryCountryOptions = [
            { label: '-- All --', value: '' }, 
            ...deliveryCountries.map(code => ({ 
                label: `${this.countryCodeToName[code] || code} (${code})`, 
                value: code 
            }))
        ];
    }

    initFilterOptionsForActiveTab() {
        let dataForFilters = [];
        
        if (this.activeTab === 'mandatory') {
            dataForFilters = this.allLanePrices.filter(lane => lane.mandatory === true);
        } else if (this.activeTab === 'optional') {
            dataForFilters = this.allLanePrices.filter(lane => lane.mandatory !== true);
        } else if (this.activeTab === 'existing') {
            dataForFilters = this.allExistingLanePrices;
        } else {
            return;
        }

        const loadingCountries = [...new Set(dataForFilters.map(item => item.loadingLocationCode))].filter(code => code);
        const deliveryCountries = [...new Set(dataForFilters.map(item => item.destinationLocationCode))].filter(code => code);

        this.loadingCountryOptions = [
            { label: '-- All --', value: '' }, 
            ...loadingCountries.map(code => ({ 
                label: `${this.countryCodeToName[code] || code} (${code})`, 
                value: code 
            }))
        ];
        
        this.deliveryCountryOptions = [
            { label: '-- All --', value: '' }, 
            ...deliveryCountries.map(code => ({ 
                label: `${this.countryCodeToName[code] || code} (${code})`, 
                value: code 
            }))
        ];
    }

    resetFilters() {
        this.loadingCountryFilter = '';
        this.deliveryCountryFilter = '';
        this.searchTerm = '';
        this.isSearchActive = false;
    }

    getMandatoryRecords() {
        return this.filteredLanePrices.filter(record => record.mandatory === true);
    }

    getNonMandatoryRecords() {
        return this.filteredLanePrices.filter(record => record.mandatory !== true);
    }

    applyFiltersAndPagination() {
        let sourceData = this.activeTab === 'existing' ? this.allExistingLanePrices : this.allLanePrices;
        
        let filteredData = sourceData.filter(row => {
            const matchLoading = this.loadingCountryFilter ? row.loadingLocationCode === this.loadingCountryFilter : true;
            const matchDelivery = this.deliveryCountryFilter ? row.destinationLocationCode === this.deliveryCountryFilter : true;
            
            const hasPrice = this.getAllowChanges ? 
                (row.freightPrice !== null && row.freightPrice !== '' && row.freightPrice !== undefined && !isNaN(row.freightPrice)) : 
                true;
            
            let matchSearch = true;
            if (this.isSearchActive) {
                const searchLower = this.searchTerm.toLowerCase();
                matchSearch = (
                    row.laneName?.toLowerCase().includes(searchLower) ||
                    row.loadingPostalCode?.toLowerCase().includes(searchLower) ||
                    row.loadingCountryCode?.toLowerCase().includes(searchLower) ||
                    row.deliveryPostalCode?.toLowerCase().includes(searchLower) ||
                    row.destinationLocationCode?.toLowerCase().includes(searchLower) ||
                    row.typeOfTrailer?.toLowerCase().includes(searchLower)
                );
            }
            
            return matchLoading && matchDelivery && hasPrice && matchSearch;
        });
        
        if (this.activeTab === 'existing') {
            // Sort existing prices
            if (this.sortedBy && this.sortedBy !== 'mandatory') {
                const sortField = this.sortedBy;
                const sortDir = this.sortDirection;
                
                filteredData.sort((a, b) => {
                    let aVal = a[sortField];
                    let bVal = b[sortField];
                    const result = this.sortValue(aVal, bVal);
                    return sortDir === 'asc' ? result : -result;
                });
            }
            
            this.filteredExistingLanePrices = filteredData;
            const startIndex = (this.currentPage - 1) * this.recordsPerPage;
            const endIndex = startIndex + this.recordsPerPage;
            this.existingLanePrices = filteredData.slice(startIndex, endIndex);
            this.lanePrices = this.existingLanePrices;
        } else {
            // ... existing logic for mandatory/optional tabs ...
            const mandatoryRecords = filteredData.filter(record => record.mandatory === true);
            const nonMandatoryRecords = filteredData.filter(record => record.mandatory !== true);
            
            if (this.sortedBy && this.sortedBy !== 'mandatory') {
                const sortField = this.sortedBy;
                const sortDir = this.sortDirection;
                
                mandatoryRecords.sort((a, b) => {
                    let aVal = a[sortField];
                    let bVal = b[sortField];
                    const result = this.sortValue(aVal, bVal);
                    return sortDir === 'asc' ? result : -result;
                });
                
                nonMandatoryRecords.sort((a, b) => {
                    let aVal = a[sortField];
                    let bVal = b[sortField];
                    const result = this.sortValue(aVal, bVal);
                    return sortDir === 'asc' ? result : -result;
                });
            }
            
            this.filteredLanePrices = [...mandatoryRecords, ...nonMandatoryRecords];
            this.numOfMandatoryLanes = mandatoryRecords.length;

            if (this.activeTab === 'mandatory') {
                const startIndex = (this.currentPage - 1) * this.recordsPerPage;
                const endIndex = startIndex + this.recordsPerPage;
                this.lanePrices = mandatoryRecords.slice(startIndex, endIndex);
            } else if (this.activeTab === 'optional') {
                const startIndex = (this.currentPage - 1) * this.recordsPerPage;
                const endIndex = startIndex + this.recordsPerPage;
                this.lanePrices = nonMandatoryRecords.slice(startIndex, endIndex);
            } else {
                this.lanePrices = [];
            }
        }
    }

    sortValue(a, b) {
        if (!isNaN(a) && !isNaN(b)) {
            return a - b;
        }
        
        if (typeof a === 'string' && typeof b === 'string') {
            return a.localeCompare(b);
        }
        
        return a > b ? 1 : -1;
    }

    // AUTHENTICATION HANDLERS
    handleCodeChange(event) {
        this.codeFromUser = event.target.value;
    }

    handleCodeSubmit() {
        getAccessCodeFromAccount({ priceRequestId: this.priceRequestId })
            .then(data => {
                this.secretCode = data;
                
                if (this.codeFromUser === this.secretCode) {
                    this.isLoadingPage = false;
                    this.isWorkPage = true;
                    this.secretCodeIsNotValid = false;
                    sessionStorage.setItem('bypassCode', 'true');
                    this.codeFromUser = '';
                } else {
                    this.secretCodeIsNotValid = true;
                }
            })
            .catch(error => {
                console.error('Error getting access code:', error);
                this.secretCodeIsNotValid = true;
            });
    }

    // TAB NAVIGATION HANDLERS
    handleShowMandatoryLanes() {
        this.activeTab = 'mandatory';
        this.currentPage = 1;
        this.resetFilters();
        this.initFilterOptionsForActiveTab(); 
        this.applyFiltersAndPagination();
    }

    handleShowOtherLanes() {
        this.activeTab = 'optional';
        this.currentPage = 1;
        this.resetFilters();
        this.initFilterOptionsForActiveTab(); 
        this.applyFiltersAndPagination();
    }

    handleShowExistingPrices() {
        this.activeTab = 'existing';
        this.currentPage = 1;
        this.resetFilters();
        this.initFilterOptionsForActiveTab();
        this.applyFiltersAndPagination();
    }

    // FILTER HANDLERS
    handleLoadingCountryChange(event) {
        this.loadingCountryFilter = event.detail.value;
        this.currentPage = 1;
        this.applyFiltersAndPagination();
    }

    handleDeliveryCountryChange(event) {
        this.deliveryCountryFilter = event.detail.value;
        this.currentPage = 1;
        this.applyFiltersAndPagination();
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        this.isSearchActive = this.searchTerm && this.searchTerm.trim() !== '';
        this.currentPage = 1;
        this.applyFiltersAndPagination();
    }

    // PAGINATION HANDLERS
    handlePageChange(event) {
        const { page } = event.detail;
        if (page && page !== this.currentPage) {
            this.currentPage = page;
            this.applyFiltersAndPagination();
        }
    }

    // SORTING HANDLERS
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        
        if (sortedBy === 'mandatory') {
            return;
        }
        
        this.sortedBy = sortedBy;
        this.sortDirection = sortDirection;
        
        this.applyFiltersAndPagination();
    }

    // DATA CHANGE HANDLERS
    handleLanePriceCellChange(event) {
        if (this.activeTab === 'existing') {
            const newDrafts = [...this.existingLanePricesDraftValues];
            
            event.detail.draftValues.forEach(change => {
                const existingIndex = newDrafts.findIndex(draft => draft.id === change.id);
                
                // Find the original lane price to get the originalId
                const lanePriceRecord = this.allExistingLanePrices.find(lp => lp.id === change.id);
                
                const draftWithOriginalId = {
                    ...change,
                    originalId: lanePriceRecord ? lanePriceRecord.originalId : null
                };
                
                if (existingIndex !== -1) {
                    newDrafts[existingIndex] = { ...newDrafts[existingIndex], ...draftWithOriginalId };
                } else {
                    newDrafts.push(draftWithOriginalId);
                }
            });
            
            this.existingLanePricesDraftValues = newDrafts;
            
            // Update display
            this.allExistingLanePrices = this.allExistingLanePrices.map(lane => {
                const draft = newDrafts.find(d => d.id === lane.id);
                return draft ? { ...lane, ...draft } : lane;
            });
            this.applyFiltersAndPagination();
        } else {
            const newDrafts = [...this.draftValues];
            
            event.detail.draftValues.forEach(change => {
                const existingIndex = newDrafts.findIndex(draft => draft.id === change.id);
                
                if (existingIndex !== -1) {
                    newDrafts[existingIndex] = { ...newDrafts[existingIndex], ...change };
                } else {
                    newDrafts.push(change);
                }
            });
            
            this.draftValues = newDrafts;
        }
    }

    handleAdditionalChargesFieldChange(event) {
        const { fieldName, fieldValue } = event.detail;
        
        if (!this.accountDraftValues.length && this.accountId) {
            const accountCopy = this.account ? {...this.account} : {};
            this.accountDraftValues = [{ 
                Id: this.accountId,
                Dangerous_Goods__c: accountCopy.Dangerous_Goods__c || false,
                Pallet_Exchange__c: accountCopy.Pallet_Exchange__c || false,
                Tail_Lift__c: accountCopy.Tail_Lift__c || false,
                Pallet_Jack__c: accountCopy.Pallet_Jack__c || false,
                ETS__c: accountCopy.ETS__c,
                Fuel_surcharge_percentage__c: accountCopy.Fuel_surcharge_percentage__c,
                Price_Per_Stop__c: accountCopy.Price_Per_Stop__c,
                Price_2nd_Driver__c: accountCopy.Price_2nd_Driver__c,
                Price_Ferry__c: accountCopy.Price_Ferry__c,
                Overnight_charges_Price__c: accountCopy.Overnight_charges_Price__c,
                Plug_in__c: accountCopy.Plug_in__c,
                Waiting_Hour__c: accountCopy.Waiting_Hour__c,
                Harbour_Dues__c: accountCopy.Harbour_Dues__c,
                Seasonal_Surcharge__c: accountCopy.Seasonal_Surcharge__c,
                Weekend_Charges__c: accountCopy.Weekend_Charges__c,
                Dangerous_Goods_Price__c: accountCopy.Dangerous_Goods_Price__c,
                Pallet_Exchange_Price__c: accountCopy.Pallet_Exchange_Price__c,
                Tail_Lift_Price__c: accountCopy.Tail_Lift_Price__c,
                Pallet_Jack_Price__c: accountCopy.Pallet_Jack_Price__c
            }];
        }
        
        if (this.accountDraftValues.length > 0) {
            this.accountDraftValues[0][fieldName] = fieldValue;
        }
        
        this.account = { ...this.account, [fieldName]: fieldValue };
    }

    // SAVE & SUBMIT HANDLERS
    handleSaveTemporary() {
        if (this.draftValues.length === 0 && 
            this.existingLanePricesDraftValues.length === 0 && 
            this.accountDraftValues.length === 0) {
            this.showCustomNotification(
                'No Changes',
                'There are no changes to save temporarily.',
                'info'
            );
            return;
        }

        const success = this.saveTemporaryData();
        
        if (success) {
            this.showCustomNotification(
                'Success',
                'Your data has been saved temporarily. You can return later to continue editing.',
                'success'
            );
        } else {
            this.showCustomNotification(
                'Error',
                'Failed to save temporary data. Please try again.',
                'error'
            );
        }
    }

    handleSubmit() {
        this.isLoading = true;
        this.hideNotification();

        // Validate mandatory lanes from current price request only
        const finalLaneData = this.allLanePrices.map(row => {
            const draft = this.draftValues.find(d => d.id === row.id);
            return draft ? { ...row, ...draft } : row;
        });

        const invalidMandatoryLanes = finalLaneData.filter(row => {
            if (!row.mandatory) return false;
            
            const missingFreightPrice = row.freightPrice === null || row.freightPrice === '' || 
                                        row.freightPrice === undefined || isNaN(row.freightPrice);
            return missingFreightPrice;
        });

        if (invalidMandatoryLanes.length > 0) {
            this.showCustomNotification(
                'Validation Error',
                'All mandatory lanes must have a Freight Price. Please fill in the missing values.',
                'error'
            );
            this.isLoading = false;
            return;
        }

        const additionalChargesComponent = this.template.querySelector('c-additional-charges');
        const accountValidationErrors = additionalChargesComponent ? 
            additionalChargesComponent.validate() : [];
        
        if (accountValidationErrors.length > 0) {
            this.showCustomNotification(
                'Validation Error',
                accountValidationErrors.join(' '),
                'error'
            );
            this.isLoading = false;
            return;
        }
        
        const promises = [];
        
        // Update account
        if (this.accountDraftValues && this.accountDraftValues.length > 0) {
            const accountToUpdate = this.accountDraftValues[0];
            promises.push(updateAccountByLanePrice({ 
                jsonAccount: JSON.stringify(accountToUpdate), 
                priceRequestId: this.priceRequestId, 
                isFinalSubmit: true 
            }));
        }

        // Update current price request lane prices
        if (this.draftValues && this.draftValues.length > 0) { 
            promises.push(updateFreightPrices({ 
                jsonData: JSON.stringify(this.draftValues), 
                priceRequestId: this.priceRequestId, 
                isFinalSubmit: true 
            }));
        }

        // Update existing lane prices (from previous price requests)
        if (this.existingLanePricesDraftValues && this.existingLanePricesDraftValues.length > 0) {
            promises.push(updateExistingLanePrices({
                jsonData: JSON.stringify(this.existingLanePricesDraftValues),
                priceRequestId: this.priceRequestId,
                isFinalSubmit: true
            }));
        }

        if (promises.length === 0) {
            this.showCustomNotification(
                'No Changes',
                'There are no changes to submit.',
                'info'
            );
            this.isLoading = false;
            return;
        }
        
        Promise.all(promises)
            .then(() => {
                this.clearTemporaryData();
                
                this.showCustomNotification(
                    'Success',
                    'Your price submission was successful! The page will refresh in a few seconds.',
                    'success'
                );
                
                this.draftValues = [];
                this.existingLanePricesDraftValues = [];
                this.accountDraftValues = [];
                
                setTimeout(() => {
                    this.isWorkPage = false;
                    this.isSubmitPage = true;
                }, 3000);
            })
            .catch(error => {
                this.showCustomNotification(
                    'Error Submitting Data',
                    this.reduceErrors(error).join(', '),
                    'error'
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRequestChanges() {
        requestPermissionToChange({ priceRequestId: this.priceRequestId })
            .then(() => {
                this.allowChangesWasSend = true;
                this.showCustomNotification(
                    'Success',
                    'Your request to make changes has been sent.',
                    'success'
                );
            })
            .catch(error => {
                this.showCustomNotification(
                    'Error',
                    'Failed to send request. Please try again.',
                    'error'
                );
                console.error('Error requesting permission:', error);
            });
        
        setTimeout(() => {
            this.handleThankYouClick();
        }, 3000);
    }

    // NAVIGATION HANDLERS
    handleThankYouClick() {
        sessionStorage.removeItem('bypassCode');      
        this.clearTemporaryData();   
        this.isSubmitPage = false;
        this.isWorkPage = false;
        this.isLoadingPage = true;     
        this.codeFromUser = '';
        this.lanePrices = [];
        this.allLanePrices = [];
        this.existingLanePrices = [];
        this.allExistingLanePrices = [];
        this.account = null;
        this.priceRequest = null;
        this.draftValues = [];
        this.existingLanePricesDraftValues = []; // Add this
        this.accountDraftValues = [];    
        this.currentPage = 1;
        this.loadingCountryFilter = '';
        this.deliveryCountryFilter = '';

        window.location.reload();
    }

    // NOTIFICATION METHODS
    showCustomNotification(title, message, variant) {
        this.notificationTitle = title;
        this.notificationMessage = message;
        this.notificationVariant = variant;
        this.showNotification = true;
        
        setTimeout(() => {
            this.hideNotification();
        }, 5000);
    }

    hideNotification() {
        this.showNotification = false;
    }

    // UTILITY METHODS
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return errors.filter(error => !!error).map(error => {
            if (error.body) {
                if (Array.isArray(error.body)) {
                    return error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    return error.body.message;
                }
            }
            return error.message || 'An unknown error occurred.';
        });
    }
}