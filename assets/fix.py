import json
import re

def is_chorus_or_refrain(line):
    """Check if a line indicates a chorus or refrain (with or without HTML tags)."""
    # First, strip HTML tags for detection
    clean_line = re.sub(r'<[^>]+>', '', line).strip()
    line_lower = clean_line.lower()
    
    # Check if the line contains any chorus/refrain keyword at the beginning
    chorus_patterns = [
        r'^chorus\s*:?\s*',           # "chorus" or "chorus:" at start
        r'^chorus\s+\d+\s*:?\s*',     # "chorus 1" or "chorus 1:"
        r'^refrain\s*:?\s*',          # "refrain" or "refrain:"
        r'^refrain\s+\d+\s*:?\s*',    # "refrain 2" or "refrain 2:"
        r'^r[eé]f\.?\s*:?\s*',        # "réf" or "réf." with accent
        r'^chœur\s*:?\s*',            # "chœur" or "chœur:"
        r'^choeur\s*:?\s*',           # "choeur" or "choeur:"
        r'^\(chorus\)',               # "(chorus)"
        r'^\(refrain\)',              # "(refrain)"
        r'^\(chœur\)',                # "(chœur)"
        r'^\(réf\)',                  # "(réf)"
    ]
    
    for pattern in chorus_patterns:
        if re.match(pattern, line_lower):
            return True
    
    # Also check if the line contains "chorus:" or "refrain:" anywhere (not just at start)
    if re.search(r'\bchorus\s*:?\s*', line_lower):
        return True
    if re.search(r'\brefrain\s*:?\s*', line_lower):
        return True
    if re.search(r'\bchœur\s*:?\s*', line_lower):
        return True
    if re.search(r'\bchoeur\s*:?\s*', line_lower):
        return True
    if re.search(r'\bréf\.?\s*:?\s*', line_lower):
        return True
    
    return False

def remove_existing_numbers(lines):
    """Remove all existing stanza numbers (lines that are just a number)."""
    result = []
    for line in lines:
        if not re.match(r'^\s*\d+\s*$', line):
            result.append(line)
    return result

def number_stanzas(lyrics):
    """
    Add stanza numbering (1, 2, 3, etc.) on separate lines above each stanza.
    Skips chorus/refrain markers and their content.
    """
    if not lyrics or lyrics == "NO TRANSLATION IN THIS LANGUAGE" or lyrics == "PAS DE TRADUCTION EN CETTE LANGUE":
        return lyrics
    
    lines = lyrics.split('\n')
    
    # Step 1: Remove ALL existing stanza numbers
    lines = remove_existing_numbers(lines)
    
    numbered_lines = []
    stanza_counter = 1
    skip_mode = False  # When True, we're inside a chorus/refrain and skip numbering
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Check if this is a chorus/refrain marker
        if is_chorus_or_refrain(line):
            # Keep the marker as is
            numbered_lines.append(line)
            skip_mode = True
            i += 1
            continue
        
        # If we're in skip_mode, keep adding lines until we hit an empty line
        if skip_mode:
            numbered_lines.append(line)
            # Check if this is the end of the chorus (empty line)
            if stripped == '':
                skip_mode = False
            i += 1
            continue
        
        # Skip empty lines
        if not stripped:
            numbered_lines.append(line)
            i += 1
            continue
        
        # Check if this starts a new stanza (after an empty line or at beginning)
        is_new_stanza = (
            i == 0 or 
            (i > 0 and lines[i-1].strip() == '') or
            (i > 0 and is_chorus_or_refrain(lines[i-1])) or
            (i > 1 and lines[i-1].strip() == '' and is_chorus_or_refrain(lines[i-2]))
        )
        
        if is_new_stanza:
            # Add the number on its own line
            numbered_lines.append(str(stanza_counter))
            numbered_lines.append(line)
            stanza_counter += 1
        else:
            numbered_lines.append(line)
        
        i += 1
    
    return '\n'.join(numbered_lines)

def validate_lyrics(lyrics, lang="EN"):
    """Validate the numbered lyrics for consistency."""
    if not lyrics or lyrics == "NO TRANSLATION IN THIS LANGUAGE" or lyrics == "PAS DE TRADUCTION EN CETTE LANGUE":
        return []
    
    errors = []
    lines = lyrics.split('\n')
    stanza_numbers = []
    expected_next = 1
    inside_chorus = False
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # Track if we're inside a chorus
        if is_chorus_or_refrain(line):
            inside_chorus = True
            continue
        
        if inside_chorus and stripped == '':
            inside_chorus = False
            continue
        
        # Only check stanza numbers (lines that are just a number)
        if re.match(r'^\s*\d+\s*$', stripped) and not inside_chorus:
            num = int(stripped)
            stanza_numbers.append(num)
            
            # Check if numbers are consecutive starting from 1
            if num != expected_next:
                errors.append(f"  [{lang}] Expected stanza {expected_next}, got {num} at line {i}")
                expected_next = num + 1
            else:
                expected_next += 1
    
    # Check if we have any stanzas
    if not stanza_numbers:
        errors.append(f"  [{lang}] No stanza numbers found!")
    
    return errors

def process_json_file(input_file="hymns.json"):
    """Process hymns.json file directly."""
    
    print(f"📖 Reading {input_file}...")
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: '{input_file}' not found.")
        return
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in '{input_file}': {e}")
        return
    
    # Handle both single object and array of objects
    if isinstance(data, dict):
        songs = [data]
    else:
        songs = data
    
    print(f"📝 Processing {len(songs)} songs...")
    print("=" * 60)
    
    # Create backup
    backup_file = input_file.replace('.json', '.backup.json')
    with open(backup_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"💾 Backup saved to '{backup_file}'")
    print("=" * 60)
    
    en_changes = 0
    fr_changes = 0
    all_errors = []
    
    for i, song in enumerate(songs):
        hid = song.get('number', song.get('id', '?'))
        
        if 'lyricsEn' in song:
            old = song['lyricsEn']
            song['lyricsEn'] = number_stanzas(old)
            if old != song['lyricsEn']:
                en_changes += 1
                print(f"  ✏️  Song {hid}: English lyrics updated")
                errors = validate_lyrics(song['lyricsEn'], "EN")
                all_errors.extend(errors)
        
        if 'lyricsFr' in song:
            old = song['lyricsFr']
            song['lyricsFr'] = number_stanzas(old)
            if old != song['lyricsFr']:
                fr_changes += 1
                print(f"  ✏️  Song {hid}: French lyrics updated")
                errors = validate_lyrics(song['lyricsFr'], "FR")
                all_errors.extend(errors)
    
    # Save directly back to hymns.json
    with open(input_file, 'w', encoding='utf-8') as f:
        json.dump(songs if isinstance(data, list) else songs[0], f, indent=2, ensure_ascii=False)
    
    print("=" * 60)
    print(f"✅ Done! Processed {len(songs)} songs. Saved to {input_file}")
    print(f"📊 Summary: {en_changes} English updates, {fr_changes} French updates")
    
    # Report validation errors
    if all_errors:
        print("=" * 60)
        print(f"⚠️  VALIDATION ERRORS FOUND ({len(all_errors)}):")
        for error in all_errors:
            print(error)
    else:
        print("✅ All validated - no numbering errors found!")

# Run the script
if __name__ == "__main__":
    import sys
    
    # Allow custom input file via command line
    input_file = sys.argv[1] if len(sys.argv) > 1 else "hymns.json"
    process_json_file(input_file)
