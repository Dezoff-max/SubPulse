import { getStatsStore, isAutomatedRequest, readStats, recordVisit, json } from "../lib/stats.js";

export default async (req, context) => {
  if (!["GET", "POST"].includes(req.method)) {
    return json({ error: "Method not allowed" }, 405, { Allow: "GET, POST" });
  }
  const store = getStatsStore(context);
  const now = Date.now();
  if (req.method === "POST") {
    const origin = req.headers.get("origin");
    if (origin && origin !== new URL(req.url).origin) return json({ error: "Invalid origin" }, 403);
    const payload = await req.json().catch(() => null);
    const visitorId = payload?.visitorId;
    if (typeof visitorId !== "string" || !/^[a-zA-Z0-9_-]{8,80}$/.test(visitorId)) {
      return json({ error: "A valid visitorId is required" }, 400);
    }
    if (!isAutomatedRequest(req)) await recordVisit(store, visitorId, context, now);
  }
  return json(await readStats(store, now));
};

export const config = { path: "/api/metrics" };
