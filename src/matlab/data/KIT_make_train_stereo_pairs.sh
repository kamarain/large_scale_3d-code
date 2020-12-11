#!/bin/sh
# This function generates stereo pairs for examples in the given
# training list file using the view mode 1 of "render_3d_object"
# - the training list file should containg one object per line:
#
#  <wavefront_obj_file_full_path> <texture_png_file_full_path> <obj_name>
#
# <obj_name> will be used to name the output files
# Usage: prompt:~>source make_train_stereo_pairs.sh <train_obj_file> <output_dir>
# Default <output_dir> is "TEMPWORK_KIT" (you can also use symlink to redirect)

tempwork="TEMPWORK_KIT"
render_bin="../../build/bin/render_stereo_pair"

if [ $# -eq 0 ]; then
    echo "Not enough input arguments!";
    echo "Usage: source make_train_stereo_pairs.sh <train_obj_file> [<tempwork_dir>]";
    echo " Example: source scripts/make_train_stereo_pairs.sh config/kit_5k_tex_first_12.txt";
    return 1;
fi;

if [ $# -eq 1 ]; then
    tempwork_dir=${tempwork%/}; # removes last slash if exists
    echo "Using default temporary work directory " $tempwork_dir;
fi;

if [ $# -eq 2 ]; then
    tempwork_dir=${2%/}; # removes last slash if exists
    echo $tempwork_dir;
fi;

mkdir -p $tempwork_dir


while read -r lline
do
    if [[ ! "$lline" == "#"* ]]; then # Skip comment lines
	line_ar=( $lline );
	$render_bin \
	    --model ${line_ar[0]} --texture ${line_ar[1]} \
	    --view_mode 1 --bboutput $tempwork_dir/${line_ar[2]}_render_bbox.dat \
	    --distoutput $tempwork_dir/${line_ar[2]}_render_dist.dat \
	    --cam_mat_output $tempwork_dir/${line_ar[2]}_render_cam_mat.dat --cam_img_output $tempwork_dir/${line_ar[2]}_render_cam_img.png 
    fi
done < $1

