#!/usr/bin/env python3
"""Script to remove print statements from Dart files while preserving code structure."""

import re
import os
from pathlib import Path

def remove_print_statements(content):
    """Remove complete print() statements from Dart code."""
    lines = content.split('\n')
    result = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        
        # Check if line starts with print(
        if stripped.startswith('print('):
            # Count parentheses to find where the print statement ends
            paren_count = 0
            in_string = False
            string_char = None
            escaped = False
            
            full_statement = line
            j = i
            
            for char in stripped:
                if escaped:
                    escaped = False
                    continue
                    
                if char == '\\':
                    escaped = True
                    continue
                
                if char in ['"', "'"]:
                    if not in_string:
                        in_string = True
                        string_char = char
                    elif char == string_char:
                        in_string = False
                        string_char = None
                
                if not in_string:
                    if char == '(':
                        paren_count += 1
                    elif char == ')':
                        paren_count -= 1
            
            # If parentheses are balanced and line ends with semicolon, skip it
            if paren_count == 0 and stripped.rstrip().endswith(';'):
                i += 1
                continue
            
            # Multi-line print statement
            while paren_count > 0 and j + 1 < len(lines):
                j += 1
                next_line = lines[j]
                full_statement += '\n' + next_line
                
                for char in next_line:
                    if escaped:
                        escaped = False
                        continue
                    
                    if char == '\\':
                        escaped = True
                        continue
                    
                    if char in ['"', "'"]:
                        if not in_string:
                            in_string = True
                            string_char = char
                        elif char == string_char:
                            in_string = False
                            string_char = None
                    
                    if not in_string:
                        if char == '(':
                            paren_count += 1
                        elif char == ')':
                            paren_count -= 1
                
                # If we found the closing parenthesis and semicolon, skip all these lines
                if paren_count == 0:
                    i = j + 1
                    break
            else:
                # Keep the line if we couldn't find the end
                result.append(line)
                i += 1
        else:
            result.append(line)
            i += 1
    
    return '\n'.join(result)

def process_dart_files(directory):
    """Process all Dart files in the directory."""
    dart_files = list(Path(directory).rglob('*.dart'))
    
    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = remove_print_statements(content)
            
            if content != new_content:
                with open(dart_file, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Processed: {dart_file}")
        except Exception as e:
            print(f"Error processing {dart_file}: {e}")

if __name__ == '__main__':
    lib_dir = Path(__file__).parent / 'lib'
    process_dart_files(lib_dir)
    print("Done!")
