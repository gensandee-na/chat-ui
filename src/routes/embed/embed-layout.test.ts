import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));

/**
 * Regression guard: the embed layout MUST NOT pull in the global navigation
 * chrome (NavMenu, MobileNav, ExpandNavigation, share button) — those are the
 * web-only chrome that the native iOS shell replaces. If someone accidentally
 * imports them here, the WKWebView will render duplicate UI and clip oddly
 * under the native tab bar.
 *
 * If this test fails, do not edit the assertions to make it pass: instead,
 * remove the offending imports from `(embed)/+layout.svelte` and rely on the
 * native host (or the canonical web layout, for the non-embed routes).
 */
describe("embed layout chrome", () => {
	const layoutSource = readFileSync(join(here, "+layout@.svelte"), "utf8");

	it("does not import NavMenu", () => {
		expect(layoutSource).not.toMatch(/NavMenu\.svelte/);
		expect(layoutSource).not.toMatch(/import\s+NavMenu/);
	});

	it("does not import MobileNav", () => {
		expect(layoutSource).not.toMatch(/MobileNav\.svelte/);
		expect(layoutSource).not.toMatch(/import\s+MobileNav/);
	});

	it("does not import ExpandNavigation", () => {
		expect(layoutSource).not.toMatch(/ExpandNavigation\.svelte/);
	});

	it("does not render the canonical share button", () => {
		expect(layoutSource).not.toMatch(/IconShare/);
		expect(layoutSource).not.toMatch(/shareModal\.open\(\)/);
	});

	it("keeps BackgroundGenerationPoller mounted (so streaming survives navigation)", () => {
		expect(layoutSource).toMatch(/<BackgroundGenerationPoller/);
	});

	it("imports the native bridge for theme + new-chat handoff", () => {
		expect(layoutSource).toMatch(/\$lib\/native\/bridge/);
	});
});

describe("embed conversation page", () => {
	const pageSource = readFileSync(join(here, "conversation/[id]/+page.svelte"), "utf8");

	it("delegates to the shared ConversationPage component", () => {
		expect(pageSource).toMatch(/ConversationPage/);
	});

	it("wires the inbound bridge so native can push files / model changes", () => {
		expect(pageSource).toMatch(/installInboundBridge/);
	});
});
