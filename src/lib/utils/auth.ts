import { goto } from "$app/navigation";
import { base } from "$app/paths";
import { page } from "$app/state";
import { isNative, native } from "$lib/native/bridge";

/**
 * Redirects to the login page if the user is not authenticated
 * and the login feature is enabled.
 *
 * In native (WKWebView) mode, hands the request off to the host app via the
 * native bridge — `/login` performs an OAuth redirect that the WKWebView
 * shouldn't try to follow itself; the native side opens
 * `ASWebAuthenticationSession` instead.
 */
export function requireAuthUser(): boolean {
	if (page.data.loginEnabled && !page.data.user) {
		const next = page.url.pathname + page.url.search;
		if (isNative) {
			native.openLogin({ next });
		} else {
			const url = `${base}/login?next=${encodeURIComponent(next)}`;
			goto(url, { invalidateAll: true });
		}
		return true;
	}
	return false;
}
