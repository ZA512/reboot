'use strict';

const REBOOT_CACHE_PREFIX = 'reboot-shell-';
const REBOOT_CACHE_NAME = '@@CACHE_NAME@@';
const REBOOT_SHELL_PATHS = Object.freeze(@@PRECACHE_PATHS@@);
const REBOOT_SCOPE_URL = new URL(self.registration.scope);
const REBOOT_INDEX_URL = new URL('index.html', REBOOT_SCOPE_URL).href;
const REBOOT_SHELL_URLS = new Set(
  REBOOT_SHELL_PATHS.map((path) => new URL(path, REBOOT_SCOPE_URL).href),
);

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(REBOOT_CACHE_NAME);
      const requests = REBOOT_SHELL_PATHS.map(
        (path) =>
          new Request(new URL(path, REBOOT_SCOPE_URL), {
            cache: 'reload',
            credentials: 'same-origin',
          }),
      );
      await cache.addAll(requests);
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter(
            (name) =>
              name.startsWith(REBOOT_CACHE_PREFIX) &&
              name !== REBOOT_CACHE_NAME,
          )
          .map((name) => caches.delete(name)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  if (request.mode === 'navigate') {
    event.respondWith(
      caches
        .open(REBOOT_CACHE_NAME)
        .then((cache) => cache.match(REBOOT_INDEX_URL))
        .then((response) => response ?? fetch(request)),
    );
    return;
  }

  requestUrl.search = '';
  requestUrl.hash = '';
  if (!REBOOT_SHELL_URLS.has(requestUrl.href)) {
    return;
  }

  event.respondWith(
    caches
      .open(REBOOT_CACHE_NAME)
      .then((cache) => cache.match(requestUrl.href))
      .then((response) => response ?? fetch(request)),
  );
});

self.addEventListener('message', (event) => {
  if (event.data?.type === 'REBOOT_ACTIVATE_UPDATE') {
    self.skipWaiting();
  }
});
