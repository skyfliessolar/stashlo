// Stashlo Service Worker v24 - stashlo.com
const CACHE = 'stashlo-v105';
const OFFLINE_URL = '/offline.html';
const PRECACHE = [
  '/',
  '/index.html',
  '/merchant.html', 
  '/admin.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png',
  '/offline.html',
  '/privacy.html',
  '/terms.html'
];

// Install - precache core files
self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(PRECACHE)).catch(() => {})
  );
});

// Activate - clean old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// Fetch - network first, cache fallback
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (!e.request.url.startsWith('https://stashlo.com') && 
      !e.request.url.startsWith('https://gcwevgaymahywqjorhnn.supabase.co')) return;
  
  e.respondWith(
    fetch(e.request)
      .then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(e.request)
        .then(cached => cached || caches.match(OFFLINE_URL))
      )
  );
});

// Push notifications
self.addEventListener('push', e => {
  const data = e.data ? e.data.json() : {};
  e.waitUntil(
    self.registration.showNotification(data.title || 'Stashlo', {
      body: data.body || 'You have a new notification',
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      data: data.url || '/'
    })
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.openWindow(e.notification.data || '/'));
});
