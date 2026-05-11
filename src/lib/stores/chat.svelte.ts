// src/lib/stores/chat.svelte.ts
export function createChatStore(initialMessages = []) {
	let messages = $state(initialMessages);
	let isLoading = $state(false);
	let error = $state(null);

	const sendMessage = async (content: string, model?: string) => {
		if (!content.trim()) return;

		isLoading = true;
		error = null;

		// Add user message
		messages.push({
			role: 'user',
			content,
			timestamp: new Date()
		});

		try {
			// TODO: Call your actual API here (OpenAI compatible)
			// Example placeholder
			const response = await fetch('/api/chat', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ messages: [...messages], model })
			});

			const data = await response.json();

			messages.push({
				role: 'assistant',
				content: data.response || 'Sorry, I could not process that.',
				timestamp: new Date()
			});
		} catch (err) {
			error = err.message;
			console.error(err);
		} finally {
			isLoading = false;
		}
	};

	const clearMessages = () => {
		messages = [];
	};

	return {
		get messages() { return messages; },
		get isLoading() { return isLoading; },
		get error() { return error; },
		sendMessage,
		clearMessages
	};
}
