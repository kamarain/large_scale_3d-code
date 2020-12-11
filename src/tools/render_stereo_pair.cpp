/*
 * @brief Executable to generate stereo views of KIT objects
 *        and store camera matrices.
 *
 * This function was used to generate training and testing images in
 * ref. [1]. Note that there exist shell scripts to generate the images
 * more conveniently.
 *
 * Copyright (c)
 *      Cognitive Vision Laboratory, SDU <norbert@mmmi.sdu.dk>
 *      Joni Kamarainen <Joni.Kamarainen@lut.fi>
 *
 * References:
 *  [1] Kamarainen, J.-K., Buch, A.G., Krueger, N., 3D Object Detection
 *      Using Accumulated Early Vision Primitives, submitted.
 *  [2] Hartley, R., and Zisserman, A., Multiple View Geometry in Computer
 *      Vision, 2003.
 */

/* -*- c-file-style: "bsd" -*- */

#include <string>
#include <cmath>

#include <vtkmetaio/metaCommand.h>
#include <vtkSmartPointer.h>
#include <vtkPNGReader.h>
#include <vtkPolyDataMapper.h>
#include <vtkImageData.h>
#include <vtkTexture.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkActor.h>
#include <vtkOBJReader.h>
#include <vtkCamera.h>
#include <vtkTransform.h>
#include <vtkMatrix4x4.h>
#include <vtkWindowToImageFilter.h>
#include <vtkPNGWriter.h>

using std::isnan;

// internal functions
void DisplayAndStoreStereo(vtkRenderer *renderer, vtkPNGWriter *pNGWriter,
                           vtkWindowToImageFilter *imageFilter,
                           const double baseLine,
                           const std::string &cam_mat_file,
                           const std::string &cam_img_file,
                           const double bbox[][8], const std::string &bbox_file);
void CanonicStereoCameraMatrix_CoViS(const int sz[], const double fov,
                                     const double baseLine, const short leftView,
                                     double K[][3], double R[][3], double t[], double k[]);
void SaveStereoCalibrationOpenCV(const int sz_l[], const int sz_r[],
                                 const double K_l[][3], const double K_r[][3],
                                 const double R_l[][3], const double R_r[][3],
                                 const double t_l[], const double t_r[],
                                 const double k_l[], const double k_r[],
                                 const std::string &fileName);
void ConstructCameraMatrixVTK(vtkRenderer *renderer, double camMatr[][4]);
void ConstructCameraMatrixCoViS(vtkRenderer *renderer, double camMatr[][4]);
std::string AddPostDefToFilename(std::string filename, const char *preDef);
int MainParseCommandLine( vtkmetaio::MetaCommand& command,
                          int argc, char **const argv);

/**
 * @brief main ist main, donnerwetter! *
 **/
