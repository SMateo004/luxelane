// Snapshot of the assigned chauffeur, copied onto the booking so the rider
// never needs read access to the driver's private user/profile documents.

export interface ChauffeurSnapshot {
  driverId: string;
  name: string;
  photoUrl: string | null;
  rating: number | null;
  ratingCount: number;
  totalRides: number;
  vehicle: string;
  vehicleColor: string;
  plate: string;
  phone: string | null;
}

/** "María Fernanda Rojas" → "María Fernanda R." (privacy-friendly). */
export function displayName(full: unknown): string {
  const parts = String(full ?? '').trim().split(/\s+/).filter(Boolean);
  // Empty: the app shows a localized "Your chauffeur".
  if (parts.length === 0) return '';
  if (parts.length === 1) return parts[0];
  const last = parts[parts.length - 1];
  return `${parts.slice(0, -1).join(' ')} ${last[0].toUpperCase()}.`;
}

export function buildChauffeur(
  driverId: string,
  user: Record<string, unknown> | undefined,
  profile: Record<string, unknown> | undefined,
  vehicle: Record<string, unknown> | undefined,
): ChauffeurSnapshot {
  const ratingCount = Number(profile?.ratingCount ?? 0) || 0;
  const rating = Number(profile?.rating ?? 0);
  const make = String(vehicle?.make ?? '').trim();
  const model = String(vehicle?.model ?? '').trim();
  const phone = String(user?.phone ?? '').trim();
  return {
    driverId,
    name: displayName(user?.displayName),
    photoUrl: typeof user?.photoUrl === 'string' && user.photoUrl ? user.photoUrl : null,
    // A rating is only meaningful once riders have actually rated.
    rating: ratingCount > 0 && rating > 0 ? Math.round(rating * 10) / 10 : null,
    ratingCount,
    totalRides: Number(profile?.totalRides ?? 0) || 0,
    vehicle: [make, model].filter(Boolean).join(' ') || 'Vehículo Luxelane',
    vehicleColor: String(vehicle?.color ?? '').trim(),
    plate: String(vehicle?.plate ?? '').trim().toUpperCase(),
    phone: phone || null,
  };
}

/** Running average after adding one rating (1–5). */
export function nextAverage(current: number, count: number, rating: number): { rating: number; count: number } {
  const c = Math.max(0, Math.floor(count));
  const avg = c === 0 ? rating : (current * c + rating) / (c + 1);
  return { rating: Math.round(avg * 100) / 100, count: c + 1 };
}

export function isValidRating(r: unknown): r is number {
  return typeof r === 'number' && Number.isInteger(r) && r >= 1 && r <= 5;
}
