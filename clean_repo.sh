#!/usr/bin/env bash

# 1. Define the large files to remove (wildcard for all .deb in assets)
TARGET_FILES="assets/*.deb"

echo "!!! WARNING: This will rewrite git history to remove $TARGET_FILES !!!"
echo "Press Ctrl+C to cancel, or wait 5 seconds to proceed..."
sleep 5

# 2. Remove the files from the Git Index (Staging area) if they are currently tracked
git rm --cached $TARGET_FILES --ignore-unmatch 2>/dev/null

# 3. Update .gitignore to ensure they aren't added again
if ! grep -q "*.deb" .gitignore; then
    echo "Ignoring .deb files..."
    echo "*.deb" >> .gitignore
    echo "assets/*.deb" >> .gitignore
fi

# 4. Use git filter-branch to scrub the file from ALL commit history
# This prevents the .git folder from being huge
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch $TARGET_FILES" \
  --prune-empty --tag-name-filter cat -- --all

# 5. Clean up the backup refs created by filter-branch
rm -rf .git/refs/original/

# 6. Force garbage collection to shrink the repo size
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "------------------------------------------------"
echo "Cleanup complete. Large binaries removed from history."
echo "Your repo is now small and clean."
echo "------------------------------------------------"
