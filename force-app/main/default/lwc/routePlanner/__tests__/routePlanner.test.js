import { createElement } from 'lwc';
import RoutePlanner from 'c/routePlanner';

jest.mock('@salesforce/apex/RoutePlanner.generate', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/RoutePlanner.getStops', () => ({ default: jest.fn() }), { virtual: true });

import generate from '@salesforce/apex/RoutePlanner.generate';
import getStops from '@salesforce/apex/RoutePlanner.getStops';

const flushPromises = () => new Promise(setImmediate);

describe('c-route-planner', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('generates route and loads stops', async () => {
        generate.mockResolvedValue({ routePlanId: 'rp1', totalDistanceKm: 12.3, totalDurationMin: 40, stopCount: 2 });
        getStops.mockResolvedValue([{ Id: 's1', Sequence__c: 1, Visit__r: { Name: 'Visit A' } }]);

        const el = createElement('c-route-planner', { is: RoutePlanner });
        document.body.appendChild(el);

        const btn = el.shadowRoot.querySelector('lightning-button');
        btn.click();

        await flushPromises();
        await flushPromises();

        expect(generate).toHaveBeenCalled();
        expect(getStops).toHaveBeenCalled();
        expect(el.stops.length).toBe(1);
    });
});
