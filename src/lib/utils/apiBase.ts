import { PUBLIC_API_BASE_URL } from "$env/static/public";

// Empty string ⇒ web build (relative URLs, current behavior).
// Non-empty ⇒ Capacitor/native build pointed at a remote backend (e.g. https://huggingface.co/chat).
export const apiOrigin: string = PUBLIC_API_BASE_URL ?? "";
export const isCapacitorBuild: boolean = apiOrigin !== "";
