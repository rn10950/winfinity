#!/bin/sh
mkdir output
FILES=./*.png
for f in $FILES
do
  convert $f -resize 78.125% output/$f
done