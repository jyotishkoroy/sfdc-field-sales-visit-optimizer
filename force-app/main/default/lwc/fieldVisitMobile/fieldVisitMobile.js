import { LightningElement, track } from 'lwc';
import getTodayVisits from '@salesforce/apex/FieldVisitController.getTodayVisits';
import checkInApex from '@salesforce/apex/VisitCheckInService.checkIn';
import checkOutApex from '@salesforce/apex/VisitCheckInService.checkOut';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FieldVisitMobile extends LightningElement {
    @track visits = [];
    error;
    isLoading = false;

    // modal state
    reasonModalOpen = false;
    pendingAction; // 'IN' | 'OUT'
    pendingVisitId;
    pendingCoords;
    exceptionReason = '';

    get subtitle() {
        return 'Today • ' + new Date().toLocaleDateString();
    }

    connectedCallback() {
        this.load();
    }

    async load() {
        this.isLoading = true;
        this.error = undefined;
        try {
            const rows = await getTodayVisits();
            this.visits = (rows || []).map((v) => this.decorate(v));
        } catch (e) {
            this.error = this.normalizeError(e);
        } finally {
            this.isLoading = false;
        }
    }

    refresh = () => this.load();

    decorate(v) {
        const accountName = v.Account__r ? v.Account__r.Name : '—';
        const fmt = (dt) => (dt ? new Date(dt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—');
        return {
            ...v,
            AccountName: accountName,
            PlannedWindow: `${fmt(v.PlannedStart__c)}–${fmt(v.PlannedEnd__c)}`
        };
    }

    async checkIn(event) {
        const visitId = event.target.dataset.id;
        await this.performCheck('IN', visitId);
    }

    async checkOut(event) {
        const visitId = event.target.dataset.id;
        await this.performCheck('OUT', visitId);
    }

    async performCheck(kind, visitId, reasonOverride) {
        this.isLoading = true;
        this.error = undefined;

        try {
            const coords = await this.getLocation();
            const req = {
                visitId,
                lat: coords.lat,
                lng: coords.lng,
                gpsStatus: 'OK',
                exceptionReason: reasonOverride
            };

            const res = kind === 'IN' ? await checkInApex({ req }) : await checkOutApex({ req });

            if (res && res.success === false && (res.message || '').includes('Reason required')) {
                // open modal
                this.pendingAction = kind;
                this.pendingVisitId = visitId;
                this.pendingCoords = coords;
                this.reasonModalOpen = true;
                this.exceptionReason = '';
                this.toast('Reason required', res.message, 'warning');
                return;
            }

            const label = kind === 'IN' ? 'Checked in' : 'Checked out';
            const extra = res?.outOfRadius ? ' (out-of-radius exception recorded)' : '';
            this.toast('Success', label + extra, 'success');
            await this.load();
        } catch (e) {
            const msg = this.normalizeError(e);
            this.toast('Error', msg, 'error');
            this.error = msg;
        } finally {
            this.isLoading = false;
        }
    }

    handleReasonChange(e) {
        this.exceptionReason = e.target.value;
    }

    closeReason() {
        this.reasonModalOpen = false;
        this.pendingAction = undefined;
        this.pendingVisitId = undefined;
        this.pendingCoords = undefined;
    }

    async confirmReason() {
        const reason = (this.exceptionReason || '').trim();
        if (!reason) {
            this.toast('Required', 'Please enter a reason.', 'warning');
            return;
        }

        // Retry action using reason; coordinates are re-fetched to avoid stale GPS
        const kind = this.pendingAction;
        const visitId = this.pendingVisitId;
        this.closeReason();
        await this.performCheck(kind, visitId, reason);
    }

    getLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation not supported on this device/browser.'));
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (pos) => {
                    resolve({
                        lat: pos.coords.latitude,
                        lng: pos.coords.longitude,
                        accuracy: pos.coords.accuracy
                    });
                },
                (err) => {
                    // map to a consistent message
                    const msg =
                        err.code === 1 ? 'GPS permission denied.' :
                        err.code === 2 ? 'GPS unavailable.' :
                        err.code === 3 ? 'GPS timeout.' :
                        'GPS error.';
                    reject(new Error(msg));
                },
                { enableHighAccuracy: true, timeout: 12000, maximumAge: 0 }
            );
        });
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
