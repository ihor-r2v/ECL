import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CostComparison extends LightningElement {
    laneSelectorInfo;
    savedFilters = {};

    showModeSelection = true;
    showLaneSelector = false;
    showLanePrice = false;
    showRequestSpotPrice = false;

    selectedMode = '';

    handleModeSelected(event) {
        this.selectedMode = event.detail.mode;
        this.showModeSelection = false;

        if (this.selectedMode === 'compareprices') {
            this.showLaneSelector = true;
        } else if (this.selectedMode === 'requestspotprice') {
            this.showRequestSpotPrice = true;
        }
    }

    handlePreviousToMode() {
        this.showLaneSelector = false;
        this.showModeSelection = true;
        this.savedFilters = {};
        this.selectedMode = '';
    }

    handlePreviousFromSpotPrice() {
        this.showRequestSpotPrice = false;
        this.showModeSelection = true;
        this.savedFilters = {};
        this.selectedMode = '';
    }

    handleLaneSelectorUpdate(event) {
        const selectedLane = event.detail.find(lane => lane.selectedAccount === true);
        
        if (!selectedLane) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Selection Required',
                    message: 'Please select an account before proceeding',
                    variant: 'error',
                })
            );
            return;
        }

        if (event.detail.length > 0) {
            const firstLane = event.detail[0];
            this.savedFilters = {
                selectedSeason: firstLane.seasonId,
                selectedTrailerType: firstLane.trailerType,
                selectedLoadingLocation: firstLane.loadingLocationId,
                selectedDeliveryLocation: firstLane.deliveryLocationId
            };
        }

        const mappedLanes = event.detail.map(lane => {
            const lanePrice = parseFloat(lane.lanePrice) || 0;
            let totalPrice = lanePrice;

            if (lane.fuelSurchargePercentage && lane.fuelSurchargePercentageIncluded) {
                totalPrice += (lanePrice * parseFloat(lane.fuelSurchargePercentage) / 100);
            }
            
            if (lane.priceAdditionalStopsIncluded && lane.priceAdditionalStops) {
                totalPrice += (parseFloat(lane.priceAdditionalStops) * (lane.additionalStopsQuantity || 2));
            }

            totalPrice = Number((Math.round(totalPrice * 100) / 100).toFixed(2));

            return {
                ...lane,
                trailerType: lane.trailerType,
                lanePrice: Number(lanePrice.toFixed(2)),
                totalPrice: totalPrice,
                selectedAccount: lane.selectedAccount || false,
                fuelSurchargePercentageIncluded: lane.fuelSurchargePercentageIncluded || false,
                priceAdditionalStopsIncluded: lane.priceAdditionalStopsIncluded || false,
                seasonalSurchargeIncluded: lane.seasonalSurchargeIncluded || false,
                overnightPriceIncluded: lane.overnightPriceIncluded || false,
                harbourDuesIncluded: lane.harbourDuesIncluded || false,
                waitingHourIncluded: lane.waitingHourIncluded || false,
                palletJackIncluded: lane.palletJackIncluded || false,
                plugInIncluded: lane.plugInIncluded || false,
                weekendChargesIncluded: lane.weekendChargesIncluded || false,
                dangerousGoodsIncluded: lane.dangerousGoodsIncluded || false,
                palletExchangeIncluded: lane.palletExchangeIncluded || false,
                tailLiftIncluded: lane.tailLiftIncluded || false,
                etsIncluded: lane.etsIncluded || false,
                priceFerryIncluded: lane.priceFerryIncluded || false,
                price2ndDriverIncluded: lane.price2ndDriverIncluded || false,
                additionalStopsQuantity: lane.additionalStopsQuantity || 2,
                waitingHourQuantity: lane.waitingHourQuantity || 1,
                palletExchangeQuantity: lane.palletExchangeQuantity || 1,
                expanded: lane.expanded || false,
                chevronIcon: lane.chevronIcon || 'utility:chevronright'
            };
        });

        this.laneSelectorInfo = mappedLanes
            .sort((a, b) => {
                if (a.selectedAccount && !b.selectedAccount) return -1;
                if (!a.selectedAccount && b.selectedAccount) return 1;
                return 0;
            })
            .map((lane, index) => ({
                ...lane,
                displayIndex: index + 1
            }));

        this.showLaneSelector = false;
        this.showLanePrice = true;
    }

    handleSelectedAccount(event) {
        const updatedLanes = event.detail.map((lane, index) => ({
            ...lane,
            displayIndex: index + 1
        }));

        this.laneSelectorInfo = updatedLanes;
    }

    handlePreviousLanePrice(event) {
        this.laneSelectorInfo = event.detail;
        
        this.showLanePrice = false;
        this.showLaneSelector = true;
    }

    handleSuccess() {
        this.showModeSelection = true;
        this.showLaneSelector = false;
        this.showLanePrice = false;
        this.showRequestSpotPrice = false;
        this.laneSelectorInfo = null;
        this.savedFilters = {};
        this.selectedMode = '';
    }
}