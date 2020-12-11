#!/bin/sh
# Fetches the packages and unzips them to corresponding directories
# Usage ~>source fecth_images.sh <class_list_file>

while read -r lline
do
    printf "                \n";
    printf "*** Fetching %s ...\n" $lline;
    printf "                \n";

    if [ -d "objects/$lline/meshes" ]; then
	printf "   ... already there!\n";
    else
	mkdir -p "objects/$lline"
	wget -O - http:\/\/i61p109.ira.uka.de\/ObjectModelsWebUI\/tmp.php\?id\=1\&kat\=DCMeshes\&dp=Objects\/$lline\/meshes.zip > objects/$lline/meshes.zip;
	unzip -o objects/$lline/meshes.zip -d objects/$lline;
	printf "                \n";
	printf "*** Done     %s !\n" $lline;
	printf "                \n";
    fi
done < $1