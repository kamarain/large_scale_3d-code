# README #

All necessary source code, tools, shell scripts and Matlab scripts to replicate our 3D object recognitioin experiments.
For more detailed information, read the repository [Wiki](https://bitbucket.org/kamarain/large-scale-3d/wiki/Home)

The project is a joint effort of several research teams:

   1. [Vision Group](http://vision.cs.tut.fi) Tampere University of Technology
   2. [CARO group](http://caro.sdu.dk) University of Southern Denmark
   3. Company X

[TOC]

# Installation

The library contains various tools written in C++, Matlab and shell scripts. Mainly everything is compiled by default if all necessary libraries are available. See every separate section to make sure that you have the required libraries installed.

Fetch the repo:

If you choose to use ssh, you may first need to install a public key on your Bitbucket account, see [instruction](https://confluence.atlassian.com/display/BITBUCKET/How+to+install+a+public+key+on+your+Bitbucket+account), and then
```
$ hg clone ssh://hg@bitbucket.org/kamarain/large-scale-3d
```
Otherwise, you can fetch the repo through https with your account authorization 
```
$ hg clone https://UserName@bitbucket.org/kamarain/large-scale-3d
```

Skip this part, if you have VTK correctly installed in your system. Otherwise, please download and install it from [Here](http://www.vtk.org/VTK/resources/software.html). The version 5.10.1 works,but not the least version 6.1.0 due to some changes in function names.


Then build 
```
$ cd large-scale-3d
$ mkdir build
$ cd build/
$ cmake ..
$ make
```

If you get this error， “VTK not found. -> Not building render_stereo_pair.” You can set VTK_DIR in the file "<LARGE-SCALE-3D-DIR>/src/tools/CMakeLists.txt", by adding one line after "cmake_minimum_required(VERSION 2.6)". It looks like:
```
cmake_minimum_required(VERSION 2.6)

set(VTK_DIR "PATH/TO/VTK/BUILD/DIRECTORY")
```


That's it, you may now check the bin/ directory for test executables.

# Experiments

Experiments have been conducted using several different data sets. Read the corresponding sub-sections for more information.

## KIT Object Models dataset
![Knaeckebrot_stereo_left.png](https://bitbucket.org/repo/RAypKb/images/1661332118-Knaeckebrot_stereo_left.png)
![Knaeckebrot_stereo_left_el_-40.00_az_40.00_zo_1.00.png](https://bitbucket.org/repo/RAypKb/images/3063848940-Knaeckebrot_stereo_left_el_-40.00_az_40.00_zo_1.00.png)
### Data
First you need to fetch the KIT Object Models data from [http://i61p109.ira.uka.de/ObjectModelsWebUI/](http://i61p109.ira.uka.de/ObjectModelsWebUI/) - this can be done using the provided shell scripts (first move to your data directory):
```
$ cd <MY_DATA_DIR>
$ mkdir KIT_Object_Models; cd KIT_Object_Models
$ source <LARGE-SCALE-3D-DIR>/src/matlab/data/KIT_fetch_data.sh <LARGE-SCALE-3D-DIR>/src/matlab/data/KIT_classlist_<MOST_RECENT_DATE>.txt
$ source <LARGE-SCALE-3D-DIR>/src/matlab/data/KIT_remove_zips.sh <LARGE-SCALE-3D-DIR>/src/matlab/data/KIT_classlist_<MOST_RECENT_DATE>.txt
```
That will download 5.1GB of data (119 3D textured object models in the Wavefront OBJ format) and then the downloaded zip files are removed after extracting the models.

### Making training and testing set stereo pairs

For this one you need to have the [render_stereo_pair](https://bitbucket.org/kamarain/large-scale-3d/wiki/edit/Home#markdown-header-render_stereo_pair) compiled. Again, there are shell scripts that one by one read a 3D model, render a stereo pair in the requested pose and save images and their calibration matrices:
```
$ cd <LARGE-SCALE-3D-DIR>/src/matlab
$ ln -s <MY_DATA_DIR>/KIT_Object_Models/
$ source data/KIT_make_train_stereo_pairs.sh data/KIT_5k_tex_first_12.txt TEMPWORK_KIT
```
This is to test that everything works. Note that paths to binaries and lists of files to process assume that you have done everything as defined here. Now you may extract full set of KIT objects by:
```
$ source data/KIT_make_train_stereo_pairs.sh data/KIT_5k_tex.txt TEMPWORK_KIT
```
"5k" refers to the size of the 3D model. The sizes vary from 800 triangles to 25k. We have found 5k ok quality for our experiments. Next, you need to generate also the test set stereo pairs, i.e. the same objects but in different orientations with respect to the viewing camera:
```
$ source data/KIT_make_test_stereo_pairs.sh data/KIT_5k_tex_first_12.txt kit-lut_EAZ_20_nozoom TEMPWORK_KIT
```
The second term refers to the Elevation, Azimuth and Zoom as set in the vtkCamera object in the VTK library and the number defines the setting in degrees (the settings 5, 10, 20 and 40 are available by default and it is rather easy to extend any angles you wish!

Now, all necessary data for the next step is stored to the temporary working directory (TEMPWORK_KIT) and into the generated file listing the test images (e.g., KIT_5k_tex_first_12_EAZ_20_nozoom_test_set.txt).

### Extracting CoViS 3D primitives

This step requires the primitive extraction binary from the [CARO group](http://caro.sdu.dk) that is
included to their CoViS system. Until the new public version is ready, you need to use these binaries:

* [slam (Linux 64-bit)](https://bitbucket.org/kamarain/large-scale-3d/downloads/slam)

Download it to your matlab directory and make sure it has the execution permission.

The primitive extraction of the slam is based on the configurations given in the XML files:

* data/KIT_slam_config_skeleton_for_trainset.xml
* data/KIT_slam_config_skeleton_for_testset.xml

Since we don't want you to mess up the configuration files there are templates that you can check out using:
```
$ source ../../checklocal.bash
```

Then extract the training set and test set 3D primitives:
```
$ source data/KIT_extract_train_primitives.sh data/KIT_5k_tex_first_12.txt TEMPWORK_KIT
$ source data/KIT_extract_test_primitives.sh KIT_5k_tex_first_12_EAZ_20_nozoom_test_set.txt TEMPWORK_KIT
```
Note that the both scripts assume that the slam binary is in the src/matlab directory and you run the code
from that directory. Test test set image list is generated by the KIT_make_test_stereo_pairs.sh script.

You may now visualise the extracted 3D primitives using the CoViS wandererX program which again you need to download here until the new public CoViS version will be available:

* [wandererX (Linux 64-bit)](https://bitbucket.org/kamarain/large-scale-3d/downloads/wandererX)

Launch the program, take the "Primitive files" sheet, push the plus button and seek primitives3d*.wanderer files in the TEMPWORK_KIT/Slam_output_* directories and then select the loaded file! The primitives of the TEMPWORK_KIT/Slam_output_Amicelli/primitives3D_0.7_0.1_4.wanderer look by default as the following:

![shot0000.png](https://bitbucket.org/repo/RAypKb/images/34051852-shot0000.png)

Now, all data has been generated and you need to move to the Matlab part that is used for forming the object database models and matching observations (test set primitives) to the models.

### Running the Matlab recognition code

Requires the publicly available MVPRMATLAB functionality:
```
$ cd <MY_EXTERNAL_SOFTWARE_DIR>
$ hg clone ssh://hg@bitbucket.org/kamarain/mvprmatlab
```

Now, if you have followed this Wiki example the experiment with the first 12 KIT objects and against their 20 degrees rotated test examples everything should work out-of-the-box:
```
$ matlab
>> addpath <MY_EXTERNAL_SOFTWARE_DIR>/mvprmatlab
>> addpath base
>> kit_demo
```
The demo loads the training example primitives that form the object database and then one by one reads the test images, matches them to the database and reports the accuracy after each example. If you want to see more output how everything happens set *conf.debugLevel=1* or *conf.debugLevel=2* to see more detailed output what happens. All experiments in our publication can be replicated by altering the config file *kit_demo_conf.m* accordingly.

## City Scenes dataset

City Scenes Dataset that we internally call as the "Junsheng-NXM" datasets is a more realistic dataset of stereo street views. The dataset itself is not (yet?) publicly available, but here we provide a similar workflow to replicate our experiments with a few example images.

![primitive3d_system.png](https://bitbucket.org/repo/RAypKb/images/1595463889-primitive3d_system.png)

### Data

**TO BE ADDED** - when the data will be publicly available. A few images are made available to download:

* Download [Junsheng-2x4.tar.gz](https://bitbucket.org/kamarain/large-scale-3d/downloads/Junsheng-2x4.tar.gz)

```
$ cd <MY_DATA_DIR>
$ mkdir LargeScale3D
$ tar zxfv <MY_DOWNLOAD_DIR>/Junsheng-2x4.tar.gz
```

This sample data set contains four stereo pairs from two different scenes and calibration information for the stereo pairs of each. The stereo pair images are of rather high resolution and in order to speed up the processing we make a smaller versions of each image (which also affects to the calibration matrices) and for this purpose you should run the script *convert_small_junsheng.sh* as
```
$ cd <LARGE-SCALE-3D-DIR>/src/matlab
$ ln -s <MY_DATA_DIR>/LargeScale3D
$ source data/Junsheng_convert_small.sh ./LargeScale3D/Junsheng-2x4 ./LargeScale3D/Junsheng-2x4/train_data.txt
$ source data/Junsheng_convert_small.sh ./LargeScale3D/Junsheng-2x4 ./LargeScale3D/Junsheng-2x4/test_data.txt
```
Now you should have a half size, quarter size and even one eighth size images with correspoding calibration files. Note that the *train_data.txt* and *test_data.txt* file names are not correct, but you should fix them and rename, for example, train_data_halfsize.txt etc. The original image format is jpeg, but the converted images are in the PNG format to retain good quality. However, for the Junsheng-2x4 we provide you examples files data/Junsheng-2x4_train_quartersize.txt and data/Junsheng-2x4_test_quartersize.txt. You are ready to proceed to the next step.

### Extracting CoViS 3D primitives

Once again, you run the provided scripts to the training and testing images:
```
$ source data/Junsheng_extract_primitives.sh LargeScale3D/Junsheng-2x4 data/Junsheng-2x4_train_quartersize.txt TEMPWORK_Junsheng-2x4
$ source data/Junsheng_extract_primitives.sh LargeScale3D/Junsheng-2x4 data/Junsheng-2x4_test_quartersize.txt TEMPWORK_Junsheng-2x4
```
This will take some time, but eventually you'll have the 3D primitives extracted.

### Running the Matlab recognition code

This is pretty similar to the kit_demo.m, but since the default parameters for all funtions in base/ were set based on the KIT experiments we found that these are not necessarily optimal for the Junsheng images. Therefore the configuration file junsheng_demo_conf.m contains more settings. However, you can run the basic experiment with the provided code without changing anything:
```
$ matlab // or how I prefer $ nice matlab -nodesktop
>> addpath <MY_EXTERNAL_SOFTWARE_DIR>/mvprmatlab
>> addpath base
>> junsheng_demo1
```

That's it!

# Tools and executables

## render_stereo_pair

This executable can be used to render stereo pair images of textured 3D objects (Wavefront OBJ files tested).

Compiled with the default build if the [VTK library](http://www.vtk.org/) is found. Install (Ubuntu 12.04):

```
$ sudo apt-get install libvtk5.6 libvtk5-dev
```

You may run an interactive example by:
```
$ cd <LARGE-SCALE-3D-DIR>/build
$ ./bin/render_stereo_pair --model testdata/OrangeMarmelade_800_tex.obj --texture testdata/OrangeMarmelade_800_tex.png
```

The executable opens and interative window showing a 3D object.

![render_stereo_pair_example1.png](https://bitbucket.org/repo/RAypKb/images/115699256-render_stereo_pair_example1.png)

render_stereo_pair executable can be used to make stereo image pairs of given baseline. See the options (--help) for more information and the other sections of this wiki for the experiments run using this
tool.
