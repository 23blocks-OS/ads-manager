import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import Anthropic from '@anthropic-ai/sdk';

@Injectable()
export class AiEngineService {
  private openai: OpenAI;
  private anthropic: Anthropic;

  constructor(private configService: ConfigService) {
    const openaiKey = this.configService.get('OPENAI_API_KEY');
    const anthropicKey = this.configService.get('ANTHROPIC_API_KEY');

    if (openaiKey) {
      this.openai = new OpenAI({ apiKey: openaiKey });
    }

    if (anthropicKey) {
      this.anthropic = new Anthropic({ apiKey: anthropicKey });
    }
  }

  async generateCompletion(
    prompt: string,
    options?: {
      model?: 'gpt-4' | 'gpt-3.5-turbo' | 'claude-3-opus' | 'claude-3-sonnet';
      temperature?: number;
      maxTokens?: number;
    },
  ): Promise<string> {
    const { model = 'gpt-4', temperature = 0.7, maxTokens = 2000 } = options || {};

    if (model.startsWith('claude')) {
      return this.generateClaudeCompletion(prompt, model, temperature, maxTokens);
    } else {
      return this.generateOpenAICompletion(prompt, model, temperature, maxTokens);
    }
  }

  private async generateOpenAICompletion(
    prompt: string,
    model: string,
    temperature: number,
    maxTokens: number,
  ): Promise<string> {
    const response = await this.openai.chat.completions.create({
      model,
      messages: [{ role: 'user', content: prompt }],
      temperature,
      max_tokens: maxTokens,
    });

    return response.choices[0].message.content || '';
  }

  private async generateClaudeCompletion(
    prompt: string,
    model: string,
    temperature: number,
    maxTokens: number,
  ): Promise<string> {
    const response = await this.anthropic.messages.create({
      model: model === 'claude-3-opus' ? 'claude-3-opus-20240229' : 'claude-3-sonnet-20240229',
      max_tokens: maxTokens,
      temperature,
      messages: [{ role: 'user', content: prompt }],
    });

    const content = response.content[0];
    return content.type === 'text' ? content.text : '';
  }

  async generateStructuredResponse<T>(
    prompt: string,
    schema: string,
    options?: {
      model?: 'gpt-4' | 'gpt-3.5-turbo';
      temperature?: number;
    },
  ): Promise<T> {
    const { model = 'gpt-4', temperature = 0.7 } = options || {};

    const enhancedPrompt = `${prompt}\n\nRespond with a JSON object matching this schema:\n${schema}\n\nRespond only with valid JSON, no other text.`;

    const response = await this.openai.chat.completions.create({
      model,
      messages: [{ role: 'user', content: enhancedPrompt }],
      temperature,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0].message.content || '{}';
    return JSON.parse(content) as T;
  }

  async analyzeSentiment(text: string): Promise<{
    score: number;
    sentiment: 'positive' | 'negative' | 'neutral';
    confidence: number;
  }> {
    const prompt = `Analyze the sentiment of this text and respond with a JSON object:

Text: "${text}"

Respond with this exact JSON structure:
{
  "score": <number between -1 and 1>,
  "sentiment": "<positive|negative|neutral>",
  "confidence": <number between 0 and 1>
}`;

    return this.generateStructuredResponse(prompt, '');
  }

  async extractKeywords(text: string, count: number = 10): Promise<string[]> {
    const prompt = `Extract the ${count} most important keywords from this text:

"${text}"

Respond with a JSON array of keywords: ["keyword1", "keyword2", ...]`;

    const response = await this.generateStructuredResponse<{ keywords: string[] }>(
      prompt,
      '',
    );

    return response.keywords || [];
  }

  async generateImage(prompt: string, size: '1024x1024' | '512x512' = '1024x1024'): Promise<string> {
    const response = await this.openai.images.generate({
      model: 'dall-e-3',
      prompt,
      n: 1,
      size,
    });

    return response.data[0].url || '';
  }
}
