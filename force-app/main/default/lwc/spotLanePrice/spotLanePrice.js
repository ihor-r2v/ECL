import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPreferredSupplier from '@salesforce/apex/LaneSelectorController.createPreferredSupplier';

export default class SpotLanePrice extends NavigationMixin(LightningElement) {
    @api laneSelectorInfo;

    // Field configurations
    DIRECT_FIELDS = [
        'overnightPrice', 'harbourDues', 'palletJack',
        'plugIn', 'weekendCharges', 'dangerousGoods',
        'tailLift', 'ets', 'priceFerry', 'price2ndDriver',
        'seasonalSurcharge'
    ];

    PERCENTAGE_FIELDS = ['fuelSurchargePercentage'];
    
    QUANTITY_FIELDS = {
        waitingHour: 'waitingHourQuantity',
        palletExchange: 'palletExchangeQuantity',
        priceAdditionalStops: 'additionalStopsQuantity'
    };

    get accounts() {
        if (!this.laneSelectorInfo || !Array.isArray(this.laneSelectorInfo)) {
            return [];
        }
        
        return this.laneSelectorInfo.map(account => ({
            ...account,

            formattedLanePrice: Number(parseFloat(account.lanePrice) || 0).toFixed(2),
            formattedTotalPrice: Number(parseFloat(account.totalPrice) || 0).toFixed(2),

            waitingHourDisabled: !account.waitingHourIncluded,
            palletExchangeDisabled: !account.palletExchangeIncluded,
            additionalStopsDisabled: !account.priceAdditionalStopsIncluded,
            buttonClass: account.selectedAccount ? 'select-button-picked' : 'select-button',
            buttonLabel: account.selectedAccount ? 'Preferred Supplier' : 'Select',
            preferredCarrierLabel: account.preferredCarrier ? ' ✓ Preferred' : '',
            accountScores: {
                availabilityScore: account.accountScores?.availabilityScore || 0,
                priceScore: account.accountScores?.priceScore || 0,
                reliabilityScore: account.accountScores?.reliabilityScore || 0
            },
            priceVariables: this.buildPriceVariables(account)
        }));
    }

    get isSendDisabled() {
        return !this.laneSelectorInfo?.some(account => account.selectedAccount);
    }

    buildPriceVariables(account) {
        const variables = [];
        
        // Fuel Surcharge
        if (account.fuelSurchargePercentage) {
            variables.push({
                field: 'fuelSurchargePercentage',
                label: 'Fuel Surcharge',
                value: account.fuelSurchargePercentage,
                displayValue: `${account.fuelSurchargePercentage} %`,
                included: account.fuelSurchargePercentageIncluded,
                hasQuantity: false
            });
        }

        // Additional Stops
        if (account.priceAdditionalStops) {
            variables.push({
                field: 'priceAdditionalStops',
                label: 'Additional Stops',
                value: account.priceAdditionalStops,
                displayValue: `€ ${account.priceAdditionalStops}`,
                included: account.priceAdditionalStopsIncluded,
                hasQuantity: true,
                quantityField: 'additionalStopsQuantity',
                quantity: account.additionalStopsQuantity,
                disabled: account.additionalStopsDisabled
            });
        }

        // Seasonal Surcharge
        if (account.seasonalSurcharge) {
            variables.push({
                field: 'seasonalSurcharge',
                label: 'Seasonal Surcharge',
                value: account.seasonalSurcharge,
                displayValue: `€ ${account.seasonalSurcharge}`,
                included: account.seasonalSurchargeIncluded,
                hasQuantity: false
            });
        }

        // Add all other fields
        const fieldMap = {
            overnightPrice: 'Overnight Price',
            harbourDues: 'Harbour dues',
            waitingHour: 'Waiting Hour',
            palletJack: 'Pallet Jack',
            plugIn: 'Plug In',
            weekendCharges: 'Weekend Charges',
            dangerousGoods: 'Dangerous Goods',
            palletExchange: 'Pallet Exchange',
            tailLift: 'Tail Lift',
            ets: 'ETS',
            priceFerry: 'Price Ferry',
            price2ndDriver: '2nd Driver'
        };

        Object.entries(fieldMap).forEach(([field, label]) => {
            if (account[field]) {
                const quantityField = this.QUANTITY_FIELDS[field];
                variables.push({
                    field,
                    label,
                    value: account[field],
                    displayValue: `€ ${account[field]}`,
                    included: account[`${field}Included`],
                    hasQuantity: !!quantityField,
                    quantityField,
                    quantity: quantityField ? account[quantityField] : null,
                    disabled: quantityField ? account[`${field.replace(/([A-Z])/g, '_$1').toLowerCase()}Disabled`] : false
                });
            }
        });

        return variables;
    }

