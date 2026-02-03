import { LightningElement, api } from 'lwc';
import getLanePriceAndAccount from '@salesforce/apex/LaneCostCalculatorController.getLanePriceAndAccount';

export default class LanePriceCalculator extends LightningElement {
    @api lanePriceId;
    @api accountId;
    @api innerMargin = '0';
    @api AnnuallSalesPrice = 0;
    @api AnnualListPrice = 0;
    @api calculatedMargin = 0

    lanePrice;
    account;
    error;
    
    pricePerStop = 2;
    waitingHour = 0;
    overnightCharges = false;
    seasonalFee = false;
    palletExchange = 0;
    
    plugin = false;
    harbourDues = false;
    ets = false;
    weekendCharges = false;
    dangerousGoods = false;
    tailLift = false;
    palletJack = false;
    secondDriver = false;
    priceFerry = false;
    isThisFirstCalculation = true;
    
    calculatedTotalPrice = 0;
    calculatedSalesPrice = 0;
    showResults = true;

    get innerMarginDecimal() {
        const val = parseFloat(this.innerMargin);
        return isNaN(val) ? 0.0 : val;
    }

    get getSalesPrice() {
        return this.calculatedSalesPrice.toFixed(2);
    }

    get marginForThisLane() {
        return this.calculatedMargin.toFixed(2);
    }

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        try {
            const result = await getLanePriceAndAccount({
                lanePriceId: this.lanePriceId,
                accountId: this.accountId
            });
            // const result = await getLanePriceAndAccount({
            //     lanePriceId: 'a01KE000001zyEXYAY',
            //     accountId: '001KE000006nZE6YAM'
            // });
            this.lanePrice = result.lanePrice;
            this.account = result.account;
            this.AnnualListPrice = parseFloat(this.lanePrice?.Freight_Price__c) || 0;
            this.handleCalculate();
        } catch (err) {
            this.error = err.body ? err.body.message : err.message;
        }
    }

    handleCalculate() {
        if (!this.lanePrice || !this.account) {
            this.error = 'Missing lane price or account data';
            return;
        }

        this.error = null;
        
        // Base freight price
        const freightPrice = parseFloat(this.lanePrice?.Freight_Price__c) || 0;
        
        // Calculate additional costs that multiply by count
        const pricePerStopCost = this.getPricePerStopCost();
        const waitingHourCost = this.getWaitingHourCost();
        const overnightChargesCost = this.getOvernightChargesCost();
        
        // Calculate percentage-based surcharges on freight price
        const fuelSurcharge = this.getFuelSurcharge(freightPrice);
        const seasonalSurcharge = this.getSeasonalSurcharge(freightPrice);

        // Calculate checkbox-based additions
        const pluginCost = this.getPluginCost();
        const harbourDuesCost = this.getHarbourDuesCost();
        const etsCost = this.getETSCost();
        const weekendChargesCost = this.getWeekendChargesCost();
        const dangerousGoodsCost = this.getDangerousGoodsCost();
        const palletExchangeCost = this.getPalletExchangeCost();
        const tailLiftCost = this.getTailLiftCost();
        const palletJackCost = this.getPalletJackCost();
        const secondDriverCost = this.getSecondDriverCost();
        const priceFerryCost = this.getPriceFerryCost();
        
        if(this.isThisFirstCalculation) {
            this.calculatedTotalPrice = freightPrice 
                + pricePerStopCost
                + fuelSurcharge;
            
            this.isThisFirstCalculation = false;
        }
        else {
            this.calculatedTotalPrice = freightPrice 
                + pricePerStopCost
                + waitingHourCost 
                + overnightChargesCost
                + fuelSurcharge 
                + seasonalSurcharge 
                + pluginCost 
                + harbourDuesCost 
                + etsCost 
                + weekendChargesCost
                + dangerousGoodsCost
                + palletExchangeCost
                + tailLiftCost
                + palletJackCost
                + secondDriverCost
                + priceFerryCost;
        }
        this.calculatedSalesPrice = this.calculatedTotalPrice;

        this.calculatedMargin = (this.calculatedTotalPrice * this.innerMarginDecimal) / 100;

        this.AnnuallSalesPrice = this.calculatedSalesPrice;
        
        // Show results
        this.showResults = true;
    }

    // Helper methods for calculations
    getPricePerStopCost() {
        const pricePerStopValue = parseFloat(this.account?.Price_Per_Stop__c) || 0;
        const count = parseFloat(this.pricePerStop) || 0;
        return pricePerStopValue && count ? pricePerStopValue * count : 0;
    }

    getWaitingHourCost() {
        const waitingHourValue = parseFloat(this.account?.Waiting_Hour__c) || 0;
        const count = parseFloat(this.waitingHour) || 0;
        return waitingHourValue && count ? waitingHourValue * count : 0;
    }

    getOvernightChargesCost() {
        const overnightValue = parseFloat(this.account?.Overnight_charges_Price__c) || 0;
        return this.overnightCharges && overnightValue ? overnightValue : 0;
    }

    getFuelSurcharge(freightPrice) {
        const fuelSurchargePercent = parseFloat(this.account?.Fuel_surcharge_percentage__c) || 0;
        return freightPrice && fuelSurchargePercent  ? (freightPrice * fuelSurchargePercent) / 100 : 0;
    }

    getSeasonalSurcharge(freightPrice) {
        const seasonalPercent = parseFloat(this.account?.Seasonal_Surcharge__c) || 0;
        return freightPrice && seasonalPercent && this.seasonalFee ? (freightPrice * seasonalPercent) / 100 : 0;
    }

    getPluginCost() {
        const pluginValue = parseFloat(this.account?.Plug_in__c) || 0;
        return this.plugin && pluginValue ? pluginValue : 0;
    }

    getHarbourDuesCost() {
        const harbourValue = parseFloat(this.account?.Harbour_Dues__c) || 0;
        return this.harbourDues && harbourValue ? harbourValue : 0;
    }

    getETSCost() {
        const etsValue = parseFloat(this.account?.ETS__c) || 0;
        return this.ets && etsValue ? etsValue : 0;
    }

    getWeekendChargesCost() {
        const weekendValue = parseFloat(this.account?.Weekend_Charges__c) || 0;
        return this.weekendCharges && weekendValue ? weekendValue : 0;
    }
    getDangerousGoodsCost() {
        const dangerousGoodsValue = parseFloat(this.account?.Dangerous_Goods_Price__c) || 0;
        return this.dangerousGoods && dangerousGoodsValue ? dangerousGoodsValue : 0;
    }
    getPalletExchangeCost() {
        const palletExchangeValue = parseFloat(this.account?.Pallet_Exchange_Price__c) || 0;
        const count = parseFloat(this.palletExchange) || 0;
        return palletExchangeValue && count ? palletExchangeValue * count : 0;
    }
    getTailLiftCost() {
        const tailLiftValue = parseFloat(this.account?.Tail_Lift_Price__c) || 0;
        return this.tailLift && tailLiftValue ? tailLiftValue : 0;
    }
    getPalletJackCost() {
        const palletJackValue = parseFloat(this.account?.Pallet_Jack_Price__c) || 0;
        return this.palletJack && palletJackValue ? palletJackValue : 0;
    }
    getSecondDriverCost() {
        const secondDriverValue = parseFloat(this.account?.Price_2nd_Driver__c) || 0;
        return this.secondDriver && secondDriverValue ? secondDriverValue : 0;
    }
    getPriceFerryCost() {
        const priceFerryValue = parseFloat(this.account?.Price_Ferry__c) || 0;
        return this.priceFerry && priceFerryValue ? priceFerryValue : 0;
    }

    handlePricePerStopChange(event) {
        this.pricePerStop = event.target.value;
        this.handleCalculate();
    }
    handleWaitingHourChange(event) {
        this.waitingHour = event.target.value;
        this.handleCalculate();
    }

    handleSeasonalFeeChange(event) {
        this.seasonalFee = event.target.checked;
        this.handleCalculate();
    }

    handleOvernightChargesChange(event) {
        this.overnightCharges = event.target.checked;
        this.handleCalculate();
    }
    handlePluginChange(event) {
        this.plugin = event.target.checked;
        this.handleCalculate();
    }
    handleHarbourDuesChange(event) {
        this.harbourDues = event.target.checked;
        this.handleCalculate();
    }
    handleETSChange(event) {
        this.ets = event.target.checked;
        this.handleCalculate();
    }
    handleWeekendChargesChange(event) {
        this.weekendCharges = event.target.checked;
        this.handleCalculate();
    }
    handleDangerousGoodsChange(event) {
        this.dangerousGoods = event.target.checked;
        this.handleCalculate();
    }
    handlePalletExchangeChange(event) {
        this.palletExchange = event.target.value;
        this.handleCalculate();
    }
    handleTailLiftChange(event) {
        this.tailLift = event.target.checked;  
        this.handleCalculate();
    }
    handlePalletJackChange(event) {
        this.palletJack = event.target.checked;
        this.handleCalculate();
    }
    handleSecondDriverChange(event) {
        this.secondDriver = event.target.checked;
        this.handleCalculate();
    }
    handlePriceFerryChange(event) {
        this.priceFerry = event.target.checked;
        this.handleCalculate();
    }
}