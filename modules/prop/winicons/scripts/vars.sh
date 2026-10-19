#!/bin/bash
iR="/reinstall/new-winfinity/modules/prop/winicons/Winfinity-Classic"

# remove icon entirely (useful for apps)
# EX: removeIcon category icontoremove
function removeIcon {
  for dir in $iR/$1/*/; do
    rm -v "$dir$2"
  done
}

# change icon function
# EX: changeicon category newiconsource oldicontoreplace
function changeIcon {
  for dir in $iR/$1/*/; do
    cp -v "$dir$2" "$dir$3"
  done
}

# change icon across category
# EX: crossCatReplaceIcon category newiconsource category2 oldicontoreplace
function crossCatReplaceIcon {
  for dir in $iR/$1/*/; do
    size=$(basename "$dir")
    cp -v "$dir$2" "$iR/$3/$size/$4"
  done
}