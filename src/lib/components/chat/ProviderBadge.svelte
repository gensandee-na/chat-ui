<script lang="ts">
	import { Select } from "bits-ui";
	import { PROVIDERS_HUB_ORGS } from "@huggingface/inference";
	import IconFast from "$lib/components/icons/IconFast.svelte";
	import IconCheap from "$lib/components/icons/IconCheap.svelte";
	import CarbonMagicWandFilled from "~icons/carbon/magic-wand-filled";
	import CarbonChevronDown from "~icons/carbon/chevron-down";
	import LucideCheck from "~icons/lucide/check";
	import { useSettingsStore } from "$lib/stores/settings";
	import { usePublicConfig } from "$lib/utils/PublicConfig.svelte";
	import type { Model } from "$lib/types/Model";

	interface Props {
		currentModel?: Model;
	}

	let { currentModel }: Props = $props();

	const settings = useSettingsStore();
	const publicConfig = usePublicConfig();

	type RouterProvider = { provider: string } & Record<string, unknown>;

	const PROVIDER_POLICIES = [
		{ value: "auto", shortLabel: "Auto", label: "Auto (your HF preference order)" },
		{ value: "fastest", shortLabel: "Fastest", label: "Fastest (highest throughput)" },
		{ value: "cheapest", shortLabel: "Cheapest", label: "Cheapest (lowest cost)" },
	] as const;

	let modelId = $derived(currentModel?.id ?? "");
	let providerList = $derived((currentModel?.providers ?? []) as RouterProvider[]);
	let currentValue = $derived($settings.providerOverrides?.[modelId] ?? "auto");
	let currentProvider = $derived(providerList.find((p) => p.provider === currentValue));
	let currentPolicy = $derived(PROVIDER_POLICIES.find((p) => p.value === currentValue));
	let triggerLabel = $derived(
		currentPolicy?.shortLabel ?? currentProvider?.provider ?? currentValue
	);

	let visible = $derived(
		!!currentModel &&
			publicConfig.isHuggingChat &&
			!currentModel.isRouter &&
			(currentModel.providers?.length ?? 0) > 0
	);

	// Auto-mode composition: up to 6 provider micro-avatars packed inside the same
	// 14×14 box that the magic-wand fills. Layouts hand-tuned for visual balance.
	type Slot = { x: number; y: number; w: number; h: number };
	const COMPOSITION_LAYOUTS: Record<number, Slot[]> = {
		1: [{ x: 0, y: 0, w: 14, h: 14 }],
		2: [
			{ x: 0, y: 4, w: 6, h: 6 },
			{ x: 8, y: 4, w: 6, h: 6 },
		],
		3: [
			{ x: 4, y: 0, w: 6, h: 6 },
			{ x: 0, y: 8, w: 6, h: 6 },
			{ x: 8, y: 8, w: 6, h: 6 },
		],
		4: [
			{ x: 0, y: 0, w: 6, h: 6 },
			{ x: 8, y: 0, w: 6, h: 6 },
			{ x: 0, y: 8, w: 6, h: 6 },
			{ x: 8, y: 8, w: 6, h: 6 },
		],
		5: [
			{ x: 0, y: 1, w: 4, h: 4 },
			{ x: 5, y: 1, w: 4, h: 4 },
			{ x: 10, y: 1, w: 4, h: 4 },
			{ x: 3, y: 9, w: 4, h: 4 },
			{ x: 7, y: 9, w: 4, h: 4 },
		],
		6: [
			{ x: 0, y: 1, w: 4, h: 4 },
			{ x: 5, y: 1, w: 4, h: 4 },
			{ x: 10, y: 1, w: 4, h: 4 },
			{ x: 0, y: 9, w: 4, h: 4 },
			{ x: 5, y: 9, w: 4, h: 4 },
			{ x: 10, y: 9, w: 4, h: 4 },
		],
	};

	let compositionProviders = $derived(providerList.slice(0, 6));
	let compositionLayout = $derived(
		COMPOSITION_LAYOUTS[Math.min(compositionProviders.length, 6)] ?? []
	);

	function setProvider(v: string) {
		settings.update((s) => ({
			...s,
			providerOverrides: { ...s.providerOverrides, [modelId]: v },
		}));
	}
</script>

