import {
  outcomeResponse,
  successResponse,
  validateParseRequest,
  type ParseResponse,
  type ResponseItem,
} from "./contract.ts";
import {
  ABORTED,
  clampItemConcurrency,
  DEFAULT_ITEM_CONCURRENCY,
  DEFAULT_REQUEST_DEADLINE_MS,
  mapConcurrentOrdered,
  raceWithAbort,
} from "./async_control.ts";
import { resolveWithFallback } from "./resolver.ts";
import type {
  FoodNutritionResolver,
  MealInterpreter,
  ResolverResult,
} from "./types.ts";

export interface MealTextHandlerDependencies {
  readonly authenticate: (request: Request) => Promise<boolean>;
  readonly interpreter: MealInterpreter;
  readonly primaryResolver: FoodNutritionResolver;
  readonly secondaryResolver?: FoodNutritionResolver | null;
  readonly requestDeadlineMs?: number;
  readonly itemConcurrency?: number;
}

const JSON_HEADERS = { "Content-Type": "application/json" } as const;

export function createMealTextHandler(
  dependencies: MealTextHandlerDependencies,
): (request: Request) => Promise<Response> {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405, { Allow: "POST" });
    }

    const requestAbort = new AbortController();
    const deadlineMs = positiveDeadline(
      dependencies.requestDeadlineMs,
      DEFAULT_REQUEST_DEADLINE_MS,
    );
    const deadline = setTimeout(() => requestAbort.abort(), deadlineMs);

    try {
      let authenticated: boolean | typeof ABORTED;
      try {
        authenticated = await raceWithAbort(
          requestAbort.signal,
          () => dependencies.authenticate(request),
        );
      } catch {
        authenticated = false;
      }
      if (authenticated === ABORTED) return unavailableResponse();
      if (!authenticated) return json({ error: "unauthorized" }, 401);

      let body: unknown;
      try {
        body = await request.json();
      } catch {
        return json({ error: "invalid_request" }, 400);
      }
      if (requestAbort.signal.aborted) return unavailableResponse();

      const validation = validateParseRequest(body);
      if (!validation.ok) return json({ error: "invalid_request" }, 400);

      let interpretation;
      try {
        interpretation = await raceWithAbort(
          requestAbort.signal,
          () => dependencies.interpreter.interpret(
            validation.request.mealText,
            requestAbort.signal,
          ),
        );
      } catch {
        return unavailableResponse();
      }
      if (interpretation === ABORTED) return unavailableResponse();
      if (interpretation.kind === "unrecognized") {
        return response(outcomeResponse("unrecognized"));
      }
      if (interpretation.kind === "unavailable") {
        return unavailableResponse();
      }

      let resolved: readonly ResolverResult[] | typeof ABORTED;
      try {
        resolved = await mapConcurrentOrdered(
          interpretation.items,
          clampItemConcurrency(dependencies.itemConcurrency ?? DEFAULT_ITEM_CONCURRENCY),
          requestAbort.signal,
          (candidate, _index, signal) => resolveWithFallback(
            candidate,
            dependencies.primaryResolver,
            dependencies.secondaryResolver ?? null,
            signal,
          ),
        );
      } catch {
        return unavailableResponse();
      }
      if (resolved === ABORTED || requestAbort.signal.aborted) {
        return unavailableResponse();
      }

      const resolvedItems: ResponseItem[] = [];
      let sawIncomplete = false;
      let sawUnavailable = false;
      for (const item of resolved) {
        if (item.kind === "resolved") {
          resolvedItems.push(item.item);
        } else if (item.kind === "incomplete") {
          sawIncomplete = true;
        } else {
          sawUnavailable = true;
        }
      }

      if (requestAbort.signal.aborted) return unavailableResponse();
      if (sawIncomplete) return response(outcomeResponse("incomplete"));
      if (sawUnavailable) return unavailableResponse();
      if (resolvedItems.length !== interpretation.items.length || resolvedItems.length === 0) {
        return response(outcomeResponse("incomplete"));
      }

      return response(successResponse(interpretation.mealName, resolvedItems));
    } finally {
      clearTimeout(deadline);
    }
  };
}

function positiveDeadline(value: number | undefined, fallback: number): number {
  return Number.isFinite(value) && value! > 0 ? Math.floor(value!) : fallback;
}

function unavailableResponse(): Response {
  return response(outcomeResponse("unavailable"));
}

function response(payload: ParseResponse): Response {
  return json(payload, 200);
}

function json(
  payload: unknown,
  status: number,
  headers: Readonly<Record<string, string>> = {},
): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...JSON_HEADERS, ...headers },
  });
}
