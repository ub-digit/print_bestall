#!/bin/bash

#filesDir="../html/MoveFiles/exp"
rePrintFileList=$1
appDir=$2
filesDir="${appDir}/files"
files=$(<${rePrintFileList})

while read -r file
do
	((no_of_files++))
	file="$(echo -e "${file}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	mv "${filesDir}/done/$file" "${filesDir}/"
done <<<"$files"

if [[ $no_of_files == 1 ]]; then
	fil="fil"
else
	fil="filer"
fi
echo "$no_of_files $fil skrivs ut."

rm "${rePrintFileList}"