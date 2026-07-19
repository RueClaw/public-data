# Exercises Dataset (hasaneyldrm/exercises-dataset)

**Repo:** https://github.com/hasaneyldrm/exercises-dataset
**License:** MIT for code, tooling, dataset structure, and instruction text; exercise media is excluded and governed by separate Gym visual terms.
**Reviewed:** 2026-07-19
**Stack:** JSON, JSON Schema 2020-12, static HTML/CSS/JavaScript, local JPG/GIF media
**What it is:** A large ready-to-use fitness exercise dataset with 1,324 exercise records, thumbnails, animated GIFs, muscle/equipment metadata, and instructions in 10 languages.

---

## Verdict

⚠️ **Interesting dataset, but not a clean drop-in asset pack.** The structured JSON is immediately useful for workout apps, recommendation demos, and exercise catalogs, and the included schema is a real integration aid. The main caveat is licensing: the data/text is MIT, but the images and GIFs are not MIT and require separate Gym visual rights. The static SQL exporter also currently omits French instruction columns despite the dataset advertising 10 languages.

---

## What It Is

`exercises-dataset` is the exercise data layer behind LogPress, published as a standalone repository. It ships a single JSON array with 1,324 exercises covering body part, target muscle, equipment, synergist muscles, secondary muscles, image path, GIF path, attribution, full instructions, and step arrays.

The dataset is unusually practical for application builders because it includes local 180x180 thumbnails and GIFs for every record, plus a static exercise browser and setup wizard. There is no server component; the browser can be opened directly and the setup guide generates SQL inserts locally in the browser.

The repository is best treated as a high-quality seed catalog, not as a fully governed medical or professional coaching dataset. Exercise names, groupings, and movement instructions are useful, but downstream apps should still add review, substitutions, contraindications, accessibility metadata, and safety disclaimers where health advice is involved.

## Stack

| Layer | Tech |
|-------|------|
| Data | `data/exercises.json` JSON array |
| Schema | JSON Schema Draft 2020-12 |
| Browser | Static HTML/CSS/JavaScript |
| Media | 1,324 JPG thumbnails and 1,324 GIF animations |
| Export tooling | Client-side SQL generator inside `setup.html` / `index.html` |
| Backend | None |

## Key Features

### Complete Exercise Records

Each record has a stable zero-padded ID, name, body part, equipment, target muscle, secondary muscles, media references, attribution, and creation timestamp. The schema uses `additionalProperties: false`, which is a good signal for consumers that want deterministic imports rather than fuzzy application data.

### Multilingual Instructions

The dataset contains both paragraph instructions and step arrays for English, Spanish, Italian, Turkish, Russian, Chinese, Hindi, Polish, Korean, and French. A local check found no records missing the required language maps.

### Bundled Media

Every exercise record points to a local thumbnail and GIF, and the repository contains matching files for all 1,324 records. That makes prototypes look finished quickly, but it is also where the license caveat matters most: cloning the repo does not grant broad reuse rights to the media.

### Static Browser and Setup Wizard

The included `index.html` provides search, filters, infinite-scroll cards, a detail modal, and multilingual instruction tabs. The setup wizard includes SQL table templates and client snippets for common backend stacks.

## Architecture

This is a data-first repository. The important design choice is keeping the canonical dataset in `data/exercises.json` with a formal schema, while treating the HTML browser and SQL generator as convenience tooling.

The schema is strict about the core record shape:

```json
{
  "id": "0001",
  "name": "3/4 sit-up",
  "body_part": "waist",
  "equipment": "body weight",
  "instructions": {
    "en": "...",
    "fr": "..."
  },
  "instruction_steps": {
    "en": ["..."],
    "fr": ["..."]
  },
  "image": "images/0001-2gPfomN.jpg",
  "gif_url": "videos/0001-2gPfomN.gif"
}
```

The static browser embeds the whole dataset directly into `index.html`, which makes it easy to run offline but heavy and somewhat brittle as an editing surface. Several render paths use `innerHTML`; that is acceptable for the bundled trusted data, but downstream apps should render untrusted exercise content with text nodes or escaping.

## Comparison

Compared with small exercise JSON lists, this repository is much more application-ready because it includes media, multilingual step arrays, and a schema. Compared with commercial exercise APIs, it is cheaper and more inspectable, but lacks API hosting, professional content guarantees, injury/contraindication metadata, user-level substitutions, taxonomy versioning, and fully transferable media rights.

| Aspect | Exercises Dataset | Commercial Exercise API | Small Open JSON List |
|--------|-------------------|-------------------------|----------------------|
| Data volume | 1,324 exercises | Often large | Usually small |
| Media | Bundled JPG/GIF, restricted reuse | Usually licensed through API | Often absent |
| Schema | Included JSON Schema | API contract | Often informal |
| Multilingual instructions | 10 languages | Varies | Rare |
| Operational support | Static files only | Hosted API/support | Usually none |
| License clarity | Split data/media terms | Vendor terms | Often unclear |

## Self-Hosting Notes

No service is required. Consumers can clone the repo, import `data/exercises.json`, and serve the media paths themselves if they have appropriate media rights.

Important caveats:

- Treat `images/` and `videos/` separately from the MIT-licensed JSON/text.
- Preserve the Gym visual attribution field where media is displayed.
- Do not rely on the current SQL exporter for all 10 languages; French is mentioned in the setup prompt but omitted from generated table definitions and INSERT statements.
- Add your own validation/CI if the dataset becomes a production dependency.
- Add product-specific health, safety, accessibility, and substitution metadata before using it in coaching or rehabilitation contexts.

---

**Attribution:** hasaneyldrm/exercises-dataset, MIT for code/data/text with separate Gym visual media terms.
