#!/bin/bash

# Author: Pekka Paalanen, 2005

# template file suffix
SUFF=".template"

# root of working directory tree, defaults to cwd
DIR=.

# command to compare two files
DIFFCMD="diff -u"

DODIFF=no
while [[ "$1" ]]; do
	case "$1" in
	--help)
		echo "Usage: $0 [--diff] [path]"
		echo "Finds the files \`*$SUFF' from \`path' (the default is"\
		"cwd) and subdirs, and"
		echo "makes local copies without \`$SUFF' suffix, if they do"\
		"not exist."
		echo "If the local copy is older than the original, it is"\
		"reported."
		echo "If \`--diff' is defined and local copy exists, the"\
		"differences are shown"
		echo "with command \`$DIFFCMD'."
		exit
		;;
	--diff)
		DODIFF=yes
		;;
	*)
		DIR="$1"
		;;
	esac
	shift
done


find "$DIR" -follow -type f -name "*$SUFF" | \
while read -r f
do
	if [[ -e "${f%$SUFF}" ]]; then
		if [[ "$f" -nt "${f%$SUFF}" ]]; then
			echo " * File \`$f' is newer than \`${f%$SUFF}'."
		fi
		if [[ $DODIFF == yes ]]; then
			$DIFFCMD "$f" "${f%$SUFF}"
		fi
	else
		echo " * Copying \`$f' to \`${f%$SUFF}'."
		cp -i "$f" "${f%$SUFF}"
	fi
done


