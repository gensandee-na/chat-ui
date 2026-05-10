import { apiOrigin, isCapacitorBuild } from "$lib/utils/apiBase";
import { authToken } from "$lib/stores/authToken";

function isAbsolute(url: string): boolean {
	return /^[a-z][a-z0-9+.-]*:\/\//i.test(url) || url.startsWith("//");
}

function withOrigin(input: RequestInfo | URL): RequestInfo | URL {
	if (!apiOrigin) return input;
	if (typeof input === "string") {
		return isAbsolute(input) ? input : `${apiOrigin}${input.startsWith("/") ? "" : "/"}${input}`;
	}
	return input;
}

function hasHeader(headers: HeadersInit | undefined, name: string): boolean {
	if (!headers) return false;
	if (headers instanceof Headers) return headers.has(name);
	if (Array.isArray(headers)) {
		const lower = name.toLowerCase();
		return headers.some(([k]) => k.toLowerCase() === lower);
	}
	const lower = name.toLowerCase();
	return Object.keys(headers).some((k) => k.toLowerCase() === lower);
}

export async function apiFetch(
	input: RequestInfo | URL,
	init: RequestInit = {}
): Promise<Response> {
	const finalInit: RequestInit = {
		...init,
		credentials: init.credentials ?? "include",
	};

	if (isCapacitorBuild) {
		const token = authToken.get();
		if (token && !hasHeader(init.headers, "authorization")) {
			const headers = new Headers(init.headers);
			headers.set("Authorization", `Bearer ${token}`);
			finalInit.headers = headers;
		}
	}

	return fetch(withOrigin(input), finalInit);
}
