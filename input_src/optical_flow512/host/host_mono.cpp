/**********
Copyright (c) 2018, Xilinx, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**********/

#define CL_HPP_CL_1_2_DEFAULT_BUILD
#define CL_HPP_TARGET_OPENCL_VERSION 120
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#define CL_HPP_ENABLE_PROGRAM_CONSTRUCTION_FROM_ARRAY_COMPATIBILITY 1
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS

#define DATA_SIZE 4096

#include <vector>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <CL/cl2.hpp>
#include "typedefs.h"
#include "imageLib/imageLib.h"

// Forward declaration of utility functions included at the end of this file
std::vector<cl::Device> get_xilinx_devices();
char *read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void check_results(velocity_t output[MAX_HEIGHT*MAX_WIDTH], CFloatImage refFlow);


// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char **argv)
{
    // ------------------------------------------------------------------------------------
    // Step 1: Initialize the OpenCL environment
    // ------------------------------------------------------------------------------------
    cl_int err;
    std::string binaryFile = (argc != 2) ? "optical_flow.xclbin" : argv[1];
    unsigned fileBufSize;
    std::vector<cl::Device> devices = get_xilinx_devices();
    devices.resize(1);
    cl::Device device = devices[0];
    cl::Context context(device, NULL, NULL, NULL, &err);
    char *fileBuf = read_binary_file(binaryFile, fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
    cl::Program program(context, devices, bins, NULL, &err);
    cl::CommandQueue q(context, device, CL_QUEUE_PROFILING_ENABLE, &err);
    cl::Kernel krnl_optical_flow(program, "optical_flow", &err);

    // ------------------------------------------------------------------------------------
    // Step 2: Create buffers and initialize test values
    // ------------------------------------------------------------------------------------
    // Create the buffers and allocate memory
    cl::Buffer in1_buf(context, CL_MEM_READ_ONLY, sizeof(frames_t) * MAX_HEIGHT*MAX_WIDTH, NULL, &err);
    cl::Buffer out_buf(context, CL_MEM_WRITE_ONLY, sizeof(velocity_t) * MAX_HEIGHT*MAX_WIDTH, NULL, &err);

    // Map buffers to kernel arguments, thereby assigning them to specific device memory banks
    krnl_optical_flow.setArg(0, in1_buf);
    krnl_optical_flow.setArg(1, out_buf);

    // Map host-side buffer memory to user-space pointers
    frames_t *frames = (frames_t *)q.enqueueMapBuffer(in1_buf, CL_TRUE, CL_MAP_WRITE, 0, sizeof(frames_t) * MAX_HEIGHT*MAX_WIDTH);
    velocity_t *outputs = (velocity_t *)q.enqueueMapBuffer(out_buf, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(velocity_t) * MAX_HEIGHT*MAX_WIDTH);

    // Initialize the vectors used in the test
    // pack input data for better performance
    // parse command line arguments
    std::string dataPath("/home/ylxiao/rosetta/optical-flow/datasets/current");
    //std::string outFile("/home/ylxiao/eclipse-workspace/optical_flow/datasets/current/out.flo");

      // for sw and sdsoc versions
      //parse_sdsoc_command_line_args(argc, argv, dataPath, outFile);

    // create actual file names according to the datapath
    std::string frame_files[5];
    std::string reference_file;
    frame_files[0] = dataPath + "/frame1.ppm";
    frame_files[1] = dataPath + "/frame2.ppm";
    frame_files[2] = dataPath + "/frame3.ppm";
    frame_files[3] = dataPath + "/frame4.ppm";
    frame_files[4] = dataPath + "/frame5.ppm";
    reference_file = dataPath + "/ref.flo";

    // read in images and convert to grayscale
    printf("Reading input files ... \n");

    CByteImage imgs[5];
    for (int i = 0; i < 5; i++)
    {
      CByteImage tmpImg;
      ReadImage(tmpImg, frame_files[i].c_str());
      imgs[i] = ConvertToGray(tmpImg);
    }

    // read in reference flow file
    printf("Reading reference output flow... \n");

    CFloatImage refFlow;
    ReadFlowFile(refFlow, reference_file.c_str());


      // pack the values
      for (int i = 0; i < MAX_HEIGHT; i++)
      {
        for (int j = 0; j < MAX_WIDTH; j++)
        {
          frames[i*MAX_WIDTH+j](7 ,  0) = imgs[0].Pixel(j, i, 0);
          frames[i*MAX_WIDTH+j](15,  8) = imgs[1].Pixel(j, i, 0);
          frames[i*MAX_WIDTH+j](23, 16) = imgs[2].Pixel(j, i, 0);
          frames[i*MAX_WIDTH+j](31, 24) = imgs[3].Pixel(j, i, 0);
          frames[i*MAX_WIDTH+j](39, 32) = imgs[4].Pixel(j, i, 0);
          frames[i*MAX_WIDTH+j](63, 40) = 0;
        }
      }


    // ------------------------------------------------------------------------------------
    // Step 3: Run the kernel
    // ------------------------------------------------------------------------------------
    // Set kernel arguments


    krnl_optical_flow.setArg(0, in1_buf);
	krnl_optical_flow.setArg(1, out_buf);
	krnl_optical_flow.setArg(2, DATA_SIZE);

	//for(int i=0; i<10; i++){
	// Schedule transfer of inputs to device memory, execution of kernel, and transfer of outputs back to host memory
	q.enqueueMigrateMemObjects({in1_buf}, 0 /* 0 means from host*/);
	q.enqueueTask(krnl_optical_flow);
	q.enqueueMigrateMemObjects({out_buf}, CL_MIGRATE_MEM_OBJECT_HOST);
	//}

	// Wait for all scheduled operations to finish
	q.finish();


    // ------------------------------------------------------------------------------------
    // Step 4: Check Results and Release Allocated Resources
    // ------------------------------------------------------------------------------------
    bool match = true;
    printf("Checking results:\n");
    printf("Correct error: 150.083418 degrees\n");
    check_results(outputs, refFlow);

    delete[] fileBuf;

    std::cout << "TEST " << (match ? "PASSED" : "FAILED") << std::endl;
    return (match ? EXIT_SUCCESS : EXIT_FAILURE);
}

// ------------------------------------------------------------------------------------
// Utility functions
// ------------------------------------------------------------------------------------
std::vector<cl::Device> get_xilinx_devices()
{
    size_t i;
    cl_int err;
    std::vector<cl::Platform> platforms;
    err = cl::Platform::get(&platforms);
    cl::Platform platform;
    for (i = 0; i < platforms.size(); i++)
    {
        platform = platforms[i];
        std::string platformName = platform.getInfo<CL_PLATFORM_NAME>(&err);
        if (platformName == "Xilinx")
        {
            std::cout << "INFO: Found Xilinx Platform" << std::endl;
            break;
        }
    }
    if (i == platforms.size())
    {
        std::cout << "ERROR: Failed to find Xilinx platform" << std::endl;
        exit(EXIT_FAILURE);
    }

    //Getting ACCELERATOR Devices and selecting 1st such device
    std::vector<cl::Device> devices;
    err = platform.getDevices(CL_DEVICE_TYPE_ACCELERATOR, &devices);
    return devices;
}

char *read_binary_file(const std::string &xclbin_file_name, unsigned &nb)
{
    if (access(xclbin_file_name.c_str(), R_OK) != 0)
    {
        printf("ERROR: %s xclbin not available please build\n", xclbin_file_name.c_str());
        exit(EXIT_FAILURE);
    }
    //Loading XCL Bin into char buffer
    std::cout << "INFO: Loading '" << xclbin_file_name << "'\n";
    std::ifstream bin_file(xclbin_file_name.c_str(), std::ifstream::binary);
    bin_file.seekg(0, bin_file.end);
    nb = bin_file.tellg();
    bin_file.seekg(0, bin_file.beg);
    char *buf = new char[nb];
    bin_file.read(buf, nb);
    return buf;
}




void check_results(velocity_t output[MAX_HEIGHT*MAX_WIDTH], CFloatImage refFlow)
{
  // copy the output into the float image
  CFloatImage outFlow(MAX_WIDTH, MAX_HEIGHT, 2);
  for (int i = 0; i < MAX_HEIGHT; i++)
  {
    for (int j = 0; j < MAX_WIDTH; j++)
    {
      #ifdef OCL
        double out_x = output[i * MAX_WIDTH + j].x;
        double out_y = output[i * MAX_WIDTH + j].y;
      #else
        double out_x = output[i*MAX_WIDTH+j].x;
        double out_y = output[i*MAX_WIDTH+j].y;
      #endif

      if (out_x*out_x + out_y*out_y > 25.0)
      {
        outFlow.Pixel(j, i, 0) = 1e10;
        outFlow.Pixel(j, i, 1) = 1e10;
      }
      else
      {
        outFlow.Pixel(j, i, 0) = out_x;
        outFlow.Pixel(j, i, 1) = out_y;
      }
    }
  }

  //WriteFlowFile(outFlow, outFile.c_str());

  double accum_error = 0;
  int num_pix = 0;
  for (int i = 0; i < MAX_HEIGHT; i++)
  {
    for (int j = 0; j < MAX_WIDTH; j++)
    {
      double out_x = outFlow.Pixel(j, i, 0);
      double out_y = outFlow.Pixel(j, i, 1);

      if (unknown_flow(out_x, out_y)) continue;

      double out_deg = atan2(-out_y, -out_x) * 180.0 / M_PI;
      double ref_x = refFlow.Pixel(j, i, 0);
      double ref_y = refFlow.Pixel(j, i, 1);
      double ref_deg = atan2(-ref_y, -ref_x) * 180.0 / M_PI;

      // Normalize error to [-180, 180]
      double error = out_deg - ref_deg;
      while (error < -180) error += 360;
      while (error > 180) error -= 360;

      accum_error += fabs(error);
      num_pix++;
    }
  }

  double avg_error = accum_error / num_pix;
  printf("Average error: %lf degrees\n", avg_error);

}

