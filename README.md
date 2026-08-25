# ClaviRom iOS

An iOS custom keyboard for the Romansh (rumantsch) idioms — an iOS companion to the
Android keyboard [ClaviRom](https://github.com/mhuberch/clavirom) (a HeliBoard fork).

Covers the five idioms plus the standardized pan-regional variety:

- Rumantsch Grischun (`rm`)
- Sursilvan (`rm-SR`)
- Puter (`rm-PU`)
- Vallader (`rm-VA`)
- Surmiran (`rm-SM`)
- Sutsilvan (`rm-ST`)

## Status

Early scaffolding. Nothing builds yet.

## Approach

iOS keyboards ship as a **Custom Keyboard Extension** (a container app + an extension
target). Unlike Android, iOS does not expose system autocorrect/suggestions to third-party
keyboards, so suggestions run on our own word lists and an on-device engine.

The word lists are recovered from ClaviRom's compiled dictionaries (AOSP/HeliBoard binary
format v202) as `word,frequency` data — the reusable linguistic asset behind this project.

## License

To be decided. ClaviRom is GPL-3.0; any reuse of its data/assets must respect that.
