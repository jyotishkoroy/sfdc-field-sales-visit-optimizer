import { LightningElement, track } from 'lwc';
import generateApex from '@salesforce/apex/RoutePlanner.generate';
import getStops from '@salesforce/apex/RoutePlanner.getStops';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RoutePlanner extends LightningElement {
    planDate = new Date().toISOString().slice(0, 10);

    @track summary;
    @track stops = [];
    error;
    isLoading = false;

    columns = [
        { label: '#', fieldName: 'Sequence__c', type: 'number' },
        { label: 'Visit', fieldName: 'VisitName' },
        { label: 'Leg km', fieldName: 'LegDistanceKm__c', type: 'number' },
        { label: 'Leg min', fieldName: 'LegDurationMin__c', type: 'number' }
    ];

    handleDate(e) {
        this.planDate = e.target.value;
    }

    async generate() {
        this.isLoading = true;
        this.error = undefined;
        this.summary = undefined;
        this.stops = [];

        try {
            const res = await generateApex({ req: { planDate: this.planDate } });
            this.summary = res;
            this.toast('Route generated', `Stops: ${res.stopCount}, Total: ${res.totalDistanceKm} km`, 'success');

            const rows = await getStops({ routePlanId: res.routePlanId });
            this.stops = (rows || []).map((s) => ({ ...s, VisitName: s.Visit__r?.Name || '—' }));
        } catch (e) {
            this.error = this.normalizeError(e);
            this.toast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    normalizeError(e) {
        if (!e) return 'Unknown error';
        if (typeof e === 'string') return e;
        if (e.body) {
            if (Array.isArray(e.body)) return e.body.map((x) => x.message).join(', ');
            return e.body.message || JSON.stringify(e.body);
        }
        return e.message || JSON.stringify(e);
    }
}
