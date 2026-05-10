import { loadConversation } from "$lib/load/conversation";
import type { PageLoad } from "./$types";

// Mirror of the canonical loader. SvelteKit's `PageData` is inferred from this
// `load` function, so we call the shared helper inline rather than
// re-exporting it.
export const load: PageLoad = ({ params, depends, fetch, url, parent }) =>
	loadConversation({ id: params.id, depends, fetch, url, parent });
