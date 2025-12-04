#!/usr/bin/env python3
"""Script to remove all comment lines from Dart files."""

import re
from pathlib import Path

def remove_comments(content):
    """Remove single-line comments but keep doc comments (///)."""
    lines = content.split('\n')
    result = []
    
    for line in lines:
        stripped = line.lstrip()
        
        # Keep doc comments (///)
        if stripped.startswith('///'):
            result.append(line)
            continue
        
        # Skip single-line comments (//)
        if stripped.startswith('//'):
            continue
        
        # For lines with code and inline comments, keep only the code part
        # But be careful with strings containing //
        if '//' in line:
            # Simple check: if there's a // outside of strings
            # This is a simplified approach - may not handle all edge cases
            in_string = False
            string_char = None
            comment_index = -1
            
            for i, char in enumerate(line):
                if char == '\\' and i + 1 < len(line):
                    continue
                
                if char in ['"', "'"]:
                    if not in_string:
                        in_string = True
                        string_char = char
                    elif char == string_char:
                        in_string = False
                
                if not in_string and i + 1 < len(line):
                    if line[i:i+2] == '//':
                        comment_index = i
                        break
            
            if comment_index >= 0:
                # Remove inline comment
                code_part = line[:comment_index].rstrip()
                if code_part:
                    result.append(code_part)
                continue
        
        result.append(line)
    
    return '\n'.join(result)

def process_dart_files(directory):
    """Process all Dart files in the directory."""
    dart_files = list(Path(directory).rglob('*.dart'))
    processed = 0
    
    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = remove_comments(content)
            
            if content != new_content:
                with open(dart_file, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                processed += 1
                print(f"Processed: {dart_file}")
        except Exception as e:
            print(f"Error processing {dart_file}: {e}")
    
    print(f"\n✅ Processed {processed} files")

if __name__ == '__main__':
    lib_dir = Path(__file__).parent / 'lib'
    process_dart_files(lib_dir)
