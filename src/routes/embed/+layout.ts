import { loadLayout } from "$lib/load/layout";
import type { LayoutLoad } from "./$types";

// Mirror of the root layout loader. SvelteKit infers `LayoutData` from this
// file's `load` function — calling the shared helper here (rather than
// re-exporting) preserves the return type so embed pages see the same data
// shape as the canonical web layout.
export const load: LayoutLoad = ({ depends, fetch, url }) => loadLayout({ depends, fetch, url });
