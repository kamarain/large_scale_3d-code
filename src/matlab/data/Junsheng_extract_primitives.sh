#!/bin/bash
# This function extract ECV primitives from given image pairs. Usage
# source scripts/extract_primitives_junsheng.sh <IMGDIR> <IMGLISTFILE> <TEMPDIR>
#
# Example:
#  
#  <wavefront_obj_file_full_path> <texture_png_file_full_path> <obj_name>
#
# <obj_name> will be used to name the output files
# Usage: prompt:~>source make_train_stereo_pairs.sh <train_obj_file> [<output_dir>]

tempwork_dir="TEMPWORK_Junsheng"
slam_config_skeleton="data/Junsheng_slam_config_skeleton.xml";
slam_bin="./slam";

echo " ";
echo "======================= EXTRACT_TRAIN_PRIMITIVES ======================="

printf "=> Using Slam config skeleton: $slam_config_skeleton \n";

if [ ! -e ${slam_config_skeleton} ]; then
    echo "Slam xml skeletong $slam_config_skeleton does not exist (check for .svn file)!!";
    echo "Try: source checklocal.bash in the ObjectDetection directory"
    return 1;
fi;

if [ $# -eq 0 ] || [ $# -eq 1 ]; then
    echo "Not enough input arguments!";
    echo "Usage: source extract_primitives_junsheng.sh <IMGDIR> <IMGLISTFILE> [<TEMPDIR>]";
    echo " Example: source scripts/extract_primitives_junsheng.sh  ./LargeScale3D/Junsheng-12x4 config/Junsheng-12x4_train.txt TEMPWORK_Junsheng-12x4"
    return 1;
fi;

if [ $# -eq 2 ]; then
    tempwork_dir=${tempwork_dir%/}; # removes last slash if exists
    echo "=> Using default temporary work directory " $tempwork_dir;
fi;

if [ $# -eq 3 ]; then
    tempwork_dir=${3%/}; # removes last slash if exists
    echo $tempwork_dir;
fi;

imgdir=$1

while read -r lline
do
    if [[ ! "$lline" == "#"* ]]; then # Skip comment lines
	line_ar=( $lline );
	classname=${line_ar[0]};
	leftimg=${line_ar[1]};
	rightimg=${line_ar[2]};
	calibfile=${line_ar[3]};
	# take image name despite the extension (.jpg .png etc.)
	filename=$(basename "$leftimg")
	extension="${filename##*.}"
	leftimgfile="${filename%.*}"
	filename=$(basename "$rightimg")
	extension="${filename##*.}"
	rightimgfile="${filename%.*}"
	#leftimgfile=`basename $leftimg .jpg`
	#rightimgfile=`basename $rightimg .jpg`
	classid="${classname}_${leftimgfile}_${rightimgfile}";
	echo "----------- Processing ${classid} ----------------"
	mkdir -p "${tempwork_dir}/Slam_output_${classid}";
	# Note that forward slash / replaced with pipe | since the variables
	# contain / in the path names and that makes sed crazy
	sed -e "s|@IMGDIR@|$imgdir|g" -e "s|@TEMPWORKDIR@|$tempwork_dir|g" -e "s|@CLASSID@|$classid|g" -e "s|@LEFTIMAGE@|$leftimg|g" -e "s|@RIGHTIMAGE@|$rightimg|g" -e "s|@CALIBFILE@|$calibfile|g" $slam_config_skeleton > "${tempwork_dir}/Slam_config_${classid}_train.xml";
	$slam_bin --images "${tempwork_dir}/Slam_config_${classid}_train.xml" > "${tempwork_dir}/Slam_output_${classid}.log"
	echo "2D processing part:"
	grep "line segments created" "${tempwork_dir}/Slam_output_${classid}.log"
	echo "Stereo reconstruction processing part:"
	grep "many 3D segments have been created" "${tempwork_dir}/Slam_output_${classid}.log"
	grep "as a vector of 3D-" "${tempwork_dir}/Slam_output_${classid}.log"
    fi
done < $2

