cmake_minimum_required(VERSION 2.6)
 
#PROJECT(ObjectDetection)
 
FIND_PACKAGE(VTK QUIET)
IF (VTK_FOUND)
  INCLUDE(${VTK_USE_FILE})
 
  ADD_EXECUTABLE(render_stereo_pair render_stereo_pair.cpp)
  TARGET_LINK_LIBRARIES(render_stereo_pair vtkHybrid)
  TARGET_LINK_LIBRARIES(render_stereo_pair vtkmetaio)

  set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "render_stereo_pair_bbox_vtk_left_camera_frame.dat;render_stereo_pair_bbox_vtk_world.dat;render_stereo_pair_cam_img_left.png;render_stereo_pair_cam_img_right.png;render_stereo_pair_cam_mat_CoViS_canonic.dat;render_stereo_pair_dist_orig.dat")
ELSE (VTK_FOUND)
  MESSAGE(STATUS "VTK not found. -> Not building render_stereo_pair.")
ENDIF (VTK_FOUND)

add_custom_command(TARGET render_stereo_pair PRE_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
  ${CMAKE_CURRENT_SOURCE_DIR}/testdata ${CMAKE_BINARY_DIR}/testdata)


## Define test files needed to test executables
#file(GLOB BinTestFiles testdata/OrangeMarmelade_800_tex.obj
#  testdata/OrangeMarmelade_800_tex.png)
#
#foreach(BinTestFile ${BinTestFiles})
#  add_custom_command(TARGET render_stereo_pair POST_BUILD
#    COMMAND ${CMAKE_COMMAND} -E
#    copy ${BinTestFile} ${CMAKE_BINARY_DIR}/${BinTestFile})
#endforeach()