#!/usr/bin/env python3
"""
Migration Script for Intelligent NavBar Behavior
This script helps identify files that need to be updated to use the new BottomSheetUtils
"""

import os
import re
from pathlib import Path

def find_dart_files(root_dir):
    """Find all Dart files in the project"""
    dart_files = []
    for root, dirs, files in os.walk(root_dir):
        # Skip build and cache directories
        if 'build' in root or '.dart_tool' in root or 'generated' in root:
            continue
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def analyze_file(file_path):
    """Analyze a Dart file for bottom sheet usage"""
    results = {
        'has_modal_bottom_sheet': False,
        'has_nav_visibility_manual': False,
        'show_modal_count': 0,
        'needs_migration': False,
        'line_numbers': []
    }
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
            
            # Check for showModalBottomSheet
            if 'showModalBottomSheet' in content:
                results['has_modal_bottom_sheet'] = True
                results['show_modal_count'] = content.count('showModalBottomSheet')
                
                # Find line numbers
                for i, line in enumerate(lines, 1):
                    if 'showModalBottomSheet' in line:
                        results['line_numbers'].append(i)
            
            # Check for manual nav visibility control
            if 'navVisibility?.value = false' in content or 'NavBarVisibilityScope.maybeOf' in content:
                results['has_nav_visibility_manual'] = True
            
            # Determine if migration is needed
            if results['has_modal_bottom_sheet'] and results['has_nav_visibility_manual']:
                results['needs_migration'] = True
                
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    
    return results

def generate_report(root_dir):
    """Generate migration report"""
    print("=" * 80)
    print("INTELLIGENT NAVBAR - MIGRATION REPORT")
    print("=" * 80)
    print()
    
    dart_files = find_dart_files(root_dir)
    files_needing_migration = []
    
    for file_path in dart_files:
        results = analyze_file(file_path)
        
        if results['needs_migration']:
            files_needing_migration.append((file_path, results))
    
    if not files_needing_migration:
        print("✅ No files need migration! All bottom sheets are already using BottomSheetUtils")
        print()
        return
    
    print(f"📋 Found {len(files_needing_migration)} files that could benefit from migration:\n")
    
    for file_path, results in files_needing_migration:
        rel_path = os.path.relpath(file_path, root_dir)
        print(f"📄 {rel_path}")
        print(f"   • showModalBottomSheet calls: {results['show_modal_count']}")
        print(f"   • Line numbers: {', '.join(map(str, results['line_numbers']))}")
        print()
    
    print("=" * 80)
    print("MIGRATION STEPS:")
    print("=" * 80)
    print("""
1. Add import at the top of each file:
   import '../../core/utils/bottom_sheet_utils.dart';

2. Replace pattern:
   FROM:
   ```dart
   final navVisibility = NavBarVisibilityScope.maybeOf(context);
   navVisibility?.value = false;
   
   showModalBottomSheet(
     context: context,
     builder: (context) => YourWidget(),
   ).whenComplete(() {
     navVisibility?.value = true;
   });
   ```
   
   TO:
   ```dart
   BottomSheetUtils.showAdaptiveBottomSheet(
     context: context,
     builder: (context) => YourWidget(),
   );
   ```

3. For premium styling, use:
   ```dart
   BottomSheetUtils.showAdaptiveBottomSheet(
     context: context,
     builder: (context) => BottomSheetUtils.createPremiumBottomSheet(
       context: context,
       child: YourContent(),
     ),
   );
   ```

4. Test each file after migration to ensure navbar hides/shows correctly

5. Remove unused imports of NavBarVisibilityScope if no longer needed

See NAVBAR_INTELLIGENT_BEHAVIOR_GUIDE.md for detailed examples!
    """)

if __name__ == "__main__":
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir
    
    print(f"Scanning project: {project_root}\n")
    generate_report(str(project_root))
