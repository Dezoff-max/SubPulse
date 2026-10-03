import { randomUUID } from "node:crypto";
import { getStore, getDeployStore } from "@netlify/blobs";

export const DOWNLOADS_BASELINE = 1239;
export const VISITORS_BASELINE = 758;
export const SESSION_TTL_MS = 90_000;

export function getStatsStore(context) {
  const options = { name: "subpulse-stats", consistency: "strong" };
  // Drafts and old deploy permalinks must not contaminate published statistics.
  return context?.deploy?.context === "production" && context.deploy.published
    ? getStore(options)
    : getDeployStore(options);
}

export function json(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "Netlify-CDN-Cache-Control": "no-store",
      ...headers,
    },
  });
}

export function isAutomatedRequest(req) {
  return /bot\b|crawler|spider|slurp|headless|lighthouse|monitor|preview/i.test(req.headers.get("user-agent") || "") ||
    /prefetch|prerender/i.test(`${req.headers.get("purpose") || ""} ${req.headers.get("sec-purpose") || ""}`);
}

function country(context) {
  const code = context?.geo?.country?.code;
  return {
    countryCode: typeof code === "string" && /^[A-Z]{2}$/.test(code.toUpperCase()) ? code.toUpperCase() : "UN",
    countryName: context?.geo?.country?.name || "Unknown",
  };
}

export async function recordVisit(store, visitorId, context, now = Date.now()) {
  const key = `visitors/${visitorId}`;
  if (!(await store.get(key, { type: "json" }))) {
    // Simultaneous first visits still resolve to one unique key.
    await store.setJSON(key, { firstSeen: now });
  }
  await store.setJSON(`presence-v2/${visitorId}`, {
    id: visitorId,
    lastSeen: now,
    seenAt: new Date(now).toISOString(),
    ...country(context),
  });
}

export async function recordDownload(store, requestId) {
  const id = typeof requestId === "string" && /^[a-zA-Z0-9_-]{8,100}$/.test(requestId) ? requestId : randomUUID();
  await store.setJSON(`download-events-v2/${id}`, { startedAt: new Date().toISOString() });
}

export async function readStats(store, now = Date.now()) {
  const [legacy, visitors, downloads, presence] = await Promise.all([
    store.get("totals", { type: "json" }),
    store.list({ prefix: "visitors/" }),
    store.list({ prefix: "download-events-v2/" }),
    store.list({ prefix: "presence-v2/" }),
  ]);
  const active = [];
  // Bound concurrent reads; never delete presence in a read request.
  for (let i = 0; i < presence.blobs.length; i += 20) {
    const batch = await Promise.all(presence.blobs.slice(i, i + 20).map(({ key }) => store.get(key, { type: "json" })));
    active.push(...batch.filter(Boolean));
  }

  const recentById = new Map();
  for (const user of [...active, ...(Array.isArray(legacy?.recentUsers) ? legacy.recentUsers : [])]) {
    if (!user.id) continue;
    const previous = recentById.get(user.id);
    if (!previous || Date.parse(user.seenAt) > Date.parse(previous.seenAt)) recentById.set(user.id, user);
  }
  const recentUsers = [...recentById.values()]
    .sort((a, b) => Date.parse(b.seenAt) - Date.parse(a.seenAt))
    .slice(0, 3)
    .map(({ countryCode, countryName, seenAt }) => ({ countryCode, countryName, seenAt }));

  // Legacy totals are read-only from this version onward. Configured bases are
  // disclosed separately and are not described as newly measured traffic.
  const downloadsBase = Math.max(DOWNLOADS_BASELINE, Number.isSafeInteger(legacy?.downloads) ? legacy.downloads : 0);
  return {
    downloads: downloadsBase + downloads.blobs.length,
    totalVisitors: VISITORS_BASELINE + visitors.blobs.length,
    online: active.filter(({ lastSeen }) => Number.isFinite(lastSeen) && now - lastSeen >= 0 && now - lastSeen <= SESSION_TTL_MS).length,
    recentUsers,
    baseline: { downloads: downloadsBase, totalVisitors: VISITORS_BASELINE },
    measured: { downloads: downloads.blobs.length, totalVisitors: visitors.blobs.length },
    updatedAt: new Date(now).toISOString(),
  };
}
