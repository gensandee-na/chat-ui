import { writable, get } from "svelte/store";
import { browser } from "$app/environment";
import { env as publicEnv } from "$env/dynamic/public";

function toKeyPart(s: string | undefined): string {
	return (s || "").toLowerCase().replace(/[^a-z0-9_-]+/g, "-");
}

const KEY_PREFIX = toKeyPart(publicEnv.PUBLIC_APP_ASSETS || publicEnv.PUBLIC_APP_NAME) || "app";
const STORAGE_KEY = `${KEY_PREFIX}:auth-token`;

function load(): string | null {
	if (!browser) return null;
	try {
		return localStorage.getItem(STORAGE_KEY);
	} catch {
		return null;
	}
}

const store = writable<string | null>(load());

export const authToken = {
	subscribe: store.subscribe,
	get(): string | null {
		return get(store);
	},
	set(token: string) {
		const trimmed = token.trim();
		if (!trimmed) {
			return this.clear();
		}
		if (browser) {
			try {
				localStorage.setItem(STORAGE_KEY, trimmed);
			} catch {
				// ignore storage failures
			}
		}
		store.set(trimmed);
	},
	clear() {
		if (browser) {
			try {
				localStorage.removeItem(STORAGE_KEY);
			} catch {
				// ignore storage failures
			}
		}
		store.set(null);
	},
};