    connectedCallback() {
        if (this.laneSelectorInfo) {
            this.laneSelectorInfo = this.laneSelectorInfo.map(account => ({
                ...account,
                ...this.initializeDefaults(account)
            }));
            this.recalculateAllTotalPrices();
        }
    }

    initializeDefaults(account) {
        return {
            fuelSurchargePercentageIncluded: account.fuelSurchargePercentageIncluded ?? false,
            priceAdditionalStopsIncluded: account.priceAdditionalStopsIncluded ?? false,
            waitingHourQuantity: account.waitingHourQuantity || 1,
            palletExchangeQuantity: account.palletExchangeQuantity || 1,
            additionalStopsQuantity: account.additionalStopsQuantity || 2,
            cardClass: account.selectedAccount ? 'account-column-lane-price selected' : 'account-column-lane-price',
            seasonalSurchargeIncluded: account.seasonalSurchargeIncluded ?? false,
            overnightPriceIncluded: account.overnightPriceIncluded ?? false,
            harbourDuesIncluded: account.harbourDuesIncluded ?? false,
            waitingHourIncluded: account.waitingHourIncluded ?? false,
            palletJackIncluded: account.palletJackIncluded ?? false,
            plugInIncluded: account.plugInIncluded ?? false,
            weekendChargesIncluded: account.weekendChargesIncluded ?? false,
            dangerousGoodsIncluded: account.dangerousGoodsIncluded ?? false,
            palletExchangeIncluded: account.palletExchangeIncluded ?? false,
            tailLiftIncluded: account.tailLiftIncluded ?? false,
            etsIncluded: account.etsIncluded ?? false,
            priceFerryIncluded: account.priceFerryIncluded ?? false,
            price2ndDriverIncluded: account.price2ndDriverIncluded ?? false,
            expanded: account.expanded ?? false,
            chevronIcon: account.chevronIcon || 'utility:chevronright',
            fuelSurchargePercentage: account.fuelSurchargePercentage || 0,
            priceAdditionalStops: account.priceAdditionalStops || 0,
            seasonalSurcharge: account.seasonalSurcharge || 0,
            overnightPrice: account.overnightPrice || 0,
            harbourDues: account.harbourDues || 0,
            waitingHour: account.waitingHour || 0,
            palletJack: account.palletJack || 0,
            plugIn: account.plugIn || 0,
            weekendCharges: account.weekendCharges || 0,
            dangerousGoods: account.dangerousGoods || 0,
            palletExchange: account.palletExchange || 0,
            tailLift: account.tailLift || 0,
            ets: account.ets || 0,
            priceFerry: account.priceFerry || 0,
            price2ndDriver: account.price2ndDriver || 0
        };
    }

    recalculateAllTotalPrices() {
        if (!this.laneSelectorInfo) return;
        this.laneSelectorInfo = this.laneSelectorInfo.map(account => ({
            ...account,
            totalPrice: this.calculateTotalPrice(account)
        }));
    }

    calculateTotalPrice(account) {
        let totalPrice = parseFloat(account.lanePrice) || 0;

        // Percentage fields
        this.PERCENTAGE_FIELDS.forEach(field => {
            if (account[field] && account[`${field}Included`]) {
                totalPrice += (parseFloat(account.lanePrice) * parseFloat(account[field]) / 100);
            }
        });

        // Quantity fields
        Object.entries(this.QUANTITY_FIELDS).forEach(([field, quantityField]) => {
            if (account[`${field}Included`] && account[field]) {
                totalPrice += parseFloat(account[field]) * (account[quantityField] || 1);
            }
        });

        // Direct fields
        this.DIRECT_FIELDS.forEach(field => {
            if (account[`${field}Included`]) {
                totalPrice += parseFloat(account[field] || 0);
            }
        });

        return Number((Math.round(totalPrice * 100) / 100).toFixed(2));
    }

