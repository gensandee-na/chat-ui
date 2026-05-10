/**
 * Bridge between the SvelteKit web UI and a host native iOS app (WKWebView).
 *
 * The web bundle is identical for browser and native; `isNative` flips to
 * `true` only when running inside a WKWebView whose configuration installs a
 * message handler named `hfchat`. All helpers below are safe no-ops outside
 * that context.
 *
 * Native -> Web is wired by attaching a small object on `window.__hfchatBridge`
 * (see `installInboundBridge`). Native injects `evaluateJavaScript` calls that
 * invoke methods on it.
 */

export interface NativeAttachFile {
	name: string;
	mime: string;
	base64: string;
}

export interface NativeShareArgs {
	conversationId: string;
}

export interface NativeAttachArgs {
	accept: string;
	multiple: boolean;
}

export interface NativeOpenSettingsArgs {
	tab?: string;
}

export interface NativeOpenModelPickerArgs {
	currentModelId?: string;
}

export interface NativeOpenLoginArgs {
	next?: string;
}

export interface NativeHapticArgs {
	style: "selection" | "impact" | "success" | "error";
}

export interface WebDidUpdateTitleArgs {
	conversationId: string;
	title: string;
}

export interface WebDidStartGenerationArgs {
	conversationId: string;
}

export interface WebDidEndGenerationArgs {
	conversationId: string;
	interrupted: boolean;
}

export interface WebErrorArgs {
	message: string;
	statusCode?: number;
}

type Outbound =
	| { type: "nativeShare"; args: NativeShareArgs }
	| { type: "nativeAttachFile"; args: NativeAttachArgs; requestId: string }
	| { type: "nativeOpenSettings"; args: NativeOpenSettingsArgs }
	| { type: "nativeOpenModelPicker"; args: NativeOpenModelPickerArgs }
	| { type: "nativeOpenLogin"; args: NativeOpenLoginArgs }
	| { type: "nativeHaptic"; args: NativeHapticArgs }
	| { type: "webDidLoad"; args: { conversationId: string } }
	| { type: "webDidUpdateTitle"; args: WebDidUpdateTitleArgs }
	| { type: "webDidStartGeneration"; args: WebDidStartGenerationArgs }
	| { type: "webDidEndGeneration"; args: WebDidEndGenerationArgs }
	| { type: "webRequestNewConversation"; args: { modelId?: string } }
	| { type: "webError"; args: WebErrorArgs };

interface InboundBridge {
	attachFiles: (files: NativeAttachFile[], requestId?: string) => void;
	setActiveModel: (id: string) => void;
	navigate: (path: string) => void;
	theme: (mode: "dark" | "light") => void;
	stopGeneration: () => void;
	injectAuthCookie: (value: string) => void;
}

interface WebkitWindow extends Window {
	webkit?: {
		messageHandlers?: Record<string, { postMessage: (message: unknown) => void }>;
	};
	__hfchatBridge?: InboundBridge;
}

const HANDLER_NAME = "hfchat";

function getHandler(): { postMessage: (message: unknown) => void } | undefined {
	if (typeof window === "undefined") return undefined;
	const w = window as WebkitWindow;
	return w.webkit?.messageHandlers?.[HANDLER_NAME];
}

export const isNative: boolean = !!getHandler();

function postMessage(message: Outbound): void {
	const handler = getHandler();
	if (!handler) return;
	try {
		handler.postMessage(message);
	} catch (err) {
		console.warn("[hfchat-bridge] failed to post message", err);
	}
}

/**
 * Outbound helpers (Web -> Native).
 *
 * They unconditionally short-circuit when no handler is registered, so calling
 * sites can branch on `isNative` only when they need a different fallback path
 * (e.g. opening a native picker vs. the web file input).
 */
