#!/bin/bash
# This function converts the large left and right images in the
# Junsheng dataset(s) to half and quarter size and edits the calibration
# matrices accordingly. The script takes two parameters:
# 
#  $ source scripts/convert_small_junsheng.sh <IMGDIR> <IMGLISTFILE>
#
# Example:
#
# $ source data/Junsheng_convert_small.sh ./LargeScale3D/Junsheng-2x4 ./LargeScale3D/Junsheng-2x4/train_data.txt
#
# The image list file must be of format:
#
# <classname> <leftimagepath> <rightimagepath> <calibfilepat>
#
# Paths are relative to <IMGDID> and the calibration file format must
# be exactly fixed (28 lines in total without line feed in the last line)

imgdir=$1
echo " ";
echo "======================= CONVERT IMAGES SMALLER ======================="

imgNo=0
while read -r lline
do
    if [[ ! "$lline" == "#"* ]]; then # Skip comment lines
	let "imgNo=$imgNo+1"
	printf "Image: %4d\r" "$imgNo"

	line_ar=( $lline );
	classname=${line_ar[0]};
	leftimg=${line_ar[1]};
	rightimg=${line_ar[2]};
	calibfile=${line_ar[3]};
	leftimgdir=`dirname $leftimg`
	leftimgfile=`basename $leftimg .jpg`
	rightimgdir=`dirname $rightimg`
	rightimgfile=`basename $rightimg .jpg`
	calibdir=`dirname $calibfile`
	calibfilename=`basename $calibfile .txt`

	#
	# create new calibration files
	
	# 1/2
	lineno=0;	
	rm -f $imgdir/$calibdir/$calibfilename"_halfsize.txt";
	while read -r line; do
	    let "lineno=$lineno+1";
	    if (($lineno==3 || $lineno==17)); then echo $line | gawk '{s1 = $1 / 2; s2 = $2 / 2; print s1" "s2}' >> $imgdir/$calibdir/$calibfilename"_halfsize.txt";
	    elif (($lineno==5 || $lineno==19)); then echo $line | gawk '{s1 = $1 / 2; s2 = $3 / 2; print s1" "$2" "s2}' >> $imgdir/$calibdir/$calibfilename"_halfsize.txt";
	    elif (($lineno==6 || $lineno==20)); then echo $line | gawk '{s1 = $2 / 2; s2 = $3 / 2; print $1" "s1" "s2}' >> $imgdir/$calibdir/$calibfilename"_halfsize.txt"; else
		echo $line >> $imgdir/$calibdir/$calibfilename"_halfsize.txt";
	    fi;
	done < $imgdir/$calibfile

	# 1/4
	lineno=0;	
	rm -f $imgdir/$calibdir/$calibfilename"_quartersize.txt";
	while read -r line; do
	    let "lineno=$lineno+1";
	    if (($lineno==3 || $lineno==17)); then echo $line | gawk '{s1 = $1 / 4; s2 = $2 / 4; print s1" "s2}' >> $imgdir/$calibdir/$calibfilename"_quartersize.txt";
	    elif (($lineno==5 || $lineno==19)); then echo $line | gawk '{s1 = $1 / 4; s2 = $3 / 4; print s1" "$2" "s2}' >> $imgdir/$calibdir/$calibfilename"_quartersize.txt";
	    elif (($lineno==6 || $lineno==20)); then echo $line | gawk '{s1 = $2 / 4; s2 = $3 / 4; print $1" "s1" "s2}' >> $imgdir/$calibdir/$calibfilename"_quartersize.txt"; else
		echo $line >> $imgdir/$calibdir/$calibfilename"_quartersize.txt";
	    fi;
	done < $imgdir/$calibfile

	# 1/8
	lineno=0;	
	rm -f $imgdir/$calibdir/$calibfilename"_oneeighthsize.txt";
	while read -r line; do
	    let "lineno=$lineno+1";
	    if (($lineno==3 || $lineno==17)); then echo $line | gawk '{s1 = $1 / 8; s2 = $2 / 8; print s1" "s2}' >> $imgdir/$calibdir/$calibfilename"_oneeighthsize.txt";
	    elif (($lineno==5 || $lineno==19)); then echo $line | gawk '{s1 = $1 / 8; s2 = $3 / 8; print s1" "$2" "s2}' >> $imgdir/$calibdir/$calibfilename"_oneeighthsize.txt";
	    elif (($lineno==6 || $lineno==20)); then echo $line | gawk '{s1 = $2 / 8; s2 = $3 / 8; print $1" "s1" "s2}' >> $imgdir/$calibdir/$calibfilename"_oneeighthsize.txt"; else
		echo $line >> $imgdir/$calibdir/$calibfilename"_oneeighthsize.txt";
	    fi;
	done < $imgdir/$calibfile

	# write the last line (assuming now newline and thus outside loop)
	if [[ $lineno == 28 ]] || [[ $lineno == 29 ]]; then
	    echo $line >> $imgdir/$calibdir/$calibfilename"_halfsize.txt";
	    echo $line >> $imgdir/$calibdir/$calibfilename"_quartersize.txt";
	    echo $line >> $imgdir/$calibdir/$calibfilename"_oneeighthsize.txt";
	else
	    echo "Number of lines " $lineno " does not match!"
	    echo $imgdir/$calibfile "-- Something wrong in structure";
	    return -1;
	fi;

	#
	# create new image files

	convert -geometry 50%x50% $imgdir/$leftimg $imgdir/$leftimgdir/$leftimgfile"_halfsize.png"
	convert -geometry 25%x25% $imgdir/$leftimg $imgdir/$leftimgdir/$leftimgfile"_quartersize.png"
	convert -geometry 12.5%x12.5% $imgdir/$leftimg $imgdir/$leftimgdir/$leftimgfile"_oneeighthsize.png"
	convert -geometry 50%x50% $imgdir/$rightimg $imgdir/$rightimgdir/$rightimgfile"_halfsize.png"
	convert -geometry 25%x25% $imgdir/$rightimg $imgdir/$rightimgdir/$rightimgfile"_quartersize.png"
	convert -geometry 12.5%x12.5% $imgdir/$rightimg $imgdir/$rightimgdir/$rightimgfile"_oneeighthsize.png"
	lineno=0;
    fi
done < $2
printf "\n"

echo "=======================       DONE             ======================="

