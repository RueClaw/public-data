# ChatGPT Prompts Library

> **Source:** [pacholoamit/chatgpt-prompts](https://github.com/pacholoamit/chatgpt-prompts)
> **License:** MIT
> **Description:** Collection of 140+ curated prompts for GPT models. Programmatically accessible via TypeScript/JavaScript SDK.

## Overview

A curated library of 140+ prompts for various use cases, accessible both as a reference and programmatically via the npm package.

## Installation

```bash
npm install chatgpt chatgpt-prompts
```

## Programmatic Usage

```typescript
import { ChatGPTAPI } from 'chatgpt';
import prompts from 'chatgpt-prompts';

const api = new ChatGPTAPI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Get a specific prompt
const prompt = prompts.getPrompt('linuxTerminal');

// Use in conversation
const res = await api.sendMessage('pwd', {
  systemMessage: prompt,
});
```

## Prompt Categories

### Development & Technical

- `linuxTerminal` — Act as a Linux terminal
- `javascriptConsole` — JavaScript REPL
- `sqlTerminal` — SQL database interface
- `gitCommitGenerator` — Generate commit messages
- `codeExplainer` — Explain code snippets
- `bugFinder` — Identify bugs in code
- `pythonInterpreter` — Python REPL
- `regexGenerator` — Create regex patterns

### Writing & Content

- `essayWriter` — Academic essays
- `plagiarismChecker` — Check for plagiarism
- `grammarCorrector` — Fix grammar
- `contentSummarizer` — Summarize long content
- `storyGenerator` — Creative fiction
- `poetryWriter` — Generate poems
- `speechWriter` — Write speeches

### Business & Professional

- `emailWriter` — Professional emails
- `meetingNotes` — Summarize meetings
- `jobInterviewer` — Practice interviews
- `legalAdvisor` — Legal guidance
- `marketingCopy` — Marketing content
- `businessPlan` — Business planning

### Education & Learning

- `tutor` — Teaching assistant
- `languageTeacher` — Language instruction
- `mathTutor` — Math problem solving
- `historyExpert` — Historical knowledge
- `scienceExplainer` — Science concepts

### Creative & Fun

- `characterRoleplay` — Play a character
- `dungeonMaster` — D&D game master
- `trivia` — Trivia questions
- `jokes` — Tell jokes
- `recipes` — Cooking recipes

## Example Prompts

### Linux Terminal

```
I want you to act as a Linux terminal. I will type commands and you 
will reply with what the terminal should show. I want you to only 
reply with the terminal output inside one unique code block, and 
nothing else. Do not write explanations. Do not type commands unless 
I instruct you to do so. When I need to tell you something in English 
I will do so by putting text inside curly brackets {like this}.
```

### Code Reviewer

```
I want you to act as a code reviewer. I will provide you with code 
snippets and you will analyze them for bugs, security issues, and 
style improvements. Provide specific feedback with line numbers and 
suggested fixes.
```

### Writing Tutor

```
I want you to act as a writing tutor. You will help improve my 
writing by providing feedback on structure, clarity, grammar, and 
style. Ask clarifying questions about my audience and goals.
```

## SDK API

```typescript
import prompts from 'chatgpt-prompts';

// Get all prompts
const all = prompts.getAllPrompts();

// Get prompt by key
const prompt = prompts.getPrompt('linuxTerminal');

// Get prompts by category
const technical = prompts.getPromptsByCategory('technical');

// Search prompts
const results = prompts.searchPrompts('code');
```

## Key Design Principles

- **Curated quality** — Each prompt is tested and refined
- **Programmatic access** — Use in code, not just copy-paste
- **Category organization** — Find prompts by use case
- **Extensible** — Add custom prompts to the library
