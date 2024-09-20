#!/bin/sh

# Navigate to the specified work directory, if provided.
if [ -n "${INPUT_WORKDIR}" ]; then
  cd "${INPUT_WORKDIR}" || exit 1
fi

# Set the tag if not provided.
if [ -z "${INPUT_TAG}" ]; then
  INPUT_TAG="release-$(date +%Y%m%d%H%M%S)"
fi

# Capture notes in a variable to potentially write them to a file later.

# Attempt to create the release.
RESPONSE=$(gh release create "$INPUT_TAG" -t "${INPUT_TITLE}" --generate-notes 2>&1)
STATUS=$?

# Check if the release creation failed due to body being too long (HTTP 422).
if [ $STATUS -ne 0 ] && echo "$RESPONSE" | grep -q "422"; then
  echo "Release notes are too long. Publishing again with release notes as a file."

  # Fetch the release details.
  RELEASE=$(gh release view --json body,name,id,tagName)
  TAG_NAME=$(printf "%s" "$RELEASE" | jq -r ".tagName")
  RELEASE_NOTES=$(printf "%s" "$RELEASE" | jq -r ".body")

  # Write the release notes to a file.
  echo "$RELEASE_NOTES" > "${TAG_NAME}.md"

  # Retry release creation with release notes attached as a markdown file.
  gh release create "$INPUT_TAG" -t "${INPUT_TITLE}" --notes-file "${TAG_NAME}".md
else
  echo "$RESPONSE"
fi
