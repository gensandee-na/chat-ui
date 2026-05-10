import { useAPIClient, handleResponse } from "$lib/APIClient";
import { UrlDependency } from "$lib/types/UrlDependency";
import { redirect } from "@sveltejs/kit";
import { base } from "$app/paths";
import type { Message } from "$lib/types/Message";

export interface ConversationData {
	messages: Message[];
	title: string;
	model: string;
	preprompt?: string;
	rootMessageId?: string;
	id: string;
	updatedAt: Date;
	modelId: string;
	shared: boolean;
}

interface LoadArgs {
	id: string;
	depends: (...deps: `${string}:${string}`[]) => void;
	fetch: typeof fetch;
	url: URL;
	parent: () => Promise<{ loginEnabled?: boolean; user?: unknown | null }>;
}

/**
 * Shared loader for the canonical and embed conversation routes. Imported by
 * both routes' `+page.ts` so SvelteKit can infer `PageData` correctly for
 * each — re-exporting `load` from another route file does not propagate the
 * return type through `$types` generation. Each call site destructures its
 * own SvelteKit `LoadEvent` and passes the fields here, side-stepping the
 * per-route `RouteId` brand that prevents passing the event directly.
 */
export async function loadConversation(args: LoadArgs): Promise<ConversationData> {
	const { id, depends, fetch, url, parent } = args;
	depends(UrlDependency.Conversation);

	const client = useAPIClient({ fetch, origin: url.origin });

	// Handle share import for logged-in users (7-char IDs are share IDs)
	if (id.length === 7) {
		const parentData = await parent();

		if (parentData.loginEnabled && parentData.user) {
			const leafId = url.searchParams.get("leafId");

			let importedConversationId: string | undefined;
			try {
				const result = await client.conversations["import-share"]
					.post({ shareId: id })
					.then(handleResponse);
				importedConversationId = result.conversationId;
			} catch {
				// Import failed, continue to load shared conversation for viewing
			}

			if (importedConversationId) {
				redirect(
					302,
					`${base}/conversation/${importedConversationId}?leafId=${leafId ?? ""}&fromShare=${id}`
				);
			}
		}
	}

	// Load conversation (works for both owned and shared conversations)
	try {
		return (await client
			.conversations({ id })
			.get({ query: { fromShare: url.searchParams.get("fromShare") ?? undefined } })
			.then(handleResponse)) as ConversationData;
	} catch {
		redirect(302, `${base}/`);
	}
}
