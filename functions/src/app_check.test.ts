import { appCheckDecision, appCheckEnforced } from './app_check';

describe('app_check', () => {
  it('logs missing tokens until enforcement is switched on', () => {
    expect(appCheckDecision(true, false)).toBe('ok');
    expect(appCheckDecision(true, true)).toBe('ok');
    expect(appCheckDecision(false, false)).toBe('log');
    expect(appCheckDecision(false, true)).toBe('reject');
  });

  it('only APP_CHECK_ENFORCE=true enforces', () => {
    expect(appCheckEnforced({ APP_CHECK_ENFORCE: 'true' })).toBe(true);
    expect(appCheckEnforced({ APP_CHECK_ENFORCE: '1' })).toBe(false);
    expect(appCheckEnforced({})).toBe(false);
  });
});
