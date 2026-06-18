import json
import re
import os

def html_refrains_in_text(text):
    if not text:
        return ""
        
    # Clean up any leftover asterisks from previous runs first
    text = text.replace("**", "")
    
    lines = text.splitlines()
    output_lines = []
    inside_refrain = False

    refrain_marker_pattern = re.compile(r'^\s*(refrain|chorus)\s*:', re.IGNORECASE)
    stanza_marker_pattern = re.compile(r'^\s*\d+\s*$', re.IGNORECASE)

    for line in lines:
        stripped_line = line.strip()

        if refrain_marker_pattern.match(stripped_line):
            inside_refrain = True
            output_lines.append(f"<b>{stripped_line}</b>")
            continue

        if inside_refrain and (stripped_line == "" or stanza_marker_pattern.match(stripped_line)):
            inside_refrain = False

        if inside_refrain and stripped_line != "":
            # Wrap the line safely inside HTML bold tags
            leading_spaces = line[:len(line) - len(line.lstrip())]
            output_lines.append(f"{leading_spaces}<b>{stripped_line}</b>")
        else:
            output_lines.append(line)

    return "\n".join(output_lines)

def process_hymns_database():
    filename = "hymns.json"
    if not os.path.exists(filename):
        print(f"❌ Error: '{filename}' not found.")
        return

    with open(filename, "r", encoding="utf-8") as file:
        hymns_data = json.load(file)

    for hymn in hymns_data:
        if "lyricsEn" in hymn:
            hymn["lyricsEn"] = html_refrains_in_text(hymn["lyricsEn"])
        if "lyricsFr" in hymn:
            hymn["lyricsFr"] = html_refrains_in_text(hymn["lyricsFr"])

    with open(filename, "w", encoding="utf-8") as file:
        json.dump(hymns_data, file, ensure_ascii=False, indent=2)

    print(f"✨ Success! Upgraded hymns database to HTML <b> markup formatting.")

if __name__ == "__main__":
    process_hymns_database()
