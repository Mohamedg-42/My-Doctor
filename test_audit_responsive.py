import os
import re

lib_dir = r"c:\Users\HP\Downloads\My-Doctor\lib"

issues = []

for root, dirs, files in os.walk(lib_dir):
    for f in files:
        if f.endswith(".dart"):
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8", errors="ignore") as file:
                lines = file.readlines()
            
            content = "".join(lines)
            
            # Check 1: Fixed widths > 340
            for i, line in enumerate(lines):
                m = re.search(r'width\s*:\s*(\d{3,4})', line)
                if m:
                    val = int(m.group(1))
                    if val >= 350 and not 'double.infinity' in line and not 'MediaQuery' in line:
                        issues.append((path, i + 1, f"Hardcoded large width: {val}px (might overflow on 320-360px screens)", line.strip()))
            
            # Check 2: Row containing Text without Expanded/Flexible
            # Look for Row( children: [ ... Text( ... Text( or Text( ... Icon(
            # We can detect Rows where multiple children exist and at least one is a long Text without Expanded
            in_row = False
            row_start = 0
            bracket_depth = 0
            row_content = []
            
            for i, line in enumerate(lines):
                if 'Row(' in line:
                    in_row = True
                    row_start = i + 1
                    row_content = [line]
                    bracket_depth = line.count('(') - line.count(')')
                    continue
                
                if in_row:
                    row_content.append(line)
                    bracket_depth += line.count('(') - line.count(')')
                    if bracket_depth <= 0:
                        in_row = False
                        block = "".join(row_content)
                        # Check if block has multiple children
                        if 'children:' in block:
                            # If it has Text with a literal string > 25 chars and NO Expanded or Flexible
                            texts = re.findall(r"Text\s*\(\s*['\"]([^'\"]+)['\"]", block)
                            for t in texts:
                                if len(t) > 28 and 'Expanded' not in block and 'Flexible' not in block:
                                    issues.append((path, row_start, f"Row with long text '{t[:30]}...' without Expanded/Flexible", row_content[0].strip()))
                                    break

print(f"Total potential layout issues found: {len(issues)}")
for path, line_no, desc, snippet in issues[:40]:
    rel = os.path.relpath(path, lib_dir)
    print(f"{rel}:{line_no} -> {desc}")
