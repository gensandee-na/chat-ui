<script lang="ts">
	import ConversationPage from "$lib/components/chat/ConversationPage.svelte";

	let { data = $bindable() } = $props();
</script>

<ConversationPage bind:data />
