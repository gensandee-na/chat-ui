<script lang="ts">
	import "../../styles/main.css";

	import { setContext } from "svelte";
	import { onDestroy, onMount, untrack } from "svelte";
	import { goto } from "$app/navigation";
	import { base } from "$app/paths";
	import { page } from "$app/state";

	import { error } from "$lib/stores/errors";
	import { createSettingsStore } from "$lib/stores/settings";
	import { setHapticsEnabled } from "$lib/utils/haptics";

	import Toast from "$lib/components/Toast.svelte";
	import BackgroundGenerationPoller from "$lib/components/BackgroundGenerationPoller.svelte";
	import { isAborted } from "$lib/stores/isAborted";
	import { native, isNative } from "$lib/native/bridge";

	let { data, children } = $props();

	// publicConfig is loaded once and never replaced — capturing the initial
	// value via context is intentional, matching `src/routes/+layout.svelte`.
	// svelte-ignore state_referenced_locally
	setContext("publicConfig", data.publicConfig);

	// svelte-ignore state_referenced_locally
	const settings = createSettingsStore(data.settings);

	let errorToastTimeout: ReturnType<typeof setTimeout>;
	let currentError: string | undefined = $state();

	async function onError() {
		if ($error && currentError && $error !== currentError) {
			clearTimeout(errorToastTimeout);
			currentError = undefined;
			await new Promise((resolve) => setTimeout(resolve, 300));
		}
		currentError = $error;
		errorToastTimeout = setTimeout(() => {
			$error = undefined;
			currentError = undefined;
		}, 5000);
	}

	$effect(() => {
		if ($error) onError();
	});

	$effect(() => {
		setHapticsEnabled($settings.hapticsEnabled);
	});

	onDestroy(() => {
		clearTimeout(errorToastTimeout);
	});

	onMount(() => {
		// Apply theme override from the native host on first paint
		const theme = page.url.searchParams.get("theme");
		if (theme === "dark" || theme === "light") {
			document.documentElement.classList.toggle("dark", theme === "dark");
		}

		// Cmd/Ctrl+Shift+O = new chat (matches global layout shortcut). Useful
		// for hardware keyboards on iPad.
		const onKeydown = (e: KeyboardEvent) => {
			const oPressed = e.key?.toLowerCase() === "o";
			const metaOrCtrl = e.metaKey || e.ctrlKey;
			if (oPressed && e.shiftKey && metaOrCtrl) {
				e.preventDefault();
				isAborted.set(true);
				if (isNative) {
					native.requestNewConversation();
				} else {
					goto(`${base}/`, { invalidateAll: true });
				}
			}
		};
		window.addEventListener("keydown", onKeydown, { capture: true });
		return () => window.removeEventListener("keydown", onKeydown, { capture: true });
	});

	// Suppress unused warning while keeping the module-side untrack import in sync
	// with the canonical layout (so future merges stay clean).
	void untrack;
</script>

<svelte:head>
	<title>{data.publicConfig.PUBLIC_APP_NAME}</title>
</svelte:head>

<BackgroundGenerationPoller />

<div class="embed-root flex min-h-dvh w-screen flex-col bg-transparent text-smd dark:text-gray-300">
	{@render children?.()}
</div>

{#if currentError}
	<Toast message={currentError} />
{/if}

<style>
	:global(:root) {
		--safe-top: env(safe-area-inset-top, 0px);
		--safe-bottom: env(safe-area-inset-bottom, 0px);
	}

	:global(html, body) {
		overscroll-behavior: none;
		-webkit-touch-callout: none;
	}

	:global(body.embed-host) {
		background: transparent;
	}

	.embed-root {
		padding-top: var(--safe-top);
		padding-bottom: var(--safe-bottom);
	}
</style>