int main ( int argc, char *argv[] ) {

   // Command line parsing - see the sub func for details
   vtkmetaio::MetaCommand command;
   if (MainParseCommandLine(command, argc, argv)) {
      return EXIT_FAILURE;
   }

   int debugMode = command.GetValueAsInt("debug_mode", "mode");

   // Read obj file (-> poly data) => triangulated 3D model
   vtkSmartPointer<vtkOBJReader> reader =
      vtkSmartPointer<vtkOBJReader>::New();
   reader->SetFileName(command.GetValueAsString("model", "file").c_str());
   reader->Update();

   // Map poly data to graphics => "Object"
   vtkSmartPointer<vtkPolyDataMapper> mapper =
      vtkSmartPointer<vtkPolyDataMapper>::New();
   mapper->SetInputConnection(reader->GetOutputPort());

   // Read the texture image => Textured object
   vtkSmartPointer<vtkPNGReader> pNGReader =
      vtkSmartPointer<vtkPNGReader>::New();
   vtkSmartPointer<vtkTexture> texture =
      vtkSmartPointer<vtkTexture>::New();
   if (command.GetOptionWasSet("texture")) {
      pNGReader->SetFileName (command.GetValueAsString("texture", "file").c_str());
      texture->SetInput(pNGReader->GetOutput());
   } else
      cout << "[NOTE] No texture given and thus rendering shape only." << std::endl;

   // Map poly data and texture to textured quads (triangles mostly) => object
   vtkSmartPointer<vtkActor> texturedQuad =
      vtkSmartPointer<vtkActor>::New();
   texturedQuad->SetMapper(mapper);
   texturedQuad->SetTexture(texture); // should appear if loaded

   // Set object orientation and center it according to its bounding box (assumes no outliers)
   texturedQuad->SetOrientation(command.GetValueAsFloat("objorientation", "x"),
                                command.GetValueAsFloat("objorientation", "y"),
                                command.GetValueAsFloat("objorientation", "z"));
   double *quadCenter = texturedQuad->GetCenter();
   texturedQuad->SetPosition(-quadCenter[0], -quadCenter[1], -quadCenter[2]);
   double bounds[6];
   texturedQuad->GetBounds(bounds); // store for visualisation

   // Construct and store the bounding box vertex coordinates (world coordinates)
   double bbox[3][8];
   bbox[0][0] = bounds[0];
   bbox[1][0] = bounds[2];
   bbox[2][0] = bounds[4]; //(xmin,ymin,zmin)
   bbox[0][1] = bounds[1];
   bbox[1][1] = bounds[2];
   bbox[2][1] = bounds[4]; //(xmax,ymin,zmin)
   bbox[0][2] = bounds[0];
   bbox[1][2] = bounds[3];
   bbox[2][2] = bounds[4]; //(xmin,ymax,zmin)
   bbox[0][3] = bounds[0];
   bbox[1][3] = bounds[2];
   bbox[2][3] = bounds[5]; //(xmin,ymin,zmax)
   bbox[0][4] = bounds[1];
   bbox[1][4] = bounds[3];
   bbox[2][4] = bounds[4]; //(xmax,ymax,zmin)
   bbox[0][5] = bounds[1];
   bbox[1][5] = bounds[2];
   bbox[2][5] = bounds[5]; //(xmax,ymin,zmax)
   bbox[0][6] = bounds[0];
   bbox[1][6] = bounds[3];
   bbox[2][6] = bounds[5]; //(xmin,ymax,zmax)
   bbox[0][7] = bounds[1];
   bbox[1][7] = bounds[3];
   bbox[2][7] = bounds[5]; //(xmax,ymax,zmax)
   std::ofstream bBFile;
   bBFile.open(AddPostDefToFilename(command.GetValueAsString("bboutput", "file"), "_vtk_world").data());
   bBFile << bbox[0][0] << " " << bbox[1][0] << " " << bbox[2][0] << std::endl;
   bBFile << bbox[0][1] << " " << bbox[1][1] << " " << bbox[2][1] << std::endl;
   bBFile << bbox[0][2] << " " << bbox[1][2] << " " << bbox[2][2] << std::endl;
   bBFile << bbox[0][3] << " " << bbox[1][3] << " " << bbox[2][3] << std::endl;
   bBFile << bbox[0][4] << " " << bbox[1][4] << " " << bbox[2][4] << std::endl;
   bBFile << bbox[0][5] << " " << bbox[1][5] << " " << bbox[2][5] << std::endl;
   bBFile << bbox[0][6] << " " << bbox[1][6] << " " << bbox[2][6] << std::endl;
   bBFile << bbox[0][7] << " " << bbox[1][7] << " " << bbox[2][7] << std::endl;
   bBFile.close();

   // Setup renderer
   vtkSmartPointer<vtkRenderer> renderer =
      vtkSmartPointer<vtkRenderer>::New();
   renderer->AddActor(texturedQuad);
   renderer->SetBackground(command.GetValueAsFloat("bgcolour", "r"),
                           command.GetValueAsFloat("bgcolour", "g"),
                           command.GetValueAsFloat("bgcolour", "b"));

   // Setup window for the renderer
   vtkSmartPointer<vtkRenderWindow> renderWindow =
      vtkSmartPointer<vtkRenderWindow>::New();
   renderWindow->AddRenderer(renderer);
   renderWindow->SetSize(command.GetValueAsInt("image_size", "width"),
                         command.GetValueAsInt("image_size", "height"));

   // Setup also filter for writing the images to a file
   vtkSmartPointer<vtkWindowToImageFilter> imageFilter =
      vtkSmartPointer<vtkWindowToImageFilter>::New();
   imageFilter->SetInput(renderWindow);
   vtkSmartPointer<vtkPNGWriter> pNGWriter =
      vtkSmartPointer<vtkPNGWriter>::New();
   pNGWriter->SetInputConnection(imageFilter->GetOutputPort());

   // Do the camera
   vtkCamera *camera = vtkCamera::New();
   //vtkCamera *camera = renderer->MakeCamera(); something weird happens to units with this
   camera->ParallelProjectionOff();
   camera->SetViewAngle(command.GetValueAsFloat("view_angle", "angle"));
   renderer->SetActiveCamera(camera);
   renderer->ResetCamera();

   // Set the camera position on the neg. z axis (pointing to the origin)
   double camPos[3];
   camera->GetPosition(camPos);
   if (command.GetValueAsFloat("camera_distance", "distance") == -1) {
      // Set position based on the bounding box dimensions (note that bb now in the origin)
      double bbDiagonal = sqrt((bounds[1] - bounds[0]) * (bounds[1] - bounds[0]) +
                               (bounds[3] - bounds[2]) * (bounds[3] - bounds[2]) +
                               (bounds[5] - bounds[4]) * (bounds[5] - bounds[4]));
      // Put camera to negative z-axis (compatibility with CoViS and OpenCV coord. systems)
      // minimum distance to fit the diagonal + 10%
      camera->SetPosition(0, 0, -1.1*bbDiagonal / 2 / tan(camera->GetViewAngle()*M_PI / 180 / 2));
   } else { // User given
      camera->SetPosition(0, 0, -command.GetValueAsFloat("camera_distance", "distance"));
   }
   renderer->ResetCameraClippingRange();
   camera->GetPosition(camPos);
   std::ofstream distFile;
   distFile.open(AddPostDefToFilename(command.GetValueAsString("distoutput", "file"), (const char *)"_orig").data());
   distFile << camPos[0] << " " << camPos[1] << " " << camPos[2] << std::endl;
   double viewPlaneNormal[3];
   camera->GetViewPlaneNormal(viewPlaneNormal); // store this just in case
   distFile << viewPlaneNormal[0] << " " << viewPlaneNormal[1] << " " << viewPlaneNormal[2] << std::endl;

   // Produce views and images based on the view mode

   // view mode 0 (interactive)
   if (command.GetValueAsInt("view_mode", "mode") == 0) {

      // Hook rendering window with the iteraction module
      vtkSmartPointer<vtkRenderWindowInteractor> renderWindowInteractor =
         vtkSmartPointer<vtkRenderWindowInteractor>::New();
      renderWindowInteractor->SetRenderWindow(renderWindow);
      // Start the show
      renderWindowInteractor->Start();

   } // end of interactive mode


   // view mode 1 (frontal stereo)
   if (command.GetValueAsInt("view_mode", "mode") == 1) {
      DisplayAndStoreStereo(renderer, pNGWriter,
                            imageFilter,
                            command.GetValueAsFloat("stereo_baseline", "baseline"),
                            command.GetValueAsString("cam_mat_output", "file"),
                            command.GetValueAsString("cam_img_output", "file"),
                            bbox, command.GetValueAsString("bboutput", "file"));
   } // end of frontal stereo mode

   // view mode 2 (elevation/azimuth/zoom) - NOTE: zoom not tested
   if (command.GetValueAsInt("view_mode", "mode") == 2) {

      double canonicPosition[3];
      camera->GetPosition(canonicPosition);
      double canonicViewUp[3];
      camera->GetViewUp(canonicViewUp);
      double focalPoint[3];
      camera->GetFocalPoint(focalPoint);

      //
      // Iterate through all combinations of elevation, azimuth and zoom
      float elevation[5];
      elevation[0] = command.GetValueAsFloat("elevation", "val1");
      elevation[1] = command.GetValueAsFloat("elevation", "val2");
      elevation[2] = command.GetValueAsFloat("elevation", "val3");
      elevation[3] = command.GetValueAsFloat("elevation", "val4");
      elevation[4] = command.GetValueAsFloat("elevation", "val5");
      float azimuth[5];
      azimuth[0] = command.GetValueAsFloat("azimuth", "val1");
      azimuth[1] = command.GetValueAsFloat("azimuth", "val2");
      azimuth[2] = command.GetValueAsFloat("azimuth", "val3");
      azimuth[3] = command.GetValueAsFloat("azimuth", "val4");
      azimuth[4] = command.GetValueAsFloat("azimuth", "val5");
      float zoom[5];
      zoom[0] = command.GetValueAsFloat("zoom", "val1");
      zoom[1] = command.GetValueAsFloat("zoom", "val2");
      zoom[2] = command.GetValueAsFloat("zoom", "val3");
      zoom[3] = command.GetValueAsFloat("zoom", "val4");
      zoom[4] = command.GetValueAsFloat("zoom", "val5");

      std::string iterImg;
      std::string iterCam;
      std::string iterBbox;
      for (int dind = 0; dind < 5; dind++) {
         if (isnan(zoom[dind])) {
            continue;
         }
         if (zoom[dind] != 1.0) {
            std::cout << "--> WARNING: Zoom values other than 1.0 NOT TESTED <--" << std::endl;
         }
         for (int eind = 0; eind < 5; eind++) {
            if (isnan(elevation[eind])) {
               continue;
            }
            for (int aind = 0; aind < 5; aind++) {
               if (isnan(azimuth[aind])) {
                  continue;
               }
               camera->Elevation(elevation[eind]);
               camera->Azimuth(azimuth[aind]);
               camera->Zoom(zoom[dind]);
               camera->OrthogonalizeViewUp(); // Needs to be done after azimuth

               // Construct iteration specific names (prefixes)
               char iterStr[64];
               sprintf(iterStr, "_el_%4.2f_az_%4.2f_zo_%4.2f", elevation[eind], azimuth[aind], zoom[dind]);
               iterImg = AddPostDefToFilename(command.GetValueAsString("cam_img_output", "file"), iterStr);
               iterCam = AddPostDefToFilename(command.GetValueAsString("cam_mat_output", "file"), iterStr);
               iterBbox = AddPostDefToFilename(command.GetValueAsString("bboutput", "file"), iterStr);

               DisplayAndStoreStereo(renderer, pNGWriter,
                                     imageFilter,
                                     command.GetValueAsFloat("stereo_baseline", "baseline"),
                                     iterCam, iterImg,
                                     bbox, iterBbox);

               // Reset position and zoom to original for next values to be consistent
               camera->Zoom(1 / zoom[dind]);
               camera->SetPosition(canonicPosition);
               camera->SetViewUp(canonicViewUp);
               camera->SetFocalPoint(focalPoint);
               camera->OrthogonalizeViewUp(); // Needs to be done after azimuth
            }
         }
      }
   } // end of view mode 2 (elevation/azimuth/zoom)

   return EXIT_SUCCESS;
}

/**
 * @brief Displays and stores left and right stereo images and stores their camera
 *        matrices
 **/
void DisplayAndStoreStereo(vtkRenderer *renderer, vtkPNGWriter *pNGWriter,
                           vtkWindowToImageFilter *imageFilter,
                           const double baseLine,
                           const std::string &cam_mat_file,
                           const std::string &cam_img_file,
                           const double bbox[][8], const std::string &bbox_file) {

   // For the baseline movement we need to solve the world direction of the camera x-axis (kind of a hack)
   vtkCamera *camera = renderer->GetActiveCamera();
   double cam_x_direction[3];
   camera->Roll(90); // up points now to actual x direction
   camera->OrthogonalizeViewUp();
   camera->GetViewUp(cam_x_direction);
   camera->Roll(-90);

   // Left view - show and write to file
   vtkTransform *tr = vtkTransform::New();
   tr->Translate(-cam_x_direction[0]*baseLine / 2, -cam_x_direction[1]*baseLine / 2, -cam_x_direction[2]*baseLine / 2);
   renderer->GetActiveCamera()->ApplyTransform(tr);
   renderer->ResetCameraClippingRange();
   renderer->GetRenderWindow()->Render();
   imageFilter->Modified(); // kludge as this filter sucks
   pNGWriter->SetFileName(AddPostDefToFilename(cam_img_file, "_left").data());
   pNGWriter->Write();

   // Construct and store camera matrices
   double K_l[3][3]; // intrinsic camera matrix (ref. [2])
   double R_l[3][3]; // rotation matrix (ref. [2])
   double t_l[3]; // translation vector (ref. [2])
   double k_l[4]; // lens distortion parameters
   double fov = renderer->GetActiveCamera()->GetViewAngle();
   int *sz = renderer->GetRenderWindow()->GetSize();
   CanonicStereoCameraMatrix_CoViS(sz, fov, baseLine, 1, K_l, R_l, t_l, k_l);

   // Compute and store bounding box coordinates for this view
   // Can be moved to the display coordinates by the intrinsic matrix K and by noting
   // that the origin of the camera frame is bottom right and Z pointing toward the object
   vtkTransform *camViewTransform = renderer->GetActiveCamera()->GetViewTransformObject();
   double bbox_view[3][8];
   double bbin[3], bbout[3];
   for (int bbi = 0; bbi < 8; bbi++) {
      bbin[0] = bbox[0][bbi];
      bbin[1] = bbox[1][bbi];
      bbin[2] = bbox[2][bbi];
      camViewTransform->TransformPoint(bbin, bbout);
      bbox_view[0][bbi] = bbout[0];
      bbox_view[1][bbi] = bbout[1];
      bbox_view[2][bbi] = bbout[2];
   }
   std::ofstream bboxFile;
   bboxFile.open(AddPostDefToFilename(bbox_file, "_vtk_left_camera_frame").data());
   bboxFile << bbox_view[0][0] << " " << bbox_view[1][0] << " " << bbox_view[2][0] << std::endl;
   bboxFile << bbox_view[0][1] << " " << bbox_view[1][1] << " " << bbox_view[2][1] << std::endl;
   bboxFile << bbox_view[0][2] << " " << bbox_view[1][2] << " " << bbox_view[2][2] << std::endl;
   bboxFile << bbox_view[0][3] << " " << bbox_view[1][3] << " " << bbox_view[2][3] << std::endl;
   bboxFile << bbox_view[0][4] << " " << bbox_view[1][4] << " " << bbox_view[2][4] << std::endl;
   bboxFile << bbox_view[0][5] << " " << bbox_view[1][5] << " " << bbox_view[2][5] << std::endl;
   bboxFile << bbox_view[0][6] << " " << bbox_view[1][6] << " " << bbox_view[2][6] << std::endl;
   bboxFile << bbox_view[0][7] << " " << bbox_view[1][7] << " " << bbox_view[2][7] << std::endl;
   bboxFile.close();

   /* try 1
   double bbox_view[3][8];
   for (int bbi = 0; bbi < 8; bbi++) {
      bbox_view[0][bbi] = bbox[0][bbi]; bbox_view[1][bbi] = bbox[1][bbi]; bbox_view[2][bbi] = bbox[2][bbi];
      renderer->WorldToView(bbox_view[0][bbi], bbox_view[1][bbi], bbox_view[2][bbi]);
   }
   std::ofstream bboxFile;
   bboxFile.open(AddPostDefToFilename(bbox_file, "_left_view").data());
   bboxFile << bbox_view[0][0] << " " << bbox_view[1][0] << " " << bbox_view[2][0] << std::endl;
   bboxFile << bbox_view[0][1] << " " << bbox_view[1][1] << " " << bbox_view[2][1] << std::endl;
   bboxFile << bbox_view[0][2] << " " << bbox_view[1][2] << " " << bbox_view[2][2] << std::endl;
   bboxFile << bbox_view[0][3] << " " << bbox_view[1][3] << " " << bbox_view[2][3] << std::endl;
   bboxFile << bbox_view[0][4] << " " << bbox_view[1][4] << " " << bbox_view[2][4] << std::endl;
   bboxFile << bbox_view[0][5] << " " << bbox_view[1][5] << " " << bbox_view[2][5] << std::endl;
   bboxFile << bbox_view[0][6] << " " << bbox_view[1][6] << " " << bbox_view[2][6] << std::endl;
   bboxFile << bbox_view[0][7] << " " << bbox_view[1][7] << " " << bbox_view[2][7] << std::endl;
   bboxFile.close();
   */

   // Right view - show and write to file
   tr->Identity();
   tr->Translate(cam_x_direction[0]*baseLine, cam_x_direction[1]*baseLine, cam_x_direction[2]*baseLine);
   renderer->GetActiveCamera()->ApplyTransform(tr);
   renderer->ResetCameraClippingRange();
   renderer->GetRenderWindow()->Render();
   imageFilter->Modified(); // kludge as this filter sucks
   pNGWriter->SetFileName(AddPostDefToFilename(cam_img_file, "_right").data());
   pNGWriter->Write();

   // Construct and store camera matrices
   double K_r[3][3]; // intrinsic camera matrix (ref. [2])
   double R_r[3][3]; // rotation matrix (ref. [2])
   double t_r[3]; // translation vector (ref. [2])
   double k_r[4]; // lens distortion parameters
   CanonicStereoCameraMatrix_CoViS(sz, fov, baseLine, 0, K_r, R_r, t_r, k_r);

   // Save camera calibration information in OpenCV format
   SaveStereoCalibrationOpenCV(sz, sz, K_l, K_r, R_l, R_r, t_l, t_r, k_l, k_r,
                               AddPostDefToFilename(cam_mat_file, "_CoViS_canonic"));

   // Return camera to the original position (needed for the elevation/azimuth loop)
   tr->Identity();
   tr->Translate(-cam_x_direction[0]*baseLine / 2, -cam_x_direction[1]*baseLine / 2, -cam_x_direction[2]*baseLine / 2);
   renderer->GetActiveCamera()->ApplyTransform(tr);
   renderer->ResetCameraClippingRange();
   return;
}

/**
 * @brief Forms the matrices K, R and t needed to construct the camera matrix P
 *        in eq. (6.8) in ref [2] for canonical poses of a stereo system (canonical means
 *        that camera matrices are relative between the two cameras and not the world).
 *        Note that CoViS coordinate system is right hand system, where Z points away
 *        from the camera and the origin is at the image centre => baseline
 *        for the left view is positive (neg. of that given)
 **/
void CanonicStereoCameraMatrix_CoViS(const int sz[], const double fov, const double baseLine, const short leftView, double K[][3], double R[][3], double t[], double k[]) {
   // compute alpha_x and alpha_y (focal lengths in terms of pixels, see eq. (6.9) in ref. [2])
   int szx = sz[0];
   int szy = sz[1];
   const double fx = sz[0] / 2 / std::tan(fov * M_PI / 2 / 180.0);
   const double fy = sz[1] / 2 / std::tan(fov * M_PI / 2 / 180.0);
   //    fx  0 x_0
   //K =  0 fy y_0
   //     0  0   1
   K[0][0] = fx;
   K[0][1] = 0; // skew is 0
   K[0][2] = sz[0] / 2; // principal point x_0 in pixels
   K[1][0] = 0;
   K[1][1] = fy;
   K[1][2] = sz[1] / 2; // principal point y_0 in pixels
   K[2][0] = 0;
   K[2][1] = 0;
   K[2][2] = 1;
   //     1 0 0
   // R = 0 1 0
   //     0 0 1
   R[0][0] = 1;
   R[0][1] = 0;
   R[0][2] = 0;
   R[1][0] = 0;
   R[1][1] = 1;
   R[1][2] = 0;
   R[2][0] = 0;
   R[2][1] = 0;
   R[2][2] = 1;
   //
   // t = [baseline/2 0 0];
   if (leftView == 1)
      t[0] = baseLine / 2;
   else
      t[0] = -baseLine / 2;
   t[1] = 0;
   t[2] = 0;
   // Distortion parameters
   k[0] = 0;
   k[1] = 0;
   k[2] = 0;
   k[3] = 0;
   return;
}

/**
 * @brief Saves the calibration information of a stereo pair cameras in OpenCV format.
 **/
void SaveStereoCalibrationOpenCV(const int sz_l[], const int sz_r[],
                                 const double K_l[][3], const double K_r[][3],
                                 const double R_l[][3], const double R_r[][3],
                                 const double t_l[], const double t_r[],
                                 const double k_l[], const double k_r[],
                                 const std::string &fileName) {
   std::ofstream fd;
   fd.open(fileName.data());

   // Num of cameras
   fd << "2" << std::endl << std::endl;

   // Left camera information
   fd << sz_l[0] << " " << sz_l[1] << std::endl;
   fd << K_l[0][0] << " " << K_l[0][1] << " " << K_l[0][2] << std::endl;
   fd << K_l[1][0] << " " << K_l[1][1] << " " << K_l[1][2] << std::endl;
   fd << K_l[2][0] << " " << K_l[2][1] << " " << K_l[2][2] << std::endl;
   fd << k_l[0] << " " << k_l[1] << " " << k_l[2] << " " << k_l[3] << std::endl;
   fd << R_l[0][0] << " " << R_l[0][1] << " " << R_l[0][2] << std::endl;
   fd << R_l[1][0] << " " << R_l[1][1] << " " << R_l[1][2] << std::endl;
   fd << R_l[2][0] << " " << R_l[2][1] << " " << R_l[2][2] << std::endl;
   fd << t_l[0] << " " << t_l[1] << " " << t_l[2] << std::endl;

   fd << std::endl;

   // Right camera information
   fd << sz_r[0] << " " << sz_r[1] << std::endl;
   fd << K_r[0][0] << " " << K_r[0][1] << " " << K_r[0][2] << std::endl;
   fd << K_r[1][0] << " " << K_r[1][1] << " " << K_r[1][2] << std::endl;
   fd << K_r[2][0] << " " << K_r[2][1] << " " << K_r[2][2] << std::endl;
   fd << k_r[0] << " " << k_r[1] << " " << k_r[2] << " " << k_r[3] << std::endl;
   fd << R_r[0][0] << " " << R_r[0][1] << " " << R_r[0][2] << std::endl;
   fd << R_r[1][0] << " " << R_r[1][1] << " " << R_r[1][2] << std::endl;
   fd << R_r[2][0] << " " << R_r[2][1] << " " << R_r[2][2] << std::endl;
   fd << t_r[0] << " " << t_r[1] << " " << t_r[2] << std::endl;

   fd.close();
   return;
}

