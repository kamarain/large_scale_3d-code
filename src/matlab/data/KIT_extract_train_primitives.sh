#!/bin/bash
# This function runs the feature extraction binary for the generated
# stereo pairs (see make_train_stereo_pairs.sh). This function uses a
# training image list file similar to make_train_stereo_pairs.sh:
#
#  <wavefront_obj_file_full_path> <texture_png_file_full_path> <obj_name>
#
# <obj_name> will be used to name the output files
# Usage: prompt:~>source make_train_stereo_pairs.sh <train_obj_file> [<output_dir>]

tempwork_dir="TEMPWORK_KIT"
slam_config_skeleton="data/KIT_slam_config_skeleton_for_trainset.xml";
slam_bin="./slam";

echo " ";
echo "======================= EXTRACT_TRAIN_PRIMITIVES ======================="

printf "=> Using Slam config skeleton: $slam_config_skeleton \n";

if [ ! -e ${slam_config_skeleton} ]; then
    echo "Slam xml skeletong $slam_config_skeleton does not exist (check for .svn file)!!";
    echo "Try: source checklocal.bash in the ObjectDetection directory"
    return 1;
fi;

if [ $# -eq 0 ]; then
    echo "Not enough input arguments!";
    echo "Usage: source extract_train_primitives.sh <train_obj_file> [<tempwork_dir>]";
    echo " Example: source scripts/extract_train_primitives.sh config/kit_5k_tex_first_12.txt"
    return 1;
fi;

if [ $# -eq 1 ]; then
    tempwork_dir=${tempwork_dir%/}; # removes last slash if exists
    echo "=> Using default temporary work directory " $tempwork_dir;
fi;

if [ $# -eq 2 ]; then
    tempwork_dir=${2%/}; # removes last slash if exists
    echo $tempwork_dir;
fi;


while read -r lline
do
    if [[ ! "$lline" == "#"* ]]; then # Skip comment lines
	line_ar=( $lline );
	basename=${line_ar[2]};
	echo "----------- Processing ${basename} ----------------"
	mkdir -p "${tempwork_dir}/Slam_output_${basename}";
	sed -e "s/@BASENAME@/$basename/g" -e "s/@BASEDIR@/$tempwork_dir/g" $slam_config_skeleton > "${tempwork_dir}/Slam_config_${basename}_train.xml";
	$slam_bin --images "${tempwork_dir}/Slam_config_${basename}_train.xml" > "${tempwork_dir}/Slam_output_${basename}.log"
	echo "2D processing part:"
	grep "line segments created" "${tempwork_dir}/Slam_output_${basename}.log"
	echo "Stereo reconstruction processing part:"
	grep "many 3D segments have been created" "${tempwork_dir}/Slam_output_${basename}.log"
	grep "as a vector of 3D-" "${tempwork_dir}/Slam_output_${basename}.log"
    fi
done < $1

