# Turndown HTML→Markdown Config (AI-tuned)

**Source:** [needle-tools/md-browse](https://github.com/needle-tools/md-browse) (MIT)
**What:** Turndown configuration tuned to match what Claude/Copilot see when converting HTML to markdown. Useful for any web scraping or content extraction pipeline.

## Key Settings

```js
const turndown = new TurndownService({
  headingStyle: "atx",
  codeBlockStyle: "fenced",
  emDelimiter: "_",
  bulletListMarker: "-",
});
turndown.use(gfm); // GitHub Flavored Markdown
```

## Notable Rules

### Remove noise elements
```js
const UNWANTED_ELEMENTS = ["script", "style", "noscript", "iframe", "object", "embed", "meta", "link"];
turndown.remove(UNWANTED_ELEMENTS);
```

### Ignore layout tables (no headers = not a real table)
```js
turndown.addRule("ignoreLayoutTables", {
  filter: (node) => {
    if (node.nodeName !== "TABLE") return false;
    return node.querySelectorAll("th").length === 0;
  },
  replacement: (content) => `\n\n${content}\n\n`,
});
```

### Preserve blank links (use aria-label, title, img alt as fallback)
Falls back through: textContent → aria-label → title → img[alt] → href itself.

### Cleanup pass
- Normalize whitespace in link labels
- Fix protocol-relative URLs (`//` → `https://`)
- Remove `data:` URI image refs (SVG sprites noise)
- Strip empty ordered list items
- Collapse triple+ newlines to double

## Idea: Accept: text/markdown

md-browse sends `Accept: text/markdown` header first — some sites (like Vercel docs) actually serve markdown directly. Worth trying in any scraping pipeline before falling back to HTML conversion.