/**
 * @brief Forms a 3x4 camera matrix for the canonical pose (unit vector),
 * where camera is moved in y direction by the amount of the given baseline.
 * This function assumes that the coordinate system is ... WHAT? *
 * Note: to move camera left, the baseline must be positive
 **/
void saveCameraMatrixCanonicOpenCV(vtkRenderer *renderer, double camMatr[][4], double baseline, const char *camOpenCVFile) {

   // OpenCV compatible camera parameters
   double fov = renderer->GetActiveCamera()->GetViewAngle();
   int *sz = renderer->GetRenderWindow()->GetSize();
   int szx = sz[0];
   int szy = sz[1];
   const double fx = 0.5 * szx / std::tan(0.5 * fov * M_PI / 180.0);
   const double fy = 0.5 * szy / std::tan(0.5 * fov * M_PI / 180.0);
   double cx = szx / 2;
   double cy = szy / 2;
   double R[3][3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};

   std::ofstream oCVFile;
   oCVFile.open(camOpenCVFile);

   // Write first the left camera (denoted by "2" I presume?)
   oCVFile << "2" << std::endl << std::endl;
   //image size
   oCVFile << szx << " " << szy << std::endl << std::endl;
   // 3x3 camera calibration matrix
   oCVFile << fx << " " <<  0 << " " << cx << std::endl;
   oCVFile <<  0 << " " << fy << " " << cx << std::endl;
   oCVFile <<  0 << " " <<  0 << " " <<  1 << std::endl << std::endl;
   // 1x4 Distortion parameters
   oCVFile <<  0 << " " <<  0 << " " <<  0 << " " << 0 << std::endl << std::endl;
   // 3x3 Rotation matrix
   oCVFile << R[0][0] << " " << R[0][1] << " " << R[0][2] << std::endl;
   oCVFile << R[1][0] << " " << R[1][1] << " " << R[1][2] << std::endl;
   oCVFile << R[2][0] << " " << R[2][1] << " " << R[2][2] << std::endl << std::endl;
   // 1x3 translation vector
   oCVFile << 0 << " " << 0 << " " << 0 << std::endl << std::endl;

   // and then the right camera
   //image size
   oCVFile << szx << " " << szy << std::endl << std::endl;
   // 3x3 camera calibration matrix
   oCVFile << fx << " " <<  0 << " " << cx << std::endl;
   oCVFile <<  0 << " " << fy << " " << cx << std::endl;
   oCVFile <<  0 << " " <<  0 << " " <<  1 << std::endl << std::endl;
   // 1x4 Distortion parameters
   oCVFile <<  0 << " " <<  0 << " " <<  0 << " " << 0 << std::endl << std::endl;
   // 3x3 Rotation matrix
   oCVFile << R[0][0] << " " << R[0][1] << " " << R[0][2] << std::endl;
   oCVFile << R[1][0] << " " << R[1][1] << " " << R[1][2] << std::endl;
   oCVFile << R[2][0] << " " << R[2][1] << " " << R[2][2] << std::endl << std::endl;
   // 1x3 translation vector
   oCVFile << -baseline << " " << 0 << " " << 0 << std::endl;
}


/**
* @brief Forms a 3x4 camera matrix compatible with VTK coordinates and
 * definitions. The camera matrix is constructed using the processing in
 * vtkRenderer::WorldToView() and vtkRenderer::ViewToDisplay() and thus
 * changing them will certainly affect this.
 *
 * Note: vtk image origin is at the bottom left corner
 **/
void ConstructCameraMatrixVTK(vtkRenderer *renderer, double camMatr[][4]) {
   double *dispPoint;
   double *viewport;

   int sizex, sizey;
   int *size;

   // Window (image) size
   size = renderer->GetRenderWindow()->GetSize();
   sizex = size[0];
   sizey = size[1];

   // World to view transformation vPw
   viewport = renderer->GetViewport();
   vtkSmartPointer<vtkMatrix4x4> vPw =
      renderer->GetActiveCamera()->
      GetCompositePerspectiveTransformMatrix (renderer->GetTiledAspectRatio(), 0, 1);

   // View to camera (display) transformation constructed in a way that its
   // multiplication with vPw forms the final result, i.e. cPw = cPv*vPw
   // see vtkRenderer::ViewToDisplay() for details (and do some matr. algebra)
   vtkSmartPointer<vtkMatrix4x4> cPv = vtkSmartPointer<vtkMatrix4x4>::New();

   cPv->SetElement(0, 0, sizex*(viewport[2] - viewport[0]) / 2);
   cPv->SetElement(0, 1, 0);
   cPv->SetElement(0, 2, 0);
   cPv->SetElement(0, 3, sizex*(viewport[2] + viewport[0]) / 2);

   cPv->SetElement(1, 0, 0);
   cPv->SetElement(1, 1, sizey*(viewport[3] - viewport[1]) / 2);
   cPv->SetElement(1, 2, 0);
   cPv->SetElement(1, 3, sizey*(viewport[3] + viewport[1]) / 2);

   cPv->SetElement(2, 0, 0);
   cPv->SetElement(2, 1, 0);
   cPv->SetElement(2, 2, 0);
   cPv->SetElement(2, 3, 1);

   cPv->SetElement(3, 0, 0);
   cPv->SetElement(3, 1, 0);
   cPv->SetElement(3, 2, 0);
   cPv->SetElement(3, 3, 0);

   // Form the final matrix
   vtkSmartPointer<vtkMatrix4x4> cPw = vtkSmartPointer<vtkMatrix4x4>::New();
   vtkMatrix4x4::Multiply4x4(cPv, vPw, cPw);

   // Store, not that the result matrix is actually 3x4
   camMatr[0][0] = cPw->GetElement(0, 0);
   camMatr[0][1] = cPw->GetElement(0, 1);
   camMatr[0][2] = cPw->GetElement(0, 2);
   camMatr[0][3] = cPw->GetElement(0, 3);
   camMatr[1][0] = cPw->GetElement(1, 0);
   camMatr[1][1] = cPw->GetElement(1, 1);
   camMatr[1][2] = cPw->GetElement(1, 2);
   camMatr[1][3] = cPw->GetElement(1, 3);
   camMatr[2][0] = cPw->GetElement(2, 0);
   camMatr[2][1] = cPw->GetElement(2, 1);
   camMatr[2][2] = cPw->GetElement(2, 2);
   camMatr[2][3] = cPw->GetElement(2, 3);
}

