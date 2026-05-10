import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

interface PostedMessage {
	type: string;
	args?: unknown;
	requestId?: string;
}

async function loadBridgeWithHandler() {
	const posted: PostedMessage[] = [];
	const handler = { postMessage: vi.fn((msg: PostedMessage) => posted.push(msg)) };
	vi.stubGlobal("window", { webkit: { messageHandlers: { hfchat: handler } } });
	vi.resetModules();
	const mod = await import("./bridge");
	return { mod, posted, handler };
}

async function loadBridgeWithoutHandler() {
	vi.stubGlobal("window", {});
	vi.resetModules();
	return import("./bridge");
}

describe("native bridge", () => {
	beforeEach(() => {
		vi.unstubAllGlobals();
	});
	afterEach(() => {
		vi.unstubAllGlobals();
		vi.resetModules();
	});

	it("isNative is false outside a WKWebView", async () => {
		const mod = await loadBridgeWithoutHandler();
		expect(mod.isNative).toBe(false);
	});

	it("isNative is true when webkit handler is present", async () => {
		const { mod } = await loadBridgeWithHandler();
		expect(mod.isNative).toBe(true);
	});

	it("posts share message to webkit handler", async () => {
		const { mod, posted } = await loadBridgeWithHandler();
		mod.native.share({ conversationId: "c1" });
		expect(posted).toEqual([{ type: "nativeShare", args: { conversationId: "c1" } }]);
	});

	it("posts haptic, didLoad, didStart/EndGeneration, error", async () => {
		const { mod, posted } = await loadBridgeWithHandler();
		mod.native.haptic({ style: "selection" });
		mod.native.didLoad("c2");
		mod.native.didStartGeneration({ conversationId: "c2" });
		mod.native.didEndGeneration({ conversationId: "c2", interrupted: true });
		mod.native.error({ message: "boom", statusCode: 500 });
		expect(posted.map((p) => p.type)).toEqual([
			"nativeHaptic",
			"webDidLoad",
			"webDidStartGeneration",
			"webDidEndGeneration",
			"webError",
		]);
	});

	it("native helpers are no-ops without a handler", async () => {
		const mod = await loadBridgeWithoutHandler();
		// Should not throw.
		mod.native.share({ conversationId: "x" });
		mod.native.haptic({ style: "impact" });
	});

	it("requestNativeFiles rejects when no handler is available", async () => {
		const mod = await loadBridgeWithoutHandler();
		await expect(mod.requestNativeFiles({ accept: "*/*", multiple: false })).rejects.toThrow(
			/native bridge/i
		);
	});

	it("requestNativeFiles posts a message with a request id and resolves on attachFiles", async () => {
		const { mod, posted } = await loadBridgeWithHandler();
		const teardown = mod.installInboundBridge({});
		try {
			const promise = mod.requestNativeFiles({ accept: "image/*", multiple: true });
			expect(posted).toHaveLength(1);
			const msg = posted[0];
			expect(msg.type).toBe("nativeAttachFile");
			expect(typeof msg.requestId).toBe("string");

			const w = (globalThis as unknown as { window: { __hfchatBridge?: unknown } }).window;
			const inbound = w.__hfchatBridge as
				| { attachFiles: (files: unknown[], requestId?: string) => void }
				| undefined;
			expect(inbound).toBeDefined();

			// File is provided by jsdom/node? In Node test env, File may be missing —
			// stub atob and File via globals.
			if (typeof globalThis.atob === "undefined") {
				vi.stubGlobal("atob", (s: string) => Buffer.from(s, "base64").toString("binary"));
			}
			if (typeof globalThis.File === "undefined") {
				class FakeFile {
					name: string;
					type: string;
					size: number;
					constructor(parts: unknown[], name: string, opts: { type: string }) {
						this.name = name;
						this.type = opts.type;
						const blob = parts[0] as { length?: number };
						this.size = typeof blob?.length === "number" ? blob.length : 0;
					}
				}
				vi.stubGlobal("File", FakeFile as unknown as typeof File);
			}

			inbound?.attachFiles(
				[{ name: "a.png", mime: "image/png", base64: btoa("hi") }],
				msg.requestId
			);
			const files = await promise;
			expect(files).toHaveLength(1);
			expect(files[0].name).toBe("a.png");
			expect(files[0].type).toBe("image/png");
		} finally {
			teardown();
		}
	});

	it("installInboundBridge invokes setActiveModel / navigate / stopGeneration callbacks", async () => {
		const { mod } = await loadBridgeWithHandler();
		const setActiveModel = vi.fn();
		const navigate = vi.fn();
		const stopGeneration = vi.fn();
		const teardown = mod.installInboundBridge({ setActiveModel, navigate, stopGeneration });
		try {
			const w = (
				globalThis as unknown as {
					window: { __hfchatBridge: Record<string, (...args: unknown[]) => void> };
				}
			).window;
			w.__hfchatBridge.setActiveModel("model-id");
			w.__hfchatBridge.navigate("/conversation/abc");
			w.__hfchatBridge.stopGeneration();
			expect(setActiveModel).toHaveBeenCalledWith("model-id");
			expect(navigate).toHaveBeenCalledWith("/conversation/abc");
			expect(stopGeneration).toHaveBeenCalled();
		} finally {
			teardown();
		}
	});

	it("installInboundBridge teardown removes window.__hfchatBridge", async () => {
		const { mod } = await loadBridgeWithHandler();
		const teardown = mod.installInboundBridge({});
		const w = globalThis as unknown as { window: { __hfchatBridge?: unknown } };
		expect(w.window.__hfchatBridge).toBeDefined();
		teardown();
		expect(w.window.__hfchatBridge).toBeUndefined();
	});
});
