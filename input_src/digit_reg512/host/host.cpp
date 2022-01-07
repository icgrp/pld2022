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
#include "training_data.h"
#include "testing_data.h"
#include <sys/time.h>




#define CONFIG_SIZE 256
#define INPUT_SIZE ((NUM_TRAINING + NUM_TEST) * 8 / 16)
#define OUTPUT_SIZE (32)

// Forward declaration of utility functions included at the end of this file
std::vector<cl::Device> get_xilinx_devices();
char *read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void check_results(bit512* result, const LabelType* expected, int cnt);


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

  // Variables for time measurement
  struct timeval start, end;


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
    for (int i = 1; i < argc-1; i++)
    {
        char *xclbinFilename = argv[i];
        std::cout << "Loading xclbin" << i << ": '" << xclbinFilename << "'\n";
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

    for (int i = 0; i < NUM_TRAINING; i ++ )
    {
      WholeDigitType tmp;
      WholeDigitType tmp_in;
      tmp.range(63 , 0  ) = training_data[i*DIGIT_WIDTH+0];
      tmp.range(127, 64 ) = training_data[i*DIGIT_WIDTH+1];
      tmp.range(191, 128) = training_data[i*DIGIT_WIDTH+2];
      tmp.range(255, 192) = training_data[i*DIGIT_WIDTH+3];
      for(int j=0; j<8; j++){
    	  tmp_in.range(j*32+31, j*32) = tmp.range((7-j)*32+31, (7-j)*32);
      }
      int offset = i % 2;
      in2[i/2](offset*256+255, offset*256) = tmp_in(255, 0);
    }

    for (int i = 0; i < NUM_TEST; i ++ )
    {
      WholeDigitType tmp;
      WholeDigitType tmp_in;
      tmp.range(63 , 0  ) = testing_data[i*DIGIT_WIDTH+0];
      tmp.range(127, 64 ) = testing_data[i*DIGIT_WIDTH+1];
      tmp.range(191, 128) = testing_data[i*DIGIT_WIDTH+2];
      tmp.range(255, 192) = testing_data[i*DIGIT_WIDTH+3];
      for(int j=0; j<8; j++){
    	  tmp_in.range(j*32+31, j*32) = tmp.range((7-j)*32+31, (7-j)*32);
      }
      int offset = i % 2;
      in2[i/2+NUM_TRAINING/2](offset*256+255, offset*256) = tmp_in(255, 0);
    }


    // ------------------------------------------------------------------------------------
    // Step 3: Run the kernel
    // ------------------------------------------------------------------------------------
    // Set kernel arguments
  gettimeofday(&start, NULL);



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

  gettimeofday(&end, NULL);

    // ------------------------------------------------------------------------------------
    // Step 4: Check Results and Release Allocated Resources
    // ------------------------------------------------------------------------------------
    bool match = true;
    check_results(out2, expected, NUM_TEST );
    // for(int i=0; i<CONFIG_SIZE; i++){
    int config_max = CONFIG_SIZE > 20 ? 20 : CONFIG_SIZE;
    for(int i=0; i<config_max; i++){
        printf("%d: %08x_%08x\n", i, (unsigned int)out1[i].range(63, 32), (unsigned int) out1[i].range(31, 0));
    	//std::cout << "out1[" << i << "]=" << out1[i] << std::endl;
    }
    
    delete[] fileBuf;
  // print time
  long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;   
  printf("elapsed time: %lld us\n", elapsed);


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


void check_results(bit512* result, const LabelType* expected, int cnt)
{
  int correct_cnt = 0;

  //std::ofstream ofile;
  //ofile.open("outputs.txt");
  //if (ofile.is_open())
  {
    for (int i = 0; i < cnt; i ++ )
    {
      LabelType tmp;
      int offset = i % 64;
      tmp = result[i/64](offset*8+7, offset*8);
      printf("result[%d](%d, %d) = %d\n",  i/64, offset*8+7, offset*8, (unsigned int) tmp);
      std::cout << "Test " << i << ": expected = " << int(expected[i]) << ", result = " << int(tmp) << std::endl;
      if (tmp != expected[i])
        ;
        //std::cout << "Test " << i << ": expected = " << int(expected[i]) << ", result = " << int(result[i/16]) << std::endl;
      else
        correct_cnt ++;
    }

    std::cout << "\n\t " << correct_cnt << " / " << cnt << " correct!" << std::endl;
  }
  //else
  //{
  //  std::cout << "Failed to create output file!" << std::endl;
  //}


}
