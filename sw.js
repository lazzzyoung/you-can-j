// Service worker: shows reminders pushed by the send-alarms function, even when the app is closed.
self.addEventListener('push', e => {
  const d = e.data ? e.data.json() : {};
  e.waitUntil(self.registration.showNotification(d.title || 'You can J', { body: d.body || '', tag: d.tag, icon: '/icon-192.png', data: { url: d.url || '/' } }));
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.matchAll({ type: 'window' }).then(ws => ws[0] ? ws[0].focus() : clients.openWindow(e.notification.data.url)));
});
