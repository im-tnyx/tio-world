import { probeOpenFoodFacts } from "./open_food_facts_capability_probe.ts";

const QUERIES = ["plain yogurt", "dal", "roti", "dahi"] as const;

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response(null, { status: 405 });
  const results = [];
  for (const query of QUERIES) results.push(await probeOpenFoodFacts(query));
  return Response.json({ synthetic: true, provider: "open_food_facts", results });
});