    handleSelect(event) {
        const accountId = event.target.dataset.id;
        const selectedAccount = this.laneSelectorInfo.find(acc => acc.accountId === accountId);
        
        if (!selectedAccount?.trailerType) {
            this.showToast('Invalid Selection', 'Account or trailer type not found', 'error');
            return;
        }

        // Update selection WITHOUT re-sorting (keep static order)
        this.laneSelectorInfo = this.laneSelectorInfo.map(account => {
            const isSelected = account.accountId === accountId;
            return {
                ...account,
                selectedAccount: isSelected,
                cardClass: isSelected ? 'account-column-lane-price selected' : 'account-column-lane-price'
            };
        });
        
        this.dispatchEvent(new CustomEvent('selected', { detail: this.laneSelectorInfo }));
    }

    handleTotalPriceClick(event) {
        const accountId = event.target.dataset.accountId;
        this.laneSelectorInfo = this.laneSelectorInfo.map(account => 
            account.accountId === accountId 
                ? { 
                    ...account, 
                    expanded: !account.expanded, 
                    chevronIcon: !account.expanded ? 'utility:chevrondown' : 'utility:chevronright' 
                }
                : account
        );
    }

    handlePrevious() {
        const sanitizedData = this.laneSelectorInfo.map(account => ({
            accountId: account.accountId,
            accountName: account.accountName,
            laneName: account.laneName,
            trailerType: account.trailerType,
            lanePrice: account.lanePrice,
            totalPrice: account.totalPrice,
            lanePriceId: account.lanePriceId,
            loadingLocationId: account.loadingLocationId,
            deliveryLocationId: account.deliveryLocationId,
            seasonId: account.seasonId,
            selectedAccount: account.selectedAccount,
            preferredCarrier: account.preferredCarrier,
            preferredCarrierLabel: account.preferredCarrierLabel,
            displayIndex: account.displayIndex,
            cardClass: account.cardClass,
            expanded: account.expanded,
            chevronIcon: account.chevronIcon,
            
            // Price variables
            fuelSurchargePercentage: account.fuelSurchargePercentage,
            fuelSurchargePercentageIncluded: account.fuelSurchargePercentageIncluded,
            priceAdditionalStops: account.priceAdditionalStops,
            priceAdditionalStopsIncluded: account.priceAdditionalStopsIncluded,
            additionalStopsQuantity: account.additionalStopsQuantity,
            additionalStopsDisabled: account.additionalStopsDisabled,
            
            seasonalSurcharge: account.seasonalSurcharge,
            seasonalSurchargeIncluded: account.seasonalSurchargeIncluded,
            overnightPrice: account.overnightPrice,
            overnightPriceIncluded: account.overnightPriceIncluded,
            harbourDues: account.harbourDues,
            harbourDuesIncluded: account.harbourDuesIncluded,
            waitingHour: account.waitingHour,
            waitingHourIncluded: account.waitingHourIncluded,
            waitingHourQuantity: account.waitingHourQuantity,
            palletJack: account.palletJack,
            palletJackIncluded: account.palletJackIncluded,
            plugIn: account.plugIn,
            plugInIncluded: account.plugInIncluded,
            weekendCharges: account.weekendCharges,
            weekendChargesIncluded: account.weekendChargesIncluded,
            dangerousGoods: account.dangerousGoods,
            dangerousGoodsIncluded: account.dangerousGoodsIncluded,
            palletExchange: account.palletExchange,
            palletExchangeIncluded: account.palletExchangeIncluded,
            palletExchangeQuantity: account.palletExchangeQuantity,
            tailLift: account.tailLift,
            tailLiftIncluded: account.tailLiftIncluded,
            ets: account.ets,
            etsIncluded: account.etsIncluded,
            priceFerry: account.priceFerry,
            priceFerryIncluded: account.priceFerryIncluded,
            price2ndDriver: account.price2ndDriver,
            price2ndDriverIncluded: account.price2ndDriverIncluded,
            
            accountScores: {
                availabilityScore: account.accountScores?.availabilityScore || 0,
                priceScore: account.accountScores?.priceScore || 0,
                reliabilityScore: account.accountScores?.reliabilityScore || 0
            }
        }));
        
        this.dispatchEvent(new CustomEvent('previous', { 
            detail: sanitizedData
        }));
    }

