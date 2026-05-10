import { loadLayout } from "$lib/load/layout";
import type { LayoutLoad } from "./$types";

export const load: LayoutLoad = ({ depends, fetch, url }) => loadLayout({ depends, fetch, url });
