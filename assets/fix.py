"""
Hymnal JSON Numbering Fixer & Validator
========================================
Steps:
  1. Strip ALL existing stanza numbers from lyricsEn and lyricsFr
  2. Re-number stanzas properly (choruses/refrains are never numbered)
  3. Validate the result and report any errors

Rules:
  - Stanzas are numbered sequentially: 1, 2, 3 …
  - Chorus / Refrain / Chorus 1: / Chorus 2: / Refrain 1: / Refrain 2: etc.
    are NEVER numbered — they keep their <b>…</b> label lines as-is
  - A hymn may START with a chorus before stanza 1
  - Multiple distinct choruses (Chorus 1, Chorus 2 …) are allowed
"""

import json
import re
import sys
import copy
from pathlib import Path


# ── helpers ────────────────────────────────────────────────────────────────────

# Matches a line that is ONLY a stanza number (possibly with trailing spaces)
STANZA_NUM_RE = re.compile(r'^\s*\d+\s*$')

# Matches the opening bold tag of a chorus/refrain label — all known variants
CHORUS_LABEL_RE = re.compile(
    r'<b>\s*(refrain\s+\d+\s*:|refrain\s*:|réf\.?\s*:|choeur\s*:|chorus\s+\d+\s*:|chorus\s*:)\s*<\/b>',
    re.IGNORECASE
)


def is_chorus_line(line: str) -> bool:
    """Return True if this line is a bold chorus/refrain label."""
    return bool(CHORUS_LABEL_RE.search(line))


def is_bold_line(line: str) -> bool:
    """Return True if this line is any <b>…</b> content (chorus body)."""
    stripped = line.strip()
    return stripped.startswith('<b>') and stripped.endswith('</b>')


def split_into_blocks(lyrics: str):
    """
    Split a lyrics string into logical blocks.

    Each block is a dict:
      { 'type': 'stanza' | 'chorus', 'lines': [str, …] }

    A block boundary occurs when we hit:
      - A bare stanza-number line  → start of a stanza block
      - A <b>Chorus:</b> label line → start of a chorus block
    Blank lines between blocks are preserved inside blocks as separators
    but NOT counted as block boundaries on their own.
    """
    raw_lines = lyrics.split('\n')
    blocks = []
    current_block = None

    i = 0
    while i < len(raw_lines):
        line = raw_lines[i]

        if STANZA_NUM_RE.match(line):
            # Save previous block
            if current_block:
                blocks.append(current_block)
            # Start a new stanza block (drop the old number — we'll add fresh ones)
            current_block = {'type': 'stanza', 'lines': []}
            i += 1
            continue

        if is_chorus_line(line):
            if current_block:
                blocks.append(current_block)
            # Chorus block starts with this label line
            current_block = {'type': 'chorus', 'lines': [line]}
            i += 1
            continue

        # Any other line: append to current block
        if current_block is None:
            # Content before the first explicit marker → treat as stanza
            current_block = {'type': 'stanza', 'lines': []}
        current_block['lines'].append(line)
        i += 1

    if current_block:
        blocks.append(current_block)

    return blocks


def strip_leading_trailing_blanks(lines):
    """Remove leading and trailing empty lines from a list."""
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return lines


def rebuild_lyrics(blocks) -> str:
    """
    Given blocks, assign fresh stanza numbers and rebuild the lyrics string.
    Choruses get NO number. Blocks are separated by a blank line.
    """
    stanza_counter = 0
    parts = []

    for block in blocks:
        lines = strip_leading_trailing_blanks(list(block['lines']))
        if not lines:
            continue

        if block['type'] == 'stanza':
            stanza_counter += 1
            parts.append(str(stanza_counter))          # fresh number on its own line
            parts.extend(lines)
        else:
            # chorus — no number, just its lines (label already included)
            parts.extend(lines)

        parts.append('')   # blank line between blocks

    # Remove trailing blank line
    while parts and parts[-1] == '':
        parts.pop()

    return '\n'.join(parts)


def fix_lyrics(lyrics: str) -> str:
    if not lyrics:
        return lyrics
    blocks = split_into_blocks(lyrics)
    return rebuild_lyrics(blocks)


# ── validation ─────────────────────────────────────────────────────────────────

