import { LightningElement, api } from 'lwc';

export default class PicklistColumn extends LightningElement {
    @api typeAttributes;
    @api value;

    handleChange(event) {
        // Create a simple event with only the necessary details
        this.dispatchEvent(new CustomEvent('change', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {
                value: event.detail.value,
                validity: { valid: true }
            }
        }));
    }

    @api
    validate() {
        return { valid: true };
    }

    @api
    get validity() {
        return { valid: true };
    }
}