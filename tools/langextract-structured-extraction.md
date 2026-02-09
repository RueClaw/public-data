# LangExtract — LLM-Powered Structured Extraction

**Source:** [google/langextract](https://github.com/google/langextract) (Apache 2.0)
**By:** Google

## What It Does

Python library that uses LLMs to extract structured information from unstructured text. Define what you want via few-shot examples, get back grounded, schema-compliant JSON.

## Key Features

1. **Source grounding** — every extraction maps to exact character position in source text
2. **Interactive HTML visualization** — review thousands of entities in original context
3. **Long document optimization** — chunking + parallel processing + multiple passes for recall
4. **Controlled generation** — uses Gemini's constrained output for guaranteed schema compliance
5. **Few-shot driven** — define tasks with examples, no fine-tuning
6. **Multi-model** — Gemini (recommended), OpenAI, local via Ollama

## Architecture

- `chunking.py` — splits long docs into overlapping chunks
- `extraction.py` — core extraction loop (chunk → LLM → merge)
- `prompting.py` — builds few-shot prompts from examples
- `prompt_validation.py` — validates examples align with source text
- `visualization.py` — generates self-contained HTML for review
- `providers/` — pluggable LLM backends
- `schema.py` — output schema enforcement

## Usage Pattern

```python
import langextract as lx

result = lx.extract(
    text_or_documents=input_text,
    prompt_description="Extract characters and emotions...",
    examples=[lx.data.ExampleData(text="...", extractions=[...])],
    model_id="gemini-2.5-flash",
)
result.save("output.jsonl")
lx.visualize("output.jsonl", "review.html")
```
