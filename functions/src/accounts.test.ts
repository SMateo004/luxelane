import { isSuspended, suspensionChange } from './accounts';

describe('accounts', () => {
  it('only an explicit isActive=false suspends, never an admin', () => {
    expect(isSuspended({ role: 'rider', isActive: false })).toBe(true);
    expect(isSuspended({ role: 'driver', isActive: false })).toBe(true);
    expect(isSuspended({ role: 'admin', isActive: false })).toBe(false);
    expect(isSuspended({ role: 'rider' })).toBe(false);
    expect(isSuspended({ role: 'rider', isActive: true })).toBe(false);
    expect(isSuspended(undefined)).toBe(false);
  });

  it('detects suspension and reactivation', () => {
    expect(suspensionChange({ role: 'driver', isActive: true }, { role: 'driver', isActive: false })).toBe('suspended');
    expect(suspensionChange({ role: 'driver' }, { role: 'driver', isActive: false })).toBe('suspended');
    expect(suspensionChange({ role: 'driver', isActive: false }, { role: 'driver', isActive: true })).toBe('reactivated');
    expect(suspensionChange({ role: 'driver', isActive: false }, { role: 'driver', isActive: false })).toBeNull();
    expect(suspensionChange({ role: 'driver', isActive: false }, undefined)).toBeNull(); // deleted
    expect(suspensionChange({ role: 'rider', isActive: true }, { role: 'rider', isActive: true, displayName: 'x' } as never)).toBeNull();
  });
});
