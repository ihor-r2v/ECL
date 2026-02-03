import { LightningElement, api, wire, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getLinesByLocations from '@salesforce/apex/ProductLineController.getLinesByLocations';

export default class LocationLinesTabs extends LightningElement {
    @api loadingLocation;
    @api destinationLocation;
    @api deliveryDate;
    @api trailerType;
    @api seasonId;

    @api selectedLineId = '';

    @track filteredLanes = [];
    selectedFilters = new Set();

    @track error;
    @track sortedByReliability = [];
    @track sortedByAvailability = [];
    @track sortedByPriceLevel = [];
    @track datatableKey = 0;

    activeTab = 'tab1';
    selectedRow; 
    selectedRowId;

    get selectedRowIds() {
        return this.selectedLineId ? [this.selectedLineId] : [];
    }

    columns = [
        { label: 'Name', fieldName: 'productName', type: 'text' },
        { label: 'Carrier', fieldName: 'carrier', type: 'text' },
        { label: 'Trailer Type', fieldName: 'trailerType', type: 'text' },
        { label: 'Price €', fieldName: 'unitPrice', type: 'text' }
    ];

    reliabilityColumns = [
        { label: 'Name', fieldName: 'productName' },
        { label: 'Carrier', fieldName: 'carrier' },
        { label: 'Reliability Score', fieldName: 'reliabilityScore', type: 'text' }
    ];

    availabilityColumns = [
        { label: 'Name', fieldName: 'productName' },
        { label: 'Carrier', fieldName: 'carrier' },
        { label: 'Availability Score', fieldName: 'availabilityScore', type: 'text' }
    ];

    priceLevelColumns = [
        { label: 'Name', fieldName: 'productName' },
        { label: 'Carrier', fieldName: 'carrier' },
        { label: 'Price Level', fieldName: 'priceLevel', type: 'text' }
    ];

    @wire(getLinesByLocations, { 
        loadingLocationId: '$loadingLocation', 
        destinationLocationId: '$destinationLocation', 
        deliveryDate: '$deliveryDate',
        trailerType: '$trailerType',
        seasonId: '$seasonId'  
    })
    
    wiredLines({ error, data }) {
        if (data) {
            this.error = undefined;
            this.lanes = data;
            this.lanes = data.map(lp => ({
                Id: lp.Id,
                productName: lp.productName,
                carrier: lp.carrier,
                unitPrice: lp.unitPrice,
                dieselMarkup: lp.dieselMarkup,
                transitTime: lp.transitTime,
                trailerType: lp.trailerType,
                dangerousGoods: lp.dangerousGoods,   
                palletExchange: lp.palletExchange, 
                tailLift: lp.tailLift,               
                palletJack: lp.palletJack,

                carrierScores: lp.carrierScores || []
            }));

            this.filteredLanes = [...this.lanes];
            this.processScoreTables(this.filteredLanes);

        } else if (error) {
            this.error = error;
            this.lanes = [];
        }
    }

    processScoreTables(sourceLanes) {
        const aggregatedDataMap = new Map();

        sourceLanes.forEach(line => {
            if (!line.carrierScores || !Array.isArray(line.carrierScores)) {
                return;
            }

            const key = `${line.productName}__${line.carrier}`;

            if (!aggregatedDataMap.has(key)) {
                aggregatedDataMap.set(key, {
                    Id: line.Id + '-agg',
                    productName: line.productName,
                    carrier: line.carrier,
                    reliabilityTotal: 0,
                    reliabilityCount: 0,
                    availabilityTotal: 0,
                    availabilityCount: 0,
                    priceLevelTotal: 0,
                    priceLevelCount: 0
                });
            }

            const aggregatedData = aggregatedDataMap.get(key);

            line.carrierScores.forEach(score => {
                if (typeof score.availabilityScore === 'number') {
                    aggregatedData.availabilityTotal += score.availabilityScore;
                    aggregatedData.availabilityCount++;
                }
                if (typeof score.priceLevel === 'number') {
                    aggregatedData.priceLevelTotal += score.priceLevel;
                    aggregatedData.priceLevelCount++;
                }
                if (typeof score.reliabilityScore === 'number') {
                    aggregatedData.reliabilityTotal += score.reliabilityScore;
                    aggregatedData.reliabilityCount++;
                }
            });
        });

        const finalAggregatedList = Array.from(aggregatedDataMap.values()).map(item => {
            const finalItem = {
                Id: item.Id,
                productName: item.productName,
                carrier: item.carrier
            };
            if (item.reliabilityCount > 0) {
                finalItem.reliabilityScore = Math.round(item.reliabilityTotal / item.reliabilityCount);
            }
            if (item.availabilityCount > 0) {
                finalItem.availabilityScore = Math.round(item.availabilityTotal / item.availabilityCount);
            }
            if (item.priceLevelCount > 0) {
                finalItem.priceLevel = Math.round(item.priceLevelTotal / item.priceLevelCount);
            }
            return finalItem;
        });

        this.sortedByReliability = [...finalAggregatedList].sort((a, b) => (b.reliabilityScore || 0) - (a.reliabilityScore || 0));
        this.sortedByAvailability = [...finalAggregatedList].sort((a, b) => (b.availabilityScore || 0) - (a.availabilityScore || 0));
        this.sortedByPriceLevel = [...finalAggregatedList].sort((a, b) => (b.priceLevel || 0) - (a.priceLevel || 0));
    }

    get hasLanes() {
        return this.lanes && this.lanes.length > 0;
    }

    get hasSortedByReliability() {
        return this.sortedByReliability && this.sortedByReliability.length > 0;
    }

    get hasSortedByAvailability() {
        return this.sortedByAvailability && this.sortedByAvailability.length > 0;
    }

    get hasSortedByPriceLevel() {
        return this.sortedByPriceLevel && this.sortedByPriceLevel.length > 0;
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows || [];
        if (selectedRows.length > 0) {
            this.selectedRowId = selectedRows[0].Id;
            this.selectedLineId = this.selectedRowId;
            
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedLineId', this.selectedLineId));
        } else {
            this.selectedRowId = null;
            this.selectedLineId = '';
        }
    }
}