#!/bin/sh
# Removes the zip files stored by fecth_images.sh
# Usage ~>source remove_zips.sh <class_list_file>

while read -r lline
do
    if [ -e "objects/$lline/meshes.zip" ]; then
	printf "rm objects/$lline/meshes.zip\n";
	rm objects/$lline/meshes.zip;
fi
done < $1