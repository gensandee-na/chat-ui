import { base } from "$app/paths";
import { browser } from "$app/environment";
import { apiFetch } from "$lib/utils/apiFetch";

export async function load({ params, parent, fetch }) {
	const fetcher = browser ? apiFetch : fetch;
	await fetcher(`${base}/api/v2/models/${params.model}/subscribe`, {
		method: "POST",
	});

	return {
		settings: await parent().then((data) => ({
			...data.settings,
			activeModel: params.model,
		})),
	};
}
