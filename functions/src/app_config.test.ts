import { bookingsPaused } from './app_config';

describe('app_config', () => {
  it('only an explicit isMaintenanceMode=true pauses bookings', () => {
    expect(bookingsPaused({ isMaintenanceMode: true })).toBe(true);
    expect(bookingsPaused({ isMaintenanceMode: false })).toBe(false);
    expect(bookingsPaused({ isMaintenanceMode: 'true' })).toBe(false);
    expect(bookingsPaused({})).toBe(false);
    expect(bookingsPaused(undefined)).toBe(false);
  });
});
