const CACHE = 'stashlo-v2';
const ASSETS = ['./', './index.html', './manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
  ));
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        if (res && res.status === 200 && e.request.method === 'GET') {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      }).catch(() => cached);
    })
  );
});

// Notification click — open app
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const cardId = e.notification.data?.cardId;
  if (e.action === 'dismiss') return;
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(wins => {
      const existing = wins.find(w => w.url.includes('stashlo'));
      if (existing) {
        existing.focus();
        if (cardId) existing.postMessage({ type: 'OPEN_CARD', cardId });
      } else {
        clients.openWindow('./index.html').then(win => {
          if (win && cardId) setTimeout(() => win.postMessage({ type: 'OPEN_CARD', cardId }), 1500);
        });
      }
    })
  );
});

// Daily reminder scheduling
let reminderTimer = null;

self.addEventListener('message', e => {
  if (e.data?.type === 'SCHEDULE_REMINDER') {
    if (reminderTimer) clearTimeout(reminderTimer);
    reminderTimer = setTimeout(() => fireReminder(e.data.time), e.data.delay);
  }
});

function fireReminder(time) {
  self.registration.showNotification('Stashlo — Ready to shop?', {
    body: 'Your loyalty cards are ready. Open Stashlo before you head out.',
    icon: 'icon-192.png',
    badge: 'icon-192.png',
    tag: 'sl-reminder',
    renotify: true,
    actions: [{ action: 'open', title: 'Open Stashlo' }]
  });
  const [hh, mm] = time.split(':').map(Number);
  const next = new Date();
  next.setDate(next.getDate() + 1);
  next.setHours(hh, mm, 0, 0);
  reminderTimer = setTimeout(() => fireReminder(time), next - Date.now());
}

self.addEventListener('push', e => {
  const data = e.data?.json() || {};
  e.waitUntil(
    self.registration.showNotification(data.title || 'Stashlo', {
      body: data.body || 'Your cards are ready.',
      icon: 'icon-192.png',
      badge: 'icon-192.png',
      tag: data.tag || 'sl-push',
      data: data
    })
  );
});
