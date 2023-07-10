#!/usr/bin/env bash

# Set the commit files to update
COMMIT_FILES="example/cpp/CMakeLists.txt example/uwp/extension.vsixmanifest example/uwp/Telegram.Td.UWP.nuspec README.md td/telegram/OptionManager.cpp"

# Check if there is an "-i" argument to drop all fixed files list
if [[ "$*" == *-i* ]]; then
  COMMIT_FILES=""
fi

# Find the old and new TDLib versions
SED_REGEX="project\(TDLib VERSION ([0-9\.]+) LANGUAGES CXX C\)"
GIT_DIFF=$(git --no-pager diff --unified=0 CMakeLists.txt)
OLD_TDLIB_VERSION=$(echo "${GIT_DIFF}" | sed -nr "s/\-$SED_REGEX/\1/p")
NEW_TDLIB_VERSION=$(echo "${GIT_DIFF}" | sed -nr "s/\+$SED_REGEX/\1/p")

# If a new TDLib version was found, update the commit files
if [[ -n "${OLD_TDLIB_VERSION}" ]] && [[ -n "${NEW_TDLIB_VERSION}" ]] && [[ "${OLD_TDLIB_VERSION}" != "${NEW_TDLIB_VERSION}" ]]; then
  for arg in "$@"; do
    if [[ "$arg" != "-i" ]] && [[ ! -e "$arg" ]]; then
      echo "$arg: No such file or directory"
      exit 1
    fi
  done

  for arg in "$@"; do
    if [[ "$arg" != "-i" ]] && [[ -e "$arg" ]]; then
      COMMIT_FILES="$COMMIT_FILES $arg"
    fi
  done

  if [[ -z "${COMMIT_FILES}" ]]; then
    echo "No files to update."
    exit 1
  fi

  # Replace all matches
  sed -i "s/${OLD_TDLIB_VERSION//./\\.}/${NEW_TDLIB_VERSION}/g" $COMMIT_FILES || exit 1

  # Show the diff and prompt the user to commit the changes
  git --no-pager diff CMakeLists.txt $COMMIT_FILES
  read -p "Commit \"Update version to ${NEW_TDLIB_VERSION}.\" (y/n)? " answer

  if [[ "${answer}" == [yY] ]]; then
    git commit -n CMakeLists.txt $COMMIT_FILES -m "Update version to ${NEW_TDLIB_VERSION}." && echo
    git --no-pager log --stat -n 1
  else
    # Undo sed changes
    sed -i "s/${NEW_TDLIB_VERSION//./\\.}/${OLD_TDLIB_VERSION}/g" $COMMIT_FILES || exit 1
    echo "Aborted."
    exit 1
  fi
else
  echo "Couldn't find new TDLib version."
fi
