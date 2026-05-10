<script lang="ts">
	import ConversationPage from "$lib/components/chat/ConversationPage.svelte";
	import { onMount } from "svelte";
	import { page } from "$app/state";
	import { goto, invalidateAll } from "$app/navigation";
	import { base } from "$app/paths";
	import { useSettingsStore } from "$lib/stores/settings.js";
	import { loading } from "$lib/stores/loading";
	import titleUpdate from "$lib/stores/titleUpdate";
	import { native, isNative, installInboundBridge } from "$lib/native/bridge";

	let { data = $bindable() } = $props();

	const settings = useSettingsStore();

	let pageApi: { stopGeneration: () => void; setFiles: (next: File[]) => void } | undefined;

	onMount(() => {
		const teardown = installInboundBridge({
			setFiles: (files) => pageApi?.setFiles(files),
			setActiveModel: async (id) => {
				await settings.instantSet({ activeModel: id });
				await invalidateAll();
			},
			navigate: (path) => {
				const target = path.startsWith(base) ? path : `${base}${path}`;
				goto(target, { invalidateAll: true });
			},
			stopGeneration: () => pageApi?.stopGeneration(),
		});

		native.didLoad(page.params.id ?? "");
		return teardown;
	});

	// Forward title updates so the native nav bar stays in sync.
	$effect(() => {
		if (!isNative) return;
		const t = $titleUpdate;
		if (t) {
			native.didUpdateTitle({ conversationId: t.convId, title: t.title });
		}
	});

	// Bracket generation lifecycle so native can show/hide its stop button and
	// run a haptic on completion.
	let prevLoading = false;
	$effect(() => {
		if (!isNative) return;
		const isLoading = $loading;
		if (isLoading && !prevLoading) {
			native.didStartGeneration({ conversationId: page.params.id ?? "" });
		} else if (!isLoading && prevLoading) {
			native.didEndGeneration({
				conversationId: page.params.id ?? "",
				interrupted: false,
			});
		}
		prevLoading = isLoading;
	});
</script>

<ConversationPage bind:data onReady={(api) => (pageApi = api)} />
