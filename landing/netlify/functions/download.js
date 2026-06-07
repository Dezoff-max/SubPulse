import { getStore } from "@netlify/blobs";

const DOWNLOADS_BASELINE = 999;

function getStatsStore() {
  return getStore({
    name: "subpulse-stats",
    consistency: "strong",
  });
}

export default async () => {
  const store = getStatsStore();
  const totals = (await store.get("totals", { type: "json" })) || {
    downloads: DOWNLOADS_BASELINE,
    recentUsers: [],
    totalVisitors: 0,
  };

  if (!Number.isFinite(totals.downloads) || totals.downloads < DOWNLOADS_BASELINE) {
    totals.downloads = DOWNLOADS_BASELINE;
  }

  totals.downloads += 1;
  await store.setJSON("totals", totals);

  return Response.redirect("https://subpulse.netlify.app/downloads/SubPulse.dmg", 302);
};

export const config = {
  path: "/api/download",
};
