import assert from "node:assert/strict";
import { setImmediate } from "node:timers/promises";
import test from "node:test";
import {
  DOWNLOADS_BASELINE,
  VISITORS_BASELINE,
  SESSION_TTL_MS,
  readStats,
  recordDownload,
  recordVisit,
} from "../netlify/lib/stats.js";
import download from "../netlify/functions/download.js";
import metrics from "../netlify/functions/metrics.js";

// Every operation yields so parallel requests really interleave; returning
// cloned values also prevents accidental mutation of a previously read blob.
class AsyncMemoryStore {
  constructor(initial = {}) {
    this.values = new Map(Object.entries(structuredClone(initial)));
    this.writes = [];
  }

  async get(key) {
    await setImmediate();
    return this.values.has(key) ? structuredClone(this.values.get(key)) : null;
  }

  async setJSON(key, value) {
    await setImmediate();
    this.writes.push(key);
    this.values.set(key, structuredClone(value));
  }

  async list({ prefix }) {
    await setImmediate();
    return { blobs: [...this.values.keys()].filter((key) => key.startsWith(prefix)).map((key) => ({ key })) };
  }
}

const NOW = Date.UTC(2026, 9, 3, 13);
const CONTEXT = { geo: { country: { code: "RU", name: "Russia" } } };

test("empty store discloses the configured bases separately from measured events", async () => {
  const store = new AsyncMemoryStore();
  const stats = await readStats(store, NOW);
  assert.equal(DOWNLOADS_BASELINE, 1239);
  assert.equal(VISITORS_BASELINE, 758);
  assert.equal(stats.downloads, 1239);
  assert.equal(stats.totalVisitors, 758);
  assert.deepEqual(stats.baseline, { downloads: 1239, totalVisitors: 758 });
  assert.deepEqual(stats.measured, { downloads: 0, totalVisitors: 0 });
  assert.equal(stats.online, 0);
  assert.deepEqual(stats.recentUsers, []);
  assert.deepEqual(store.writes, []);
});

test("20 concurrent downloads and heartbeats retain every download and never overwrite legacy totals", async () => {
  const legacy = { downloads: 1300, totalVisitors: 761, recentUsers: [] };
  const store = new AsyncMemoryStore({
    totals: legacy,
    "visitors/legacy-visitor-a": { firstSeen: NOW - 100_000 },
    "visitors/legacy-visitor-b": { firstSeen: NOW - 100_000 },
    "visitors/legacy-visitor-c": { firstSeen: NOW - 100_000 },
  });
  await Promise.all(Array.from({ length: 20 }, (_, index) => Promise.all([
    recordDownload(store, `parallel-download-${index}`),
    recordVisit(store, `new-visitor-${index}`, CONTEXT, NOW),
    readStats(store, NOW),
  ])));
  const stats = await readStats(store, NOW);
  assert.equal(stats.downloads, 1320);
  assert.equal(stats.totalVisitors, 781);
  assert.equal(stats.online, 20);
  assert.deepEqual(stats.measured, { downloads: 20, totalVisitors: 23 });
  assert.deepEqual(await store.get("totals"), legacy);
  assert.equal(store.writes.includes("totals"), false);
});

test("concurrent first visits, tabs and repeated heartbeats count one visitor and one online presence", async () => {
  const store = new AsyncMemoryStore();
  await Promise.all(Array.from({ length: 20 }, () => recordVisit(store, "same-visitor-123", CONTEXT, NOW)));
  await recordVisit(store, "same-visitor-123", CONTEXT, NOW + 30_000);
  const stats = await readStats(store, NOW + 30_000);
  assert.equal(stats.totalVisitors, 759);
  assert.equal(stats.measured.totalVisitors, 1);
  assert.equal(stats.online, 1);
  assert.equal(stats.downloads, 1239);
});

test("retrying one download request ID is idempotent while distinct requests each count", async () => {
  const store = new AsyncMemoryStore();
  await Promise.all(Array.from({ length: 20 }, () => recordDownload(store, "same-download-request")));
  await recordDownload(store, "distinct-download-request");
  const stats = await readStats(store, NOW);
  assert.equal(stats.downloads, 1241);
  assert.equal(stats.measured.downloads, 2);
});

test("online TTL excludes expired, future and invalid timestamps without deleting stored visits", async () => {
  const store = new AsyncMemoryStore();
  await recordVisit(store, "visitor-current", CONTEXT, NOW);
  await recordVisit(store, "visitor-boundary", CONTEXT, NOW - SESSION_TTL_MS);
  await recordVisit(store, "visitor-expired", CONTEXT, NOW - SESSION_TTL_MS - 1);
  await recordVisit(store, "visitor-future", CONTEXT, NOW + 1);
  await store.setJSON("presence-v2/visitor-invalid", { id: "visitor-invalid", lastSeen: "invalid" });
  const beforeWrites = store.writes.length;
  const stats = await readStats(store, NOW);
  assert.equal(stats.online, 2);
  assert.equal(stats.totalVisitors, 762);
  assert.equal((await store.list({ prefix: "presence-v2/" })).blobs.length, 5);
  assert.equal(store.writes.length, beforeWrites);
  assert.equal((await readStats(store, NOW + SESSION_TTL_MS + 2)).online, 0);
});

test("recent countries retain legacy history, deduplicate visitors and omit private visitor IDs", async () => {
  const store = new AsyncMemoryStore({ totals: {
    downloads: 999,
    totalVisitors: 760,
    recentUsers: [
      { id: "visitor-existing", countryCode: "US", countryName: "United States", seenAt: new Date(NOW - 20_000).toISOString() },
      { id: "visitor-legacy", countryCode: "DE", countryName: "Germany", seenAt: new Date(NOW - 30_000).toISOString() },
    ],
  } });
  await recordVisit(store, "visitor-existing", CONTEXT, NOW);
  await recordVisit(store, "visitor-new", { geo: { country: { code: "tr", name: "Türkiye" } } }, NOW - 10_000);
  const stats = await readStats(store, NOW);
  assert.equal(stats.downloads, 1239);
  assert.deepEqual(stats.recentUsers.map(({ countryCode }) => countryCode), ["RU", "TR", "DE"]);
  assert.equal(stats.recentUsers.some((user) => "id" in user), false);
});

test("HEAD download and automated prefetch redirect without requiring or incrementing a stats store", async () => {
  const requests = [
    new Request("https://example.test/api/download", { method: "HEAD" }),
    new Request("https://example.test/api/download", { headers: { "User-Agent": "Googlebot" } }),
    new Request("https://example.test/api/download", { headers: { "Sec-Purpose": "prefetch" } }),
  ];
  for (const request of requests) {
    const response = await download(request, {});
    assert.equal(response.status, 302);
    assert.equal(response.headers.get("Location"), "https://example.test/downloads/SubPulse.dmg");
    assert.match(response.headers.get("Cache-Control"), /no-store/);
    assert.equal(response.headers.get("Netlify-CDN-Cache-Control"), "no-store");
    assert.equal(await response.text(), "");
  }
});

test("unsupported endpoint methods are rejected before connecting to the stats store", async () => {
  const response = await download(new Request("https://example.test/api/download", { method: "POST" }), {});
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("Allow"), "GET, HEAD");
  const metricsResponse = await metrics(new Request("https://example.test/api/metrics", { method: "DELETE" }), {});
  assert.equal(metricsResponse.status, 405);
  assert.equal(metricsResponse.headers.get("Allow"), "GET, POST");
  assert.match(metricsResponse.headers.get("Cache-Control"), /no-store/);
});
