import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
	appId: "co.huggingface.chat",
	appName: "HuggingChat",
	webDir: "build",
	server: {
		androidScheme: "https",
	},
};

export default config;