    handleCreatePreferredSupplier() {
        const hasSelectedAccount = this.laneSelectorInfo?.some(account => account.selectedAccount);
        if (!hasSelectedAccount) return;

        const preferredCarrier = this.laneSelectorInfo.find(account => account.selectedAccount);
        
        createPreferredSupplier({
            accountId: preferredCarrier.accountId,
            lanePriceId: preferredCarrier.lanePriceId,
            loadingLocationId: preferredCarrier.loadingLocationId,
            deliveryLocationId: preferredCarrier.deliveryLocationId,
            trailerType: preferredCarrier.trailerType,
            totalPrice: preferredCarrier.totalPrice,
            seasonId: preferredCarrier.seasonId,
            psConfigs: JSON.stringify(this.buildPsConfigs(preferredCarrier))
        })
        .then(() => {
            this.showToast('Success', `Preferred Supplier ${preferredCarrier.accountName} created successfully!`, 'success');
            this.dispatchEvent(new CustomEvent('success', { detail: 'success' }));
        })
        .catch(error => {
            this.showToast('Error creating Preferred Supplier', error.body?.message || error.message, 'error');
        });
    }

    buildPsConfigs(carrier) {
        const configs = {};
        [...this.PERCENTAGE_FIELDS, ...this.DIRECT_FIELDS, ...Object.keys(this.QUANTITY_FIELDS)].forEach(field => {
            configs[`${field}Included`] = carrier[`${field}Included`];
        });
        configs.priceAdditionalStopsIncluded = carrier.priceAdditionalStopsIncluded;
        configs.additionalStopsDisabled = carrier.additionalStopsDisabled;
        configs.waitingHourDisabled = carrier.waitingHourDisabled;
        configs.palletExchangeDisabled = carrier.palletExchangeDisabled;
        return configs;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleCheckboxChange(event) {
        this.updateAccount(event.target.dataset.accountId, account => {
            const includedFieldName = `${event.target.dataset.field}Included`;
            return { [includedFieldName]: event.target.checked };
        });
    }

    handleQuantityChange(event) {
        this.updateAccount(event.target.dataset.accountId, () => ({
            [event.target.dataset.field]: parseInt(event.target.value, 10) || 2
        }));
    }

    handleSelectAll(event) {
        this.updateAccount(event.currentTarget.dataset.accountId, () => {
            const isChecked = event.target.checked;
            return {
                fuelSurchargePercentageIncluded: isChecked,
                priceAdditionalStopsIncluded: isChecked,
                seasonalSurchargeIncluded: isChecked,
                overnightPriceIncluded: isChecked,
                waitingHourIncluded: isChecked,
                palletExchangeIncluded: isChecked,
                harbourDuesIncluded: isChecked,
                palletJackIncluded: isChecked,
                plugInIncluded: isChecked,
                weekendChargesIncluded: isChecked,
                dangerousGoodsIncluded: isChecked,
                tailLiftIncluded: isChecked,
                etsIncluded: isChecked,
                priceFerryIncluded: isChecked,
                price2ndDriverIncluded: isChecked,
                additionalStopsDisabled: !isChecked,
                waitingHourDisabled: !isChecked,
                palletExchangeDisabled: !isChecked
            };
        });
    }

    updateAccount(accountId, updateFn) {
        this.laneSelectorInfo = this.laneSelectorInfo.map(account => {
            if (account.accountId === accountId) {
                const updatedAccount = { ...account, ...updateFn(account) };
                updatedAccount.totalPrice = this.calculateTotalPrice(updatedAccount);
                return updatedAccount;
            }
            return account;
        });
        this.dispatchEvent(new CustomEvent('selected', { detail: this.laneSelectorInfo }));
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
}