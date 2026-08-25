# Data

Word lists that drive the keyboard's suggestions, one file per Romansh idiom.

## Format

`wordlists/<locale>.tsv` — tab-separated, one entry per line:

```
<word>\t<frequency>
```

`frequency` is 0–255 (higher = more common), carried over from the source dictionary's
terminal probability. This is the ranking weight for suggestions.

## Provenance

Recovered from [ClaviRom](https://github.com/mhuberch/clavirom)'s compiled dictionaries
(AOSP/HeliBoard **binary format v202**) by walking the Patricia trie and emitting each
terminal word with its frequency. The decoder is [`tools/decode_dict.py`](../tools/decode_dict.py).

To regenerate (needs a local checkout of the Android `clavirom` repo):

```bash
python3 tools/decode_dict.py /path/to/clavirom/app/src/main/assets/dicts/main_rm-VA.dict \
  > data/wordlists/rm-VA.tsv
```

## Current contents

| Locale | Idiom | Entries |
|--------|-------|--------:|
| `rm-VA` | Vallader | 195,171 |

Other idioms (Rumantsch Grischun, Sursilvan, Puter, Surmiran, Sutsilvan) will be added as
the keyboard grows to support them.

## Notes

- ~2.3% of entries are capitalized (proper names, surnames). Kept for now — names are
  useful to type — but easy to filter if we want a lexicon-only list.
- **License:** this data is derived from ClaviRom, which is GPL-3.0. Any redistribution
  must respect that license.
