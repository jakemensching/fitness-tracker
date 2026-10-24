// Overload service worker: app shell works offline, updates arrive on the next open.
const VERSION = "overload-v17";
const SHELL = ["./", "./index.html", "./manifest.json", "./favicon.svg", "./apple-touch-icon.png", "./icons/icon-192.png", "./icons/icon-512.png"];
const CDN = ["cdnjs.cloudflare.com", "cdn.jsdelivr.net", "fonts.googleapis.com", "fonts.gstatic.com"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== VERSION).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  const sameOrigin = url.origin === self.location.origin;

  // The page itself: network first so new versions show up, cached copy when offline.
  if (req.mode === "navigate") {
    e.respondWith(fetch(req, { cache: "no-store" })
      .then(res => { const copy = res.clone(); caches.open(VERSION).then(c => c.put("./index.html", copy)); return res; })
      .catch(() => caches.match("./index.html")));
    return;
  }

  // Icons, Chart.js and fonts: serve from cache, refresh in the background.
  if (sameOrigin || CDN.includes(url.hostname)) {
    e.respondWith(caches.open(VERSION).then(async c => {
      const hit = await c.match(req);
      const net = fetch(req).then(res => { if (res && (res.ok || res.type === "opaque")) c.put(req, res.clone()); return res; }).catch(() => hit);
      return hit || net;
    }));
  }
  // Anything else (like a Supabase API) goes straight to the network.
});
