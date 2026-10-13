// App-wide switches in config/global, written from Admin → Settings and
// read (publicly) by the rider and chauffeur apps.

/** quoteBooking / createBooking error while bookings are paused. */
export const MAINTENANCE = 'app/maintenance';

export interface GlobalConfigLike {
  isMaintenanceMode?: unknown;
}

/**
 * Maintenance pauses new bookings only: rides already booked or in
 * progress carry on (riders keep tracking, chauffeurs keep driving).
 */
export function bookingsPaused(config: GlobalConfigLike | undefined): boolean {
  return config?.isMaintenanceMode === true;
}
