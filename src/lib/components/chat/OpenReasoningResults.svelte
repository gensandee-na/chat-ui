<script lang="ts">
	import MarkdownRenderer from "./MarkdownRenderer.svelte";
	import BlockWrapper from "./BlockWrapper.svelte";
	import CarbonChevronRight from "~icons/carbon/chevron-right";

	interface Props {
		content: string;
		loading?: boolean;
	}

	let { content, loading = false }: Props = $props();
	let isOpen = $state(false);
	let wasLoading = $state(false);
	let initialized = $state(false);
	let userToggled = $state(false);

	// Track loading transitions to auto-expand/collapse
	$effect(() => {
		if (!initialized) {
			initialized = true;
			if (loading) {
				isOpen = true;
				wasLoading = true;
				return;
			}
		}

		if (loading && !wasLoading) {
			isOpen = true;
			userToggled = false;
		} else if (!loading && wasLoading) {
			isOpen = false;
			userToggled = false;
		}
		wasLoading = loading;
	});

	// While streaming, show only the trailing portion of the trace so the user
	// sees the model's "current thought" rather than the full ever-growing trace.
	// Open thinking models (DeepSeek-R1, QwQ, Qwen3-Thinking, gpt-oss, etc.)
	// consistently separate thoughts with blank lines, so splitting on /\n\s*\n/
	// reliably isolates the last paragraph. We then enforce a soft min/max:
	// extend backwards into prior paragraphs if the tail is too short to read,
	// and slice to a trailing word boundary if it has grown too long.
	const MIN_TAIL_CHARS = 120;
	const MAX_TAIL_CHARS = 800;

	function lastParagraph(text: string): string {
		const paragraphs = text.split(/\n\s*\n/);
		let tail = paragraphs[paragraphs.length - 1] ?? "";
		for (let i = paragraphs.length - 2; i >= 0 && tail.trim().length < MIN_TAIL_CHARS; i--) {
			tail = paragraphs[i] + "\n\n" + tail;
		}
		if (tail.length > MAX_TAIL_CHARS) {
			const sliced = tail.slice(tail.length - MAX_TAIL_CHARS);
			const wordBreak = sliced.search(/\s/);
			tail = (wordBreak > 0 ? sliced.slice(wordBreak + 1) : sliced).trimStart();
		}
		return tail;
	}

	const displayContent = $derived(
		loading && !userToggled ? lastParagraph(content ?? "") : content
	);
</script>

<BlockWrapper>
	<!-- Header row -->
	<button
		type="button"
		class="group/header flex w-fit cursor-pointer select-none items-center gap-1 text-left focus:outline-none"
		onclick={() => {
			isOpen = !isOpen;
			userToggled = true;
		}}
		aria-label={isOpen ? "Collapse" : "Expand"}
	>
		<span
			class="text-sm font-medium transition-colors group-hover/header:text-gray-600 dark:group-hover/header:text-gray-300 {isOpen
				? 'text-gray-600 dark:text-gray-300'
				: 'text-gray-500 dark:text-gray-400'}"
			class:router-shimmer={loading}
		>
			Thinking
		</span>
		<CarbonChevronRight
			class="size-3.5 transition-all duration-200 group-hover/header:text-gray-600 dark:group-hover/header:text-gray-300 {isOpen
				? 'rotate-90 text-gray-600 dark:text-gray-300'
				: 'text-gray-400'}"
		/>
	</button>

	<!-- Expandable content -->
	{#if isOpen}
		<div
			class="prose prose-sm mt-2 max-w-none text-sm leading-relaxed text-gray-500 dark:prose-invert dark:text-gray-400"
		>
			<MarkdownRenderer content={displayContent} {loading} />
		</div>
	{/if}
</BlockWrapper>
