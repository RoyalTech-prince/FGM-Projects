import json
import re
import os

def html_refrains_in_text(text):
    """Wrap refrains/choruses in HTML bold tags and number stanzas."""
    if not text:
        return ""
    
    # Clean up any leftover asterisks from previous runs first
    text = text.replace("**", "")
    
    lines = text.splitlines()
    output_lines = []
    inside_refrain = False
    stanza_counter = 1
    skip_mode = False  # For numbering skip
    
    # Pattern for refrain markers
    refrain_marker_pattern = re.compile(r'^\s*(refrain|refrain 2x|refrain 1:|refrain 2:|réf\.?|réf\.?\s*:|choeur|chorus|chorus 1:|chorus 2:|chorus:)\s*', re.IGNORECASE)
    # Pattern for existing stanza numbers
    stanza_marker_pattern = re.compile(r'^\s*\d+\s*$', re.IGNORECASE)
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped_line = line.strip()
        
        # Check if this is a refrain marker
        if refrain_marker_pattern.match(stripped_line):
            # Keep the marker, don't number it
            output_lines.append(f"<b>{stripped_line}</b>")
            inside_refrain = True
            i += 1
            continue
        
        # If we're inside a refrain, skip numbering and wrap in bold
        if inside_refrain:
            # Check if we've reached the end of the refrain
            if stripped_line == "" or stanza_marker_pattern.match(stripped_line):
                inside_refrain = False
                # Don't skip - let the empty line or stanza number pass through
                if stripped_line == "":
                    output_lines.append(line)
                    i += 1
                    continue
                # If it's a stanza number, let it be processed normally
                # (but we're inside_refrain=False now, so it will fall through)
            
            if inside_refrain and stripped_line != "":
                # Wrap the line inside HTML bold tags
                leading_spaces = line[:len(line) - len(line.lstrip())]
                output_lines.append(f"{leading_spaces}<b>{stripped_line}</b>")
                i += 1
                continue
            else:
                # If we exited the refrain, continue processing normally
                continue
        
        # Skip empty lines (but keep them)
        if not stripped_line:
            output_lines.append(line)
            i += 1
            continue
        
        # Check if line is already a stanza number (to avoid double numbering)
        if stanza_marker_pattern.match(stripped_line):
            output_lines.append(line)
            i += 1
            continue
        
        # Check if this starts a new stanza (after an empty line or at beginning)
        is_new_stanza = (
            i == 0 or 
            (i > 0 and lines[i-1].strip() == '')
        )
        
        # Also check if the previous line was a refrain marker
        if i > 0 and refrain_marker_pattern.match(lines[i-1].strip()):
            is_new_stanza = True
        
        if is_new_stanza:
            # Add the number on its own line
            output_lines.append(str(stanza_counter))
            output_lines.append(line)
            stanza_counter += 1
        else:
            output_lines.append(line)
        
        i += 1
    
    return "\n".join(output_lines)

def process_hymns_database():
    filename = "hymns.json"
    if not os.path.exists(filename):
        print(f"❌ Error: '{filename}' not found.")
        return

    with open(filename, "r", encoding="utf-8") as file:
        hymns_data = json.load(file)

    # Handle both single object and array of objects
    if isinstance(hymns_data, dict):
        hymns_data = [hymns_data]

    for hymn in hymns_data:
        if "lyricsEn" in hymn:
            hymn["lyricsEn"] = html_refrains_in_text(hymn["lyricsEn"])
        if "lyricsFr" in hymn:
            hymn["lyricsFr"] = html_refrains_in_text(hymn["lyricsFr"])

    # Save back to file (if it was a single object, save as single object)
    with open(filename, "w", encoding="utf-8") as file:
        if len(hymns_data) == 1:
            json.dump(hymns_data[0], file, ensure_ascii=False, indent=2)
        else:
            json.dump(hymns_data, file, ensure_ascii=False, indent=2)

    print(f"✨ Success! Upgraded hymns database with both stanza numbering and HTML <b> markup formatting.")

if __name__ == "__main__":
    process_hymns_database()