{#if visible}
	<Select.Root type="single" value={currentValue} onValueChange={(v) => v && setProvider(v)}>
		<Select.Trigger
			aria-label="Select inference provider"
			title="Inference provider"
			class="ml-1.5 inline-flex h-8 items-center gap-1.5 rounded-full border border-gray-200 pl-2 pr-2 text-xs font-normal text-gray-600 transition-colors hover:bg-gray-100 hover:text-gray-800 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-gray-100 dark:hover:bg-gray-600 sm:h-7"
		>
			{#if currentValue === "auto"}
				{#if compositionLayout.length === 0}
					<CarbonMagicWandFilled class="size-3.5 text-gray-600 dark:text-gray-300" />
				{:else}
					<span class="relative size-3.5 flex-none" aria-hidden="true">
						{#each compositionLayout as slot, i (compositionProviders[i].provider)}
							{@const hubOrg =
								PROVIDERS_HUB_ORGS[
									compositionProviders[i].provider as keyof typeof PROVIDERS_HUB_ORGS
								]}
							{#if hubOrg}
								<img
									src="https://huggingface.co/api/avatars/{hubOrg}"
									alt=""
									class="absolute rounded-[1px] bg-white object-cover ring-1 ring-black/5 dark:bg-gray-900 dark:ring-white/10"
									style:left="{slot.x}px"
									style:top="{slot.y}px"
									style:width="{slot.w}px"
									style:height="{slot.h}px"
								/>
							{:else}
								<span
									class="absolute rounded-[1px] bg-gray-300 dark:bg-gray-600"
									style:left="{slot.x}px"
									style:top="{slot.y}px"
									style:width="{slot.w}px"
									style:height="{slot.h}px"
								></span>
							{/if}
						{/each}
					</span>
				{/if}
			{:else if currentValue === "fastest"}
				<IconFast classNames="size-3.5" />
			{:else if currentValue === "cheapest"}
				<IconCheap classNames="size-3.5" />
			{:else}
				{@const hubOrg = PROVIDERS_HUB_ORGS[currentValue as keyof typeof PROVIDERS_HUB_ORGS]}
				{#if hubOrg}
					<img
						src="https://huggingface.co/api/avatars/{hubOrg}"
						alt=""
						class="size-4 rounded bg-white p-px shadow-sm ring-1 ring-black/5 dark:bg-gray-900 dark:ring-white/10"
					/>
				{/if}
			{/if}
			<span class="leading-none">{triggerLabel}</span>
			<CarbonChevronDown class="size-3 opacity-80" />
		</Select.Trigger>
		<Select.Portal>
			<Select.Content
				class="scrollbar-custom z-50 max-h-72 overflow-y-auto rounded-xl border border-gray-200 bg-white/95 p-1 shadow-lg backdrop-blur dark:border-gray-700 dark:bg-gray-800/95"
				side="top"
				sideOffset={8}
				align="start"
			>
				<Select.Group>
					<Select.GroupHeading
						class="px-2 py-1.5 text-xs font-medium text-gray-500 dark:text-gray-400"
					>
						Selection mode
					</Select.GroupHeading>
					{#each PROVIDER_POLICIES as opt (opt.value)}
						<Select.Item
							value={opt.value}
							class="flex cursor-pointer select-none items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-gray-700 outline-none data-[highlighted]:bg-gray-100 dark:text-gray-200 dark:data-[highlighted]:bg-white/10"
						>
							{#if opt.value === "auto"}
								<span class="grid size-5 flex-none place-items-center rounded-md bg-gray-500/10">
									<CarbonMagicWandFilled class="size-3 text-gray-700 dark:text-gray-300" />
								</span>
							{:else if opt.value === "fastest"}
								<span
									class="grid size-5 flex-none place-items-center rounded-md bg-green-500/10 text-green-600 dark:text-green-500"
								>
									<IconFast classNames="size-3" />
								</span>
							{:else if opt.value === "cheapest"}
								<span
									class="grid size-5 flex-none place-items-center rounded-md bg-blue-500/10 text-blue-600 dark:text-blue-500"
								>
									<IconCheap classNames="size-3" />
								</span>
							{/if}
							<span class="flex-1">{opt.label}</span>
							{#if currentValue === opt.value}
								<LucideCheck class="size-4 text-gray-500" />
							{/if}
						</Select.Item>
					{/each}
				</Select.Group>
				<div class="my-1 h-px bg-gray-200 dark:bg-gray-700"></div>
				<Select.Group>
					<Select.GroupHeading
						class="px-2 py-1.5 text-xs font-medium text-gray-500 dark:text-gray-400"
					>
						Specific provider
					</Select.GroupHeading>
					{#each providerList as prov (prov.provider)}
						{@const hubOrg = PROVIDERS_HUB_ORGS[prov.provider as keyof typeof PROVIDERS_HUB_ORGS]}
						<Select.Item
							value={prov.provider}
							class="flex cursor-pointer select-none items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-gray-700 outline-none data-[highlighted]:bg-gray-100 dark:text-gray-200 dark:data-[highlighted]:bg-white/10"
						>
							{#if hubOrg}
								<span
									class="flex size-5 flex-none items-center justify-center rounded-md bg-gray-500/10 p-0.5"
								>
									<img
										src="https://huggingface.co/api/avatars/{hubOrg}"
										alt=""
										class="size-full rounded"
									/>
								</span>
							{:else}
								<span class="size-5"></span>
							{/if}
							<span class="flex-1">{prov.provider}</span>
							{#if currentValue === prov.provider}
								<LucideCheck class="size-4 text-gray-500" />
							{/if}
						</Select.Item>
					{/each}
				</Select.Group>
			</Select.Content>
		</Select.Portal>
	</Select.Root>
{/if}
