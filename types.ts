export interface JobResult {
  id: number;
  uiReply: string;
  backendReply: string;
  timestamp: string;
}

export interface ChatCompletionResponse {
  choices: Array<{
    message: {
      role: string;
      content: string;
    };
  }>;
}
