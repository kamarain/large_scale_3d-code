# Test CMake version
cmake_minimum_required(VERSION 2.8)

# The name of the project.
PROJECT(large-scale-3d)
SET(LARGESCALE3D_VERSION 0.0.0)

set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin )

add_subdirectory(src)
