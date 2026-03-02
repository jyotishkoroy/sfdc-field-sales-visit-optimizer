import { createElement } from 'lwc';
import FieldVisitMobile from 'c/fieldVisitMobile';

jest.mock('@salesforce/apex/FieldVisitController.getTodayVisits', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/VisitCheckInService.checkIn', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/VisitCheckInService.checkOut', () => ({ default: jest.fn() }), { virtual: true });

import getTodayVisits from '@salesforce/apex/FieldVisitController.getTodayVisits';
import checkIn from '@salesforce/apex/VisitCheckInService.checkIn';

const flushPromises = () => new Promise(setImmediate);

describe('c-field-visit-mobile', () => {
    beforeEach(() => {
        global.navigator.geolocation = {
            getCurrentPosition: (success) => success({ coords: { latitude: 12.0, longitude: 77.0, accuracy: 5 } })
        };
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('loads visits on init', async () => {
        getTodayVisits.mockResolvedValue([{ Id: 'a1', Name: 'Visit 1', Status__c: 'Planned' }]);
        const el = createElement('c-field-visit-mobile', { is: FieldVisitMobile });
        document.body.appendChild(el);
        await flushPromises();

        expect(getTodayVisits).toHaveBeenCalled();
        expect(el.visits.length).toBe(1);
    });

    it('check-in calls apex with coords', async () => {
        getTodayVisits.mockResolvedValue([{ Id: 'a1', Name: 'Visit 1', Status__c: 'Planned' }]);
        checkIn.mockResolvedValue({ success: true, outOfRadius: false });

        const el = createElement('c-field-visit-mobile', { is: FieldVisitMobile });
        document.body.appendChild(el);
        await flushPromises();

        const btn = el.shadowRoot.querySelector('lightning-button');
        btn.click();
        await flushPromises();

        expect(checkIn).toHaveBeenCalled();
    });
});