/**
 * @brief Forms a 3x4 camera matrix compatible with CoViS coordinates and
 * definitions. THIS HAS NOT BEEN IMPLEMENTED - but it should be very similar
 * to ConstructCameraMatrixVTK() - only display origin should be fixed and
 * maybe the directions of axes.... I will not implement this until really
 * need it...
 * Note: CoViS origin is at the upper corner
 **/
void ConstructCameraMatrixCoViS(vtkRenderer *renderer, double camMatr[][4]) {
   cerr << "ConstructCameraMatrixCoViS IS NOT IMPLEMENTED...AAARGH!";
}

/**
 * @brief Adds a post definition to a file name, e.g.,=> "foo.data" => "foo_ex02.data"
 **/
std::string AddPostDefToFilename(std::string filename, const char *postDef) {

   int basenameStart = filename.rfind(".");
   if (basenameStart == std::string::npos)
      basenameStart = filename.size();
   filename.insert(basenameStart, postDef);
   return filename;
}

/**
 * @brief Help provided for a user
 **/
void MainHelpCallBack(void) {
   cout << std::endl;
   cout << "A program to render KIT web database objects for ECV object detection experiments." << std::endl;
   cout << std::endl;
   cout << "The program provides stereo pair images and their camera matrices and" << std::endl;
   cout << "was mainly developed to render KIT web database objects needed for object" << std::endl;
   cout << "detection experiments (OBJ format with PNG files for texture)." << std::endl;
   cout << "The program also provides special data for detection evaluation." << std::endl;
   cout << "See the 'Readme.txt' file for more details and examples." << std::endl;
   cout << std::endl;
   return;
}

/**
 * @brief Command line parsing (using vtkmeatio::MetaCommand since VTK needed anyway).
 *        See http://www.vtk.org/Wiki/MetaIO/MetaCommand_Documentation
 **/
