import { getStatsStore, isAutomatedRequest, recordDownload, json } from "../lib/stats.js";

export default async (req, context) => {
  if (!["GET", "HEAD"].includes(req.method)) {
    return json({ error: "Method not allowed" }, 405, { Allow: "GET, HEAD" });
  }
  if (req.method === "GET" && !isAutomatedRequest(req)) {
    try {
      // Every request has its own key: concurrent visits cannot overwrite it.
      await recordDownload(getStatsStore(context), context?.requestId);
    } catch {
      // An analytics outage must never prevent the actual download.
      console.error("Unable to record a SubPulse download request");
    }
  }
  return new Response(null, {
    status: 302,
    headers: {
      Location: new URL("/downloads/SubPulse.dmg", req.url).href,
      "Cache-Control": "no-store, max-age=0",
      "Netlify-CDN-Cache-Control": "no-store",
    },
  });
};

export const config = { path: "/api/download" };
