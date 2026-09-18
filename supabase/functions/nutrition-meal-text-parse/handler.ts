import {
  outcomeResponse,
  successResponse,
  validateParseRequest,
  type ParseResponse,
  type ResponseItem,
} from "./contract.ts";
import { resolveWithFallback } from "./resolver.ts";
import type {
  FoodNutritionResolver,
  MealInterpreter,
} from "./types.ts";

export interface MealTextHandlerDependencies {
  readonly authenticate: (request: Request) => Promise<boolean>;
  readonly interpreter: MealInterpreter;
  readonly primaryResolver: FoodNutritionResolver;
  readonly secondaryResolver?: FoodNutritionResolver | null;
}

const JSON_HEADERS = { "Content-Type": "application/json" } as const;

export function createMealTextHandler(
  dependencies: MealTextHandlerDependencies,
): (request: Request) => Promise<Response> {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405, {
        Allow: "POST",
      });
    }

    let authenticated = false;
    try {
      authenticated = await dependencies.authenticate(request);
    } catch {
      authenticated = false;
    }
    if (!authenticated) return json({ error: "unauthorized" }, 401);

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid_request" }, 400);
    }

    const validation = validateParseRequest(body);
    if (!validation.ok) return json({ error: "invalid_request" }, 400);

    const interpretation = await dependencies.interpreter.interpret(
      validation.request.mealText,
    );
    if (interpretation.kind === "unrecognized") {
      return response(outcomeResponse("unrecognized"));
    }
    if (interpretation.kind === "unavailable") {
      return response(outcomeResponse("unavailable"));
    }

    const resolvedItems: ResponseItem[] = [];
    let sawIncomplete = false;
    let sawUnavailable = false;

    for (const candidate of interpretation.items) {
      const resolved = await resolveWithFallback(
        candidate,
        dependencies.primaryResolver,
        dependencies.secondaryResolver ?? null,
      );

      if (resolved.kind === "resolved") {
        resolvedItems.push(resolved.item);
      } else if (resolved.kind === "incomplete") {
        sawIncomplete = true;
      } else {
        sawUnavailable = true;
      }
    }

    if (sawIncomplete) return response(outcomeResponse("incomplete"));
    if (sawUnavailable) return response(outcomeResponse("unavailable"));
    if (resolvedItems.length !== interpretation.items.length || resolvedItems.length === 0) {
      return response(outcomeResponse("incomplete"));
    }

    return response(successResponse(interpretation.mealName, resolvedItems));
  };
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