int MainParseCommandLine( vtkmetaio::MetaCommand& command,
                          int argc, char **const argv) {
   command.SetHelpCallBack(MainHelpCallBack);
   command.SetDescription("A program to render KIT web database objects for ECV object detection experiments.");
   command.SetAuthor("Joni Kamarainen <Joni.Kamarainen@lut.fi>");

   command.SetOption("debug_mode", "", false, "Debug mode (0: no debug output, 1: some, 2: full).");
   command.SetOptionLongTag("debug_mode", "debug_mode");
   command.AddOptionField("debug_mode", "mode",
                          vtkmetaio::MetaCommand::INT, true, "0");

   command.SetOption("model", "", true, "Model file (OBJ format supported).");
   command.SetOptionLongTag("model", "model");
   command.AddOptionField("model", "file", vtkmetaio::MetaCommand::STRING, true);

   command.SetOption("texture", "", false, "Texture file (PNG supported).");
   command.SetOptionLongTag("texture", "texture");
   command.AddOptionField("texture", "file", vtkmetaio::MetaCommand::STRING, true);

   command.SetOption("bboutput", "", false, "File where the bounding box written.");
   command.SetOptionLongTag("bboutput", "bboutput");
   command.AddOptionField("bboutput", "file", vtkmetaio::MetaCommand::STRING, true, "render_3d_object_bbox.dat");

   command.SetOption("image_size", "", false, "Size of the output image (preferably a square).");
   command.SetOptionLongTag("image_size", "image_size");
   command.AddOptionField("image_size", "height",
                          vtkmetaio::MetaCommand::INT, true, "300");
   command.AddOptionField("image_size", "width",
                          vtkmetaio::MetaCommand::INT, true, "300");

   command.SetOption("view_angle", "", false, "Camera view angle (corresponds to the focal length parameter, still human eye is ~40deg).");
   command.SetOptionLongTag("view_angle", "view_angle");
   command.AddOptionField("view_angle", "angle",
                          vtkmetaio::MetaCommand::FLOAT, true, "40");

   command.SetOption("bgcolour", "", false, "Background colour");
   command.SetOptionLongTag("bgcolour", "bgcolour");
   command.AddOptionField("bgcolour", "r",
                          vtkmetaio::MetaCommand::FLOAT, true, "0.0");
   command.AddOptionField("bgcolour", "g",
                          vtkmetaio::MetaCommand::FLOAT, true, "0.0");
   command.AddOptionField("bgcolour", "b",
                          vtkmetaio::MetaCommand::FLOAT, true, "0.0");

   command.SetOption("camera_distance", "", false, "Distance from the camera to the origin (bb centre). Note that the world's scale depends on the OBJ polygon coordinates. Use -1 to set automatically.");
   command.SetOptionLongTag("camera_distance", "camera_distance");
   command.AddOptionField("camera_distance", "distance",
                          vtkmetaio::MetaCommand::FLOAT, true, "-1");

   command.SetOption("distoutput", "", false, "File where the camera location and view plane normal written.");
   command.SetOptionLongTag("distoutput", "distoutput");
   command.AddOptionField("distoutput", "file", vtkmetaio::MetaCommand::STRING, true, "render_3d_object_dist.dat");

   command.SetOption("objorientation", "", false, "Object orientation angles along its own axes. Used to make KIT object frontal toward negative z axis (camera direction).");
   command.SetOptionLongTag("objorientation", "objorientation");
   command.AddOptionField("objorientation", "x", vtkmetaio::MetaCommand::FLOAT, true, "0.0");
   command.AddOptionField("objorientation", "y", vtkmetaio::MetaCommand::FLOAT, true, "+90.0");
   command.AddOptionField("objorientation", "z", vtkmetaio::MetaCommand::FLOAT, true, "0.0");

   command.SetOption("view_mode", "", false, "View mode (0: interactive, 1: frontal stereo, 2: elevation/azimuth/zoom");
   command.SetOptionLongTag("view_mode", "view_mode");
   command.AddOptionField("view_mode", "mode",
                          vtkmetaio::MetaCommand::INT, true, "0");

   command.SetOption("cam_mat_output", "", false, "Camera matrix file name (various formats and left and right written).");
   command.SetOptionLongTag("cam_mat_output", "cam_mat_output");
   command.AddOptionField("cam_mat_output", "file",
                          vtkmetaio::MetaCommand::STRING, true, "render_3d_object_cam_mat.dat");

   command.SetOption("cam_img_output", "", false, "Camera image file name (PNG format, left and right).");
   command.SetOptionLongTag("cam_img_output", "cam_img_output");
   command.AddOptionField("cam_img_output", "file",
                          vtkmetaio::MetaCommand::STRING, true, "render_3d_object_cam_img.png");

   command.SetOption("stereo_baseline", "", false, "Stereo baseline in world coordinates (view modes 1 and 2). Note that the world's scale depends on the object coordinates (quads in the given OBJ file).");
   command.SetOptionLongTag("stereo_baseline", "stereo_baseline");
   command.AddOptionField("stereo_baseline", "baseline",
                          vtkmetaio::MetaCommand::FLOAT, true, "50");

   command.SetOption("elevation", "", false, "Camera elevation in degrees (view mode 2) (upto 5 values, use \"nan\" to omit).");
   command.SetOptionLongTag("elevation", "elevation");
   command.AddOptionField("elevation", "val1", vtkmetaio::MetaCommand::FLOAT, false, "-10.0");
   command.AddOptionField("elevation", "val2", vtkmetaio::MetaCommand::FLOAT, false, "0.0");
   command.AddOptionField("elevation", "val3", vtkmetaio::MetaCommand::FLOAT, false, "10.0");
   command.AddOptionField("elevation", "val4", vtkmetaio::MetaCommand::FLOAT, false, "nan");
   command.AddOptionField("elevation", "val5", vtkmetaio::MetaCommand::FLOAT, false, "nan");

   command.SetOption("azimuth", "", false, "Camera azimuth in degrees (view mode 2) (upto 5 values, use \"nan\" to omit).");
   command.SetOptionLongTag("azimuth", "azimuth");
   command.AddOptionField("azimuth", "val1", vtkmetaio::MetaCommand::FLOAT, false, "-10.0");
   command.AddOptionField("azimuth", "val2", vtkmetaio::MetaCommand::FLOAT, false, "0.0");
   command.AddOptionField("azimuth", "val3", vtkmetaio::MetaCommand::FLOAT, false, "10.0");
   command.AddOptionField("azimuth", "val4", vtkmetaio::MetaCommand::FLOAT, false, "nan");
   command.AddOptionField("azimuth", "val5", vtkmetaio::MetaCommand::FLOAT, false, "nan");

   command.SetOption("zoom", "", false, "Camera zoom in ]0,inf[ (view mode 2) (upto 5 values, use \"nan\" to omit). Note: Implementation NOT CHECKED!");
   command.SetOptionLongTag("zoom", "zoom");
   command.AddOptionField("zoom", "val1", vtkmetaio::MetaCommand::FLOAT, false, "0.8");
   command.AddOptionField("zoom", "val2", vtkmetaio::MetaCommand::FLOAT, false, "1.0");
   command.AddOptionField("zoom", "val3", vtkmetaio::MetaCommand::FLOAT, false, "1.2");
   command.AddOptionField("zoom", "val4", vtkmetaio::MetaCommand::FLOAT, false, "nan");
   command.AddOptionField("zoom", "val5", vtkmetaio::MetaCommand::FLOAT, false, "nan");


   if ( !command.Parse(argc, argv) ) {
      cout << "Example: " << command.GetApplicationName() << " --model testdata/OrangeMarmelade_800_tex.obj --texture testdata/OrangeMarmelade_800_tex.png" << std::endl;
      return -1;
   }
   return 0;
}