export const native = {
	share(args: NativeShareArgs) {
		postMessage({ type: "nativeShare", args });
	},
	openSettings(args: NativeOpenSettingsArgs = {}) {
		postMessage({ type: "nativeOpenSettings", args });
	},
	openModelPicker(args: NativeOpenModelPickerArgs = {}) {
		postMessage({ type: "nativeOpenModelPicker", args });
	},
	openLogin(args: NativeOpenLoginArgs = {}) {
		postMessage({ type: "nativeOpenLogin", args });
	},
	haptic(args: NativeHapticArgs) {
		postMessage({ type: "nativeHaptic", args });
	},
	didLoad(conversationId: string) {
		postMessage({ type: "webDidLoad", args: { conversationId } });
	},
	didUpdateTitle(args: WebDidUpdateTitleArgs) {
		postMessage({ type: "webDidUpdateTitle", args });
	},
	didStartGeneration(args: WebDidStartGenerationArgs) {
		postMessage({ type: "webDidStartGeneration", args });
	},
	didEndGeneration(args: WebDidEndGenerationArgs) {
		postMessage({ type: "webDidEndGeneration", args });
	},
	requestNewConversation(modelId?: string) {
		postMessage({ type: "webRequestNewConversation", args: { modelId } });
	},
	error(args: WebErrorArgs) {
		postMessage({ type: "webError", args });
	},
};

/**
 * Request the native host to present a file picker and return a list of
 * picked files, decoded as `File` objects ready to drop into the existing
 * upload flow (`file2base64`). Rejects if the native host isn't available.
 */
let nextRequestId = 0;
const pendingAttach = new Map<string, (files: File[]) => void>();

export function requestNativeFiles(args: NativeAttachArgs): Promise<File[]> {
	if (!isNative) {
		return Promise.reject(new Error("native bridge not available"));
	}
	const requestId = `attach-${++nextRequestId}`;
	return new Promise<File[]>((resolve) => {
		pendingAttach.set(requestId, resolve);
		postMessage({ type: "nativeAttachFile", args, requestId });
	});
}

function decodeAttachment(att: NativeAttachFile): File {
	const binary = atob(att.base64);
	const bytes = new Uint8Array(binary.length);
	for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
	return new File([bytes], att.name, { type: att.mime });
}

interface InstallOptions {
	setFiles?: (files: File[]) => void;
	setActiveModel?: (id: string) => Promise<void> | void;
	navigate?: (path: string) => void;
	stopGeneration?: () => void;
}

/**
 * Mount the inbound side of the bridge. Should be called from `onMount` in the
 * embed conversation page so native can push files / model changes / theme
 * into the live page.
 *
 * Returns a teardown function.
 */
export function installInboundBridge(opts: InstallOptions): () => void {
	if (typeof window === "undefined") return () => {};
	const w = window as WebkitWindow;

	const bridge: InboundBridge = {
		attachFiles(attachments, requestId) {
			const files = attachments.map(decodeAttachment);
			if (requestId && pendingAttach.has(requestId)) {
				pendingAttach.get(requestId)?.(files);
				pendingAttach.delete(requestId);
			} else if (opts.setFiles) {
				opts.setFiles(files);
			}
		},
		setActiveModel(id) {
			void opts.setActiveModel?.(id);
		},
		navigate(path) {
			opts.navigate?.(path);
		},
		theme(mode) {
			if (typeof document === "undefined") return;
			document.documentElement.classList.toggle("dark", mode === "dark");
		},
		stopGeneration() {
			opts.stopGeneration?.();
		},
		injectAuthCookie(value) {
			// Cookies set by the native side via WKHTTPCookieStore are already
			// visible to the WebView. This is a fallback for cases where native
			// missed the sync window (e.g. initial sign-in race).
			if (typeof document !== "undefined") {
				document.cookie = value;
			}
		},
	};

	w.__hfchatBridge = bridge;
	return () => {
		if (w.__hfchatBridge === bridge) delete w.__hfchatBridge;
	};
}