def validate_lyrics(hymn_id, lang, lyrics: str):
    """
    Check the fixed lyrics for numbering errors.
    Returns a list of error strings (empty = all good).
    """
    errors = []
    lines = lyrics.split('\n')
    seen_stanza_numbers = []
    inside_chorus = False

    for lineno, line in enumerate(lines, 1):
        stripped = line.strip()

        # Track chorus regions
        if is_chorus_line(stripped):
            inside_chorus = True
            continue
        if inside_chorus:
            if not stripped:
                inside_chorus = False      # blank line ends chorus
            continue

        if STANZA_NUM_RE.match(stripped):
            num = int(stripped)
            # Rule 1: stanza numbers must start at 1
            if not seen_stanza_numbers and num != 1:
                errors.append(
                    f"  [{lang}] Hymn {hymn_id}: first stanza number is {num}, expected 1 (line {lineno})"
                )
            # Rule 2: no duplicates
            if num in seen_stanza_numbers:
                errors.append(
                    f"  [{lang}] Hymn {hymn_id}: duplicate stanza number {num} (line {lineno})"
                )
            # Rule 3: must be consecutive
            if seen_stanza_numbers and num != seen_stanza_numbers[-1] + 1:
                errors.append(
                    f"  [{lang}] Hymn {hymn_id}: stanza number jumped from "
                    f"{seen_stanza_numbers[-1]} to {num} (line {lineno})"
                )
            seen_stanza_numbers.append(num)

    # Rule 4: at least one stanza
    if not seen_stanza_numbers:
        errors.append(
            f"  [{lang}] Hymn {hymn_id}: no stanza numbers found at all"
        )

    return errors


# ── main ───────────────────────────────────────────────────────────────────────

def process_file(input_path: str):
    input_file = Path(input_path)
    if not input_file.exists():
        print(f"ERROR: file not found → {input_path}")
        sys.exit(1)

    # ── Backup original ──
    backup_path = input_file.with_suffix('.backup.json')
    backup_path.write_bytes(input_file.read_bytes())
    print(f"Backup saved to '{backup_path}'")

    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Loaded {len(data)} hymns from '{input_path}'")
    print("=" * 60)

    fixed_data = []
    all_errors = []

    for hymn in data:
        hymn_copy = copy.deepcopy(hymn)
        hid = hymn_copy.get('number', hymn_copy.get('id', '?'))

        # ── Step 1 & 2: clear old numbers, renumber ──
        hymn_copy['lyricsEn'] = fix_lyrics(hymn_copy.get('lyricsEn', ''))
        hymn_copy['lyricsFr'] = fix_lyrics(hymn_copy.get('lyricsFr', ''))

        # ── Step 3: validate ──
        errs_en = validate_lyrics(hid, 'EN', hymn_copy['lyricsEn'])
        errs_fr = validate_lyrics(hid, 'FR', hymn_copy['lyricsFr'])
        all_errors.extend(errs_en + errs_fr)

        fixed_data.append(hymn_copy)

    # ── Overwrite original file ──
    with open(input_file, 'w', encoding='utf-8') as f:
        json.dump(fixed_data, f, ensure_ascii=False, indent=2)

    print(f"'{input_path}' updated in place.")
    print("=" * 60)

    # ── Report ──
    if all_errors:
        print(f"\n⚠  VALIDATION ERRORS FOUND ({len(all_errors)}):\n")
        for e in all_errors:
            print(e)
        print()
    else:
        print("\n✅  All hymns passed validation — numbering is consistent!\n")

    # ── Summary per hymn ──
    print("Per-hymn summary:")
    for hymn in fixed_data:
        hid  = hymn.get('number', hymn.get('id', '?'))
        titl = hymn.get('titleEn', '')
        blocks_en = split_into_blocks(hymn['lyricsEn'])
        blocks_fr = split_into_blocks(hymn['lyricsFr'])
        stanzas_en = sum(1 for b in blocks_en if b['type'] == 'stanza')
        stanzas_fr = sum(1 for b in blocks_fr if b['type'] == 'stanza')
        chorus_en  = sum(1 for b in blocks_en if b['type'] == 'chorus')
        chorus_fr  = sum(1 for b in blocks_fr if b['type'] == 'chorus')
        print(
            f"  #{hid:>4}  {titl[:40]:<40}  "
            f"EN: {stanzas_en} stanza(s), {chorus_en} chorus(es)  |  "
            f"FR: {stanzas_fr} stanza(s), {chorus_fr} chorus(es)"
        )

    print("\nDone.")


if __name__ == '__main__':
    # Usage: python fix_hymn_numbering.py [hymns.json]
    input_json = sys.argv[1] if len(sys.argv) > 1 else 'hymns.json'
    process_file(input_json)
