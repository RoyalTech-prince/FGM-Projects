import json
import re

def is_chorus_or_refrain(line):
    """Check if a line indicates a chorus or refrain."""
    chorus_keywords = [
        r'^chorus\s*:?$', r'^refrain\s*:?$', r'^ref\.?\s*:?$',
        r'^\(chorus\)$', r'^\(refrain\)$', r'^chœur\s*:?$',
        r'^réf\.?\s*:?$', r'^\(chœur\)$', r'^\(réf\)$'
    ]
    line_lower = line.lower().strip()
    for pattern in chorus_keywords:
        if re.match(pattern, line_lower):
            return True
    return False

def number_stanzas(lyrics):
    """
    Add stanza numbering (1, 2, 3, etc.) on separate lines above each stanza.
    Skips chorus/refrain markers and their content.
    """
    if not lyrics or lyrics == "NO TRANSLATION IN THIS LANGUAGE" or lyrics == "PAS DE TRADUCTION EN CETTE LANGUE":
        return lyrics
    
    lines = lyrics.split('\n')
    numbered_lines = []
    stanza_counter = 1
    skip_mode = False  # When True, we're inside a chorus/refrain and skip numbering
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
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
            if line.strip() == '':
                skip_mode = False
            i += 1
            continue
        
        # Skip empty lines
        if not line.strip():
            numbered_lines.append(line)
            i += 1
            continue
        
        # Check if line is already numbered (to avoid double numbering)
        if re.match(r'^\d+\s*$', line.strip()):
            numbered_lines.append(line)
            i += 1
            continue
        
        # Check if this starts a new stanza (after an empty line or at beginning)
        is_new_stanza = (
            i == 0 or 
            (i > 0 and lines[i-1].strip() == '')
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

def process_json_file():
    """Process hymns.json file directly."""
    input_file = "hymns.json"
    
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Handle both single object and array of objects
    if isinstance(data, dict):
        songs = [data]
    else:
        songs = data
    
    for song in songs:
        if 'lyricsEn' in song:
            song['lyricsEn'] = number_stanzas(song['lyricsEn'])
        if 'lyricsFr' in song:
            song['lyricsFr'] = number_stanzas(song['lyricsFr'])
    
    # Save directly back to hymns.json
    with open(input_file, 'w', encoding='utf-8') as f:
        json.dump(songs if isinstance(data, list) else songs[0], f, indent=2, ensure_ascii=False)
    
    print(f"Done! Processed {len(songs)} songs. Saved to {input_file}")

# Run the script
if __name__ == "__main__":
    process_json_file()
