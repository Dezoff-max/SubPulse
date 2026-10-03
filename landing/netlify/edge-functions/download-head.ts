// Netlify's origin proxy normalizes HEAD to GET. Handle it at the edge before
// it can reach the download-event writer and falsely increment the counter.
export default async (request: Request) => {
  if (request.method !== "HEAD") return;
  return new Response(null, {
    status: 302,
    headers: {
      Location: new URL("/downloads/SubPulse.dmg", request.url).href,
      "Cache-Control": "no-store, max-age=0",
    },
  });
};

export const config = { path: "/api/download" };
