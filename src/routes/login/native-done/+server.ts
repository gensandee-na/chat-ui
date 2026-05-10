/**
 * Bounce target for the native iOS app's ASWebAuthenticationSession.
 *
 * The OAuth/OIDC dance lands on `/login/callback`, which sets the `hf-chat`
 * session cookie via `updateUser` and then redirects to a safe relative path.
 * When the iOS app opens the login flow it passes `?next=/login/native-done`
 * so this route is the redirect target.
 *
 * We then issue a meta-refresh to a custom URL scheme (`hf-chat://auth-done`),
 * which fires the `ASWebAuthenticationSession` completion handler. The native
 * side can then read the session cookie out of the system cookie store and
 * mirror it into `WKWebsiteDataStore.default().httpCookieStore`.
 *
 * No state is set here: the cookie is already written by the upstream callback.
 */

const HTML = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <title>Signed in</title>
  <meta http-equiv="refresh" content="0;url=hf-chat://auth-done" />
  <style>
    html, body { margin: 0; height: 100%; background: #0b0b0b; color: #f5f5f5; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    main { display: flex; align-items: center; justify-content: center; height: 100%; flex-direction: column; gap: 1rem; }
    a { color: #f5f5f5; }
  </style>
</head>
<body>
  <main>
    <p>Signed in. Returning to the app…</p>
    <p><a href="hf-chat://auth-done">Tap here if nothing happens</a></p>
  </main>
  <script>
    // Belt-and-suspenders: also try a JS redirect in case the meta-refresh is
    // intercepted by a browser policy.
    window.location.replace("hf-chat://auth-done");
  </script>
</body>
</html>`;

export function GET() {
	return new Response(HTML, {
		status: 200,
		headers: {
			"Content-Type": "text/html; charset=utf-8",
			"Cache-Control": "no-store",
			"X-Robots-Tag": "noindex",
		},
	});
}
