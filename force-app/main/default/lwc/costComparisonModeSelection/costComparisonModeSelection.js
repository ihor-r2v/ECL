import { LightningElement } from 'lwc';

export default class CostComparisonModeSelection extends LightningElement {
    handleComparePrices() {
        this.dispatchEvent(new CustomEvent('modeselected', {
            detail: { mode: 'compareprices' }
        }));
    }

    handleRequestSpotPrice() {
        this.dispatchEvent(new CustomEvent('modeselected', {
            detail: { mode: 'requestspotprice' }
        }));
    }
}