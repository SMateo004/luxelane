// The app no longer uses a service worker: it served cached, outdated
// versions after deploys. This one replaces the old worker on returning
// visitors, clears its caches, unregisters itself and reloads open tabs.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys.filter((k) => k.startsWith('flutter-')).map((k) => caches.delete(k)),
    );
    await self.registration.unregister();
    const tabs = await self.clients.matchAll({ type: 'window' });
    for (const tab of tabs) tab.navigate(tab.url);
  })());
});
