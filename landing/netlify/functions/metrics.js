import { getStore } from "@netlify/blobs";

const SESSION_TTL_MS = 90 * 1000;
const DOWNLOADS_BASELINE = 999;
const DEFAULT_COUNTRY_CODE = "UN";
const DEFAULT_COUNTRY_NAME = "Unknown";
const JSON_HEADERS = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: JSON_HEADERS,
  });
}

function getStatsStore() {
  return getStore({
    name: "subpulse-stats",
    consistency: "strong",
  });
}

function normalizeCountryCode(countryCode) {
  if (typeof countryCode !== "string") return DEFAULT_COUNTRY_CODE;

  const normalized = countryCode.trim().toUpperCase();
  return /^[A-Z]{2}$/.test(normalized) ? normalized : DEFAULT_COUNTRY_CODE;
}

function getCountry(context) {
  const countryCode = normalizeCountryCode(context?.geo?.country?.code);
  const countryName = context?.geo?.country?.name || DEFAULT_COUNTRY_NAME;

  return { countryCode, countryName };
}

function publicRecentUsers(recentUsers) {
  return (Array.isArray(recentUsers) ? recentUsers : []).slice(0, 3).map((user) => ({
    countryCode: normalizeCountryCode(user.countryCode),
    countryName: user.countryName || DEFAULT_COUNTRY_NAME,
    seenAt: user.seenAt || null,
  }));
}

async function readTotals(store) {
  const totals = (await store.get("totals", { type: "json" })) || {
    downloads: DOWNLOADS_BASELINE,
    totalVisitors: 0,
    recentUsers: [],
  };

  if (!Number.isFinite(totals.downloads) || totals.downloads < DOWNLOADS_BASELINE) {
    totals.downloads = DOWNLOADS_BASELINE;
  }

  if (!Number.isFinite(totals.totalVisitors) || totals.totalVisitors < 0) {
    totals.totalVisitors = 0;
  }

  totals.recentUsers = Array.isArray(totals.recentUsers) ? totals.recentUsers.slice(0, 3) : [];

  return totals;
}

async function countOnlineSessions(store, now) {
  const { blobs } = await store.list({ prefix: "sessions/" });
  let online = 0;

  await Promise.all(
    blobs.map(async ({ key }) => {
      const session = await store.get(key, { type: "json" });
      if (!session?.lastSeen || now - session.lastSeen > SESSION_TTL_MS) {
        await store.delete(key);
        return;
      }

      online += 1;
    })
  );

  return online;
}

export default async (req, context) => {
  const store = getStatsStore();
  const now = Date.now();
  const totals = await readTotals(store);

  if (req.method === "POST") {
    const payload = await req.json().catch(() => ({}));
    const visitorId = typeof payload.visitorId === "string" ? payload.visitorId.slice(0, 80) : "";
    const sessionId = typeof payload.sessionId === "string" ? payload.sessionId.slice(0, 80) : "";

    if (!visitorId || !sessionId) {
      return json({ error: "visitorId and sessionId are required" }, 400);
    }

    const visitorKey = `visitors/${visitorId}`;
    const existingVisitor = await store.get(visitorKey, { type: "json" });

    if (!existingVisitor) {
      totals.totalVisitors += 1;
      await store.setJSON(visitorKey, { firstSeen: now });
    }

    const country = getCountry(context);
    totals.recentUsers = [
      {
        id: visitorId,
        ...country,
        seenAt: new Date(now).toISOString(),
      },
      ...totals.recentUsers.filter((user) => user.id !== visitorId),
    ].slice(0, 3);

    await store.setJSON("totals", totals);
    await store.setJSON(`sessions/${sessionId}`, {
      visitorId,
      lastSeen: now,
    });
  }

  const online = await countOnlineSessions(store, now);

  return json({
    downloads: totals.downloads,
    online,
    recentUsers: publicRecentUsers(totals.recentUsers),
    totalVisitors: totals.totalVisitors,
    updatedAt: new Date(now).toISOString(),
  });
};

export const config = {
  path: "/api/metrics",
};
