/**********
Copyright (c) 2018, Xilinx, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.  3. Neither the name of the copyright holder nor the names of its contributors
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



#include <vector>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <CL/cl2.hpp>
#include "typedefs.h"
#include "imageLib/imageLib.h"

#define DATA_SIZE 4096



#define CONFIG_SIZE 16
#define INPUT_SIZE (2*MAX_HEIGHT*MAX_WIDTH/16)
#define OUTPUT_SIZE (2*MAX_HEIGHT*MAX_WIDTH/16)

// Forward declaration of utility functions included at the end of this file
std::vector<cl::Device> get_xilinx_devices();
char *read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void check_results(velocity_t output[MAX_HEIGHT*MAX_WIDTH], CFloatImage refFlow);



// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char **argv)
{
    //TARGET_DEVICE macro needs to be passed from gcc command line
    if (argc < 2)
    {
        std::cout << "Usage: " << argv[0] << " <xclbin>" << std::endl;
        return EXIT_FAILURE;
    }

    std::vector<cl::Device> devices;
    cl::Device device;
    std::vector<cl::Platform> platforms;
    bool found_device = false;

    //traversing all Platforms To find Xilinx Platform and targeted
    //Device in Xilinx Platform
    cl::Platform::get(&platforms);
    for (size_t i = 0; (i < platforms.size()) & (found_device == false); i++)
    {
        cl::Platform platform = platforms[i];
        std::string platformName = platform.getInfo<CL_PLATFORM_NAME>();
        if (platformName == "Xilinx")
        {
            devices.clear();
            platform.getDevices(CL_DEVICE_TYPE_ACCELERATOR, &devices);
            if (devices.size())
            {
                device = devices[0];
                found_device = true;
                break;
            }
        }
    }
    if (found_device == false)
    {
        std::cout << "Error: Unable to find Target Device "
                  << device.getInfo<CL_DEVICE_NAME>() << std::endl;
        return EXIT_FAILURE;
    }

    // Creating Context and Command Queue for selected device
    cl::Context context(device);

    // Load xclbin
    for (int i = 1; i < argc; i++)
    {
        char *xclbinFilename = argv[i];
        std::cout << "Loading: '" << xclbinFilename << "'\n";
        std::ifstream bin_file(xclbinFilename, std::ifstream::binary);
        bin_file.seekg(0, bin_file.end);
        unsigned nb = bin_file.tellg();
        bin_file.seekg(0, bin_file.beg);
        char *buf = new char[nb];
        bin_file.read(buf, nb);

        // Creating Program from Binary File
        cl::Program::Binaries bins;
        bins.push_back({buf, nb});
        devices.resize(1);
        cl::Program program(context, devices, bins);
    }
    std::cout << "Done!" << std::endl;


    // ------------------------------------------------------------------------------------
    // Step 1: Initialize the OpenCL environment
    // ------------------------------------------------------------------------------------
    cl_int err;
    std::string binaryFile = (argc == 1) ? "ydma.xclbin" : argv[argc-1];
    unsigned fileBufSize;
    devices.resize(1);
    //cl::Context context(device, NULL, NULL, NULL, &err);
    char *fileBuf = read_binary_file(binaryFile, fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
    cl::Program program(context, devices, bins, NULL, &err);
    cl::CommandQueue q(context, device, CL_QUEUE_PROFILING_ENABLE, &err);
    cl::Kernel krnl_ydma(program, "ydma", &err);

    // ------------------------------------------------------------------------------------
    // Step 2: Create buffers and initialize test values
    // ------------------------------------------------------------------------------------
    // Create the buffers and allocate memory
    cl::Buffer in1_buf(context, CL_MEM_READ_ONLY, sizeof(bit64) * CONFIG_SIZE, NULL, &err);
    cl::Buffer in2_buf(context, CL_MEM_READ_ONLY, sizeof(bit512) * INPUT_SIZE, NULL, &err);
    cl::Buffer out1_buf(context, CL_MEM_WRITE_ONLY, sizeof(bit64) * CONFIG_SIZE, NULL, &err);
    cl::Buffer out2_buf(context, CL_MEM_WRITE_ONLY, sizeof(bit512) * OUTPUT_SIZE, NULL, &err);

    // Map buffers to kernel arguments, thereby assigning them to specific device memory banks
    krnl_ydma.setArg(0, in1_buf);
    krnl_ydma.setArg(1, in2_buf);
    krnl_ydma.setArg(2, out1_buf);
    krnl_ydma.setArg(3, out2_buf);

    // Map host-side buffer memory to user-space pointers
    bit64 *in1 = (bit64 *)q.enqueueMapBuffer(in1_buf, CL_TRUE, CL_MAP_WRITE, 0, sizeof(bit64) * CONFIG_SIZE);
    bit512 *in2 = (bit512 *)q.enqueueMapBuffer(in2_buf, CL_TRUE, CL_MAP_WRITE, 0, sizeof(bit512) * INPUT_SIZE);
    bit64 *out1 = (bit64 *)q.enqueueMapBuffer(out1_buf, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(bit64) * CONFIG_SIZE);
    bit512 *out2 = (bit512 *)q.enqueueMapBuffer(out2_buf, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(bit512) * OUTPUT_SIZE);

    // Initialize the vectors used in the test
    // pack input data for better performance
    //for ( int i = 0; i < CONFIG_SIZE; i++)
    //{

      in1[0].range(63, 32) = 0x00000000;
      in1[0].range(31,  0) = 0x00000000;

      in1[1].range(63, 32) = 0x00000000;
      in1[1].range(31,  0) = INPUT_SIZE;

      // configure packets

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
        for (int j = 0; j < MAX_WIDTH/8; j++)
        {
          for(int k=0; k<8; k++){
			  in2[i*MAX_WIDTH/8+j](k*64+7 , k*64+0)  = imgs[0].Pixel(j*8+k, i, 0);
			  in2[i*MAX_WIDTH/8+j](k*64+15, k*64+8)  = imgs[1].Pixel(j*8+k, i, 0);
			  in2[i*MAX_WIDTH/8+j](k*64+23, k*64+16) = imgs[2].Pixel(j*8+k, i, 0);
			  in2[i*MAX_WIDTH/8+j](k*64+31, k*64+24) = imgs[3].Pixel(j*8+k, i, 0);
			  in2[i*MAX_WIDTH/8+j](k*64+39, k*64+32) = imgs[4].Pixel(j*8+k, i, 0);
			  in2[i*MAX_WIDTH/8+j](k*64+63, k*64+40) = 0;
          }
        }
      }





    // ------------------------------------------------------------------------------------
    // Step 3: Run the kernel
    // ------------------------------------------------------------------------------------
    // Set kernel arguments


	krnl_ydma.setArg(0, in1_buf);
	krnl_ydma.setArg(1, in2_buf);
	krnl_ydma.setArg(2, out1_buf);
	krnl_ydma.setArg(3, out2_buf);
	krnl_ydma.setArg(4, CONFIG_SIZE);
	krnl_ydma.setArg(5, INPUT_SIZE);
	krnl_ydma.setArg(6, OUTPUT_SIZE);
	//krnl_ydma.setArg(6, OUTPUT_SIZE);

	// Schedule transfer of inputs to device memory, execution of kernel, and transfer of outputs back to host memory
	q.enqueueMigrateMemObjects({in1_buf, in2_buf}, 0 /* 0 means from host*/);
	q.enqueueTask(krnl_ydma);
	q.enqueueMigrateMemObjects({out1_buf, out2_buf}, CL_MIGRATE_MEM_OBJECT_HOST);


	// Wait for all scheduled operations to finish
	q.finish();


    // ------------------------------------------------------------------------------------
    // Step 4: Check Results and Release Allocated Resources
    // ------------------------------------------------------------------------------------
    bool match = true;
    velocity_t outputs[MAX_HEIGHT*MAX_WIDTH];

    for (int i = 0; i < MAX_HEIGHT; i++)
    {
      for (int j = 0; j < MAX_WIDTH/8; j++)
      {
    	  for (int k=0; k<8; k++){
    		  ;
    		  outputs[i*MAX_WIDTH+j*8+k].x(31,0)   = out2[i*MAX_WIDTH/8+j](k*64+31, k*64);
    	  	  outputs[i*MAX_WIDTH+j*8+k].y(31,0)   = out2[i*MAX_WIDTH/8+j](k*64+63, k*64+32);
    	  }
      }
    }

    check_results(outputs, refFlow);

    // for(int i=0; i<CONFIG_SIZE; i++){
    for(int i=0; i<CONFIG_SIZE; i++){
        printf("%d: %08x_%08x\n", i, (unsigned int)out1[i].range(63, 32), (unsigned int) out1[i].range(31, 0));
    	//std::cout << "out1[" << i << "]=" << out1[i] << std::endl;
    }
    
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

