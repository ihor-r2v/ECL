import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPreferredSupplier from '@salesforce/apex/LaneSelectorController.createPreferredSupplier';

export default class PreferredSupplier extends LightningElement {
    @api laneSelectorInfo;

    get accounts() {
        if (!this.laneSelectorInfo) { return []; }

        const reordered = [...this.laneSelectorInfo].sort((a, b) => {
            return (b.selectedAccount === true) - (a.selectedAccount === true);
        });
        this.laneSelectorInfo = [...this.laneSelectorInfo].sort((a, b) => {
            return (b.selectedAccount === true) - (a.selectedAccount === true);
        });

        return reordered.map((account, idx) => {
            return { 
                ...account, 
                index: idx,
                isFirst: idx === 0,
                laneHeaderLabel: idx === 0 ? 'Preferred lane price from:' : `${idx + 1} choice:`,
                laneResultLabel: idx === 0 ? 'Results:' : 'Review other comparison criteria:',
                priceSectionLabel: idx === 0 ? 'Price variables (part of total price):' : 'Other Price variables:' 
            };
        });
    }

    get isSubmitDisabled() {
        if (!this.laneSelectorInfo || this.laneSelectorInfo.length === 0) {
            return true;
        }
        
        const hasSelectedAccount = this.laneSelectorInfo.some(account => account.selectedAccount === true);
        return !hasSelectedAccount;
    }

    handleTotalPriceClick(event) {
        const accountId = event.target.dataset.accountId;

        this.laneSelectorInfo = this.laneSelectorInfo.map(account => {
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

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previous', {
            detail: 'preferredSupplier'
        }));
    }

    handleSubmit() {
        const hasSelectedAccount = this.laneSelectorInfo?.some(account => account.selectedAccount === true);
        
        if (!hasSelectedAccount) { return; }

        const firstAccount = this.laneSelectorInfo[0];
        
        const accountId = firstAccount.accountId;
        const lanePriceId = firstAccount.trailerTypes[0]?.laneId;
        const loadingLocationId = firstAccount.loadingLocationId;
        const deliveryLocationId = firstAccount.deliveryLocationId;
        const trailerType = firstAccount.trailerType;
        const totalPrice = firstAccount.totalPrice;
        const seasonId = firstAccount.seasonId;

        // sending these parameters to apex, for further use if necessary
        const psConfigs = JSON.stringify({
            fuelSurchargePercentageIncluded: firstAccount.fuelSurchargePercentageIncluded,
            seasonalSurchargeIncluded: firstAccount.seasonalSurchargeIncluded,
            overnightPriceIncluded: firstAccount.overnightPriceIncluded,
            harbourDuesIncluded: firstAccount.harbourDuesIncluded,
            waitingHourIncluded: firstAccount.waitingHourIncluded,
            palletJackIncluded: firstAccount.palletJackIncluded,
            plugInIncluded: firstAccount.plugInIncluded,
            weekendChargesIncluded: firstAccount.weekendChargesIncluded,
            dangerousGoodsIncluded: firstAccount.dangerousGoodsIncluded,
            palletExchangeIncluded: firstAccount.palletExchangeIncluded,
            tailLiftIncluded: firstAccount.tailLiftIncluded,
            etsIncluded: firstAccount.etsIncluded,
            priceFerryIncluded: firstAccount.priceFerryIncluded,
            price2ndDriverIncluded: firstAccount.price2ndDriverIncluded,
            priceAdditionalStopsIncluded: firstAccount.priceAdditionalStopsIncluded,
            additionalStopsDisabled: firstAccount.additionalStopsDisabled,
            waitingHourDisabled: firstAccount.waitingHourDisabled,
            palletExchangeDisabled: firstAccount.palletExchangeDisabled
        });
        
        createPreferredSupplier({
            accountId: accountId,
            lanePriceId: lanePriceId,
            loadingLocationId: loadingLocationId,
            deliveryLocationId: deliveryLocationId,
            trailerType: trailerType,
            totalPrice: totalPrice,
            seasonId: seasonId,
            psConfigs: psConfigs
        })
        .then(() => {
            this.showToast('Success', 'Preferred Supplier created successfully!', 'success');
            this.dispatchEvent(
                new CustomEvent('success', {
                    detail: 'success'
                })
            );
        })
        .catch(error => {
            const message = error.body ? error.body.message : error.message;
            this.showToast('Error creating Preferred Supplier', 'message', 'error');
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