#!/bin/sh

# Navigate to the specified work directory, if provided.
if [ -n "${INPUT_WORKDIR}" ]; then
  cd "${INPUT_WORKDIR}" || exit 1
fi

# Set the tag if not provided.
if [ -z "${INPUT_TAG}" ]; then
  INPUT_TAG="release-$(date +%Y%m%d%H%M%S)"
fi

RELEASE_NOTES=$(gh api repos/:owner/:repo/releases/generate-notes -f tag_name="$INPUT_TAG" --jq '.body')

# Check if release notes exceeds GH char limit (currently 125k characters)
# We'll use 124k characters in case there are slight difference in the way
# GitHub calculates the character count.
NOTES_LENGTH=$(printf "%s" "$RELEASE_NOTES" | wc -c)

if [ "$NOTES_LENGTH" -gt 124000 ]; then
  echo "Release notes are ${NOTES_LENGTH} characters. Creating release with notes as attached file."
  
  echo "$RELEASE_NOTES" > "release-notes.md"
  
  gh release create "$INPUT_TAG" -t "${INPUT_TITLE}" --notes-file "release-notes.md"
else
  echo "Release notes are ${NOTES_LENGTH} characters. Creating release with notes in body."
  
  gh release create "$INPUT_TAG" -t "${INPUT_TITLE}" --notes "$RELEASE_NOTES"
fi
