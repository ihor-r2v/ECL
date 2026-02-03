import { LightningElement, api } from 'lwc';

export default class AdditionalCharges extends LightningElement {
    @api accountData;
    @api readOnly;
    
    // Visibility flags
    @api showFuelSurchargePercentage;
    @api showAdditionalStops;
    @api showSeasonalSurcharge;
    @api showHarbourDues;
    @api showETS;
    @api showDangerousGoods;
    @api showTailLift;
    @api showPalletJack;
    @api showPalletExchange;
    @api showWaitingHour;
    @api showWeekendCharges;
    @api showPlugIn;
    @api showOvernightCharges;
    @api showTwoDrivers;
    @api showDirectFerry;
    
    patternText = 'Please enter a valid number with dot (.) as decimal separator';

    handleFieldChange(event) {
        const fieldName = event.target.name;
        let fieldValue;
        
        if (event.target.type === 'checkbox' || event.target.type === 'checkbox-button') {
            fieldValue = event.target.checked;
        } else if (event.target.type === 'number') {
            fieldValue = event.target.value === '' ? '' : parseFloat(event.target.value);
        } else {
            fieldValue = event.target.value;
        }
        
        // Dispatch event to parent with field change details
        this.dispatchEvent(new CustomEvent('fieldchange', {
            detail: {
                fieldName: fieldName,
                fieldValue: fieldValue
            }
        }));
    }

    // Public method for validation that parent can call
    @api
    validate() {
        const errors = [];
        
        if (!this.accountData) {
            return errors;
        }

        const isEmpty = (value) => {
            return value === null || value === undefined || value === '' || 
                   (typeof value === 'string' && value.trim() === '');
        };

        if (this.showFuelSurchargePercentage && isEmpty(this.accountData.Fuel_surcharge_percentage__c)) {
            errors.push('Fuel surcharge percentage is required.');
        }
        if (this.showAdditionalStops && isEmpty(this.accountData.Price_Per_Stop__c)) {
            errors.push('Price per stop is required.');
        }
        if (this.showTwoDrivers && isEmpty(this.accountData.Price_2nd_Driver__c)) {
            errors.push('Two drivers price is required.');
        }
        if (this.showDirectFerry && isEmpty(this.accountData.Price_Ferry__c)) {
            errors.push('Direct ferry price is required.');
        }
        if (this.showOvernightCharges && isEmpty(this.accountData.Overnight_charges_Price__c)) {
            errors.push('Overnight charges price is required.');
        }
        if (this.showPlugIn && isEmpty(this.accountData.Plug_in__c)) {
            errors.push('Plug-in price is required.');
        }
        if (this.showWaitingHour && isEmpty(this.accountData.Waiting_Hour__c)) {
            errors.push('Waiting hour price is required.');
        }
        if (this.showHarbourDues && isEmpty(this.accountData.Harbour_Dues__c)) {
            errors.push('Harbour dues price is required.');
        }
        if (this.showETS && isEmpty(this.accountData.ETS__c)) {
            errors.push('ETS price is required.');
        }
        if (this.showSeasonalSurcharge && isEmpty(this.accountData.Seasonal_Surcharge__c)) {
            errors.push('Seasonal surcharge is required.');
        }
        if (this.showWeekendCharges && isEmpty(this.accountData.Weekend_Charges__c)) {
            errors.push('Weekend charges price is required.');
        }
        if (this.showDangerousGoods && isEmpty(this.accountData.Dangerous_Goods_Price__c)) {
            errors.push('Dangerous goods price is required.');
        }
        if (this.showPalletExchange && isEmpty(this.accountData.Pallet_Exchange_Price__c)) {
            errors.push('Pallet exchange price is required.');
        }
        if (this.showTailLift && isEmpty(this.accountData.Tail_Lift_Price__c)) {
            errors.push('Tail lift price is required.');
        }
        if (this.showPalletJack && isEmpty(this.accountData.Pallet_Jack_Price__c)) {
            errors.push('Pallet jack price is required.');
        }

        return errors;
    }
}