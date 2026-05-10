import { describe, it, expect, beforeEach, vi } from "vitest";

const apiBaseMock = vi.hoisted(() => ({ apiOrigin: "", isCapacitorBuild: false }));
const tokenMock = vi.hoisted(() => ({ value: null as string | null }));

vi.mock("$lib/utils/apiBase", () => apiBaseMock);
vi.mock("$lib/stores/authToken", () => ({
	authToken: {
		get: () => tokenMock.value,
	},
}));

const fetchMock = vi.fn();
vi.stubGlobal("fetch", fetchMock);

let apiFetch: typeof import("./apiFetch").apiFetch;

beforeEach(async () => {
	fetchMock.mockReset();
	fetchMock.mockResolvedValue(new Response(null, { status: 200 }));
	apiBaseMock.apiOrigin = "";
	apiBaseMock.isCapacitorBuild = false;
	tokenMock.value = null;
	vi.resetModules();
	apiFetch = (await import("./apiFetch")).apiFetch;
});

describe("apiFetch", () => {
	it("leaves URL alone when apiOrigin is empty", async () => {
		await apiFetch("/api/v2/user");
		expect(fetchMock).toHaveBeenCalledOnce();
		expect(fetchMock.mock.calls[0][0]).toBe("/api/v2/user");
	});

	it("prepends apiOrigin for paths starting with /", async () => {
		apiBaseMock.apiOrigin = "https://backend.example";
		await apiFetch("/api/v2/user");
		expect(fetchMock.mock.calls[0][0]).toBe("https://backend.example/api/v2/user");
	});

	it("does not prepend apiOrigin for absolute URLs", async () => {
		apiBaseMock.apiOrigin = "https://backend.example";
		await apiFetch("https://example.com/foo");
		expect(fetchMock.mock.calls[0][0]).toBe("https://example.com/foo");
	});

	it("does not prepend apiOrigin for protocol-relative URLs", async () => {
		apiBaseMock.apiOrigin = "https://backend.example";
		await apiFetch("//example.com/foo");
		expect(fetchMock.mock.calls[0][0]).toBe("//example.com/foo");
	});

	it("injects Bearer header only when isCapacitorBuild and token is set", async () => {
		apiBaseMock.apiOrigin = "https://backend.example";
		apiBaseMock.isCapacitorBuild = true;
		tokenMock.value = "hf_secret";
		await apiFetch("/api/v2/user");
		const init = fetchMock.mock.calls[0][1] as RequestInit;
		expect(new Headers(init.headers).get("Authorization")).toBe("Bearer hf_secret");
	});

	it("does not inject Bearer when not a Capacitor build", async () => {
		tokenMock.value = "hf_secret";
		apiBaseMock.isCapacitorBuild = false;
		await apiFetch("/api/v2/user");
		const init = fetchMock.mock.calls[0][1] as RequestInit;
		expect(init.headers ? new Headers(init.headers).get("Authorization") : null).toBeNull();
	});

	it("does not overwrite a caller-supplied Authorization header", async () => {
		apiBaseMock.isCapacitorBuild = true;
		tokenMock.value = "hf_secret";
		await apiFetch("/api/v2/user", {
			headers: { Authorization: "Bearer caller-token" },
		});
		const init = fetchMock.mock.calls[0][1] as RequestInit;
		expect(new Headers(init.headers).get("Authorization")).toBe("Bearer caller-token");
	});

	it("sets credentials: 'include' by default", async () => {
		await apiFetch("/api/v2/user");
		const init = fetchMock.mock.calls[0][1] as RequestInit;
		expect(init.credentials).toBe("include");
	});

	it("respects a caller-supplied credentials option", async () => {
		await apiFetch("/api/v2/user", { credentials: "omit" });
		const init = fetchMock.mock.calls[0][1] as RequestInit;
		expect(init.credentials).toBe("omit");
	});
});
