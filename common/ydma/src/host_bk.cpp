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
#include "input_data.h"


#define CONFIG_SIZE 12
#define INPUT_SIZE 3 * NUM_3D_TRI
#define OUTPUT_SIZE (NUM_FB / 16)


// Forward declaration of utility functions included at the end of this file
std::vector<cl::Device> get_xilinx_devices();
char *read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void check_results(bit32* output);

// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char **argv)
{
    // ------------------------------------------------------------------------------------
    // Step 1: Initialize the OpenCL environment
    // ------------------------------------------------------------------------------------
    cl_int err;
    std::string binaryFile = (argc != 2) ? "ydma.xclbin" : argv[1];
    unsigned fileBufSize;
    std::vector<cl::Device> devices = get_xilinx_devices();
    devices.resize(1);
    cl::Device device = devices[0];
    cl::Context context(device, NULL, NULL, NULL, &err);
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
    cl::Buffer in2_buf(context, CL_MEM_READ_ONLY, sizeof(bit512) * 3 * NUM_3D_TRI, NULL, &err);
    cl::Buffer out1_buf(context, CL_MEM_WRITE_ONLY, sizeof(bit64) * CONFIG_SIZE, NULL, &err);
    cl::Buffer out2_buf(context, CL_MEM_WRITE_ONLY, sizeof(bit512) * OUTPUT_SIZE, NULL, &err);

    // Map buffers to kernel arguments, thereby assigning them to specific device memory banks
    krnl_ydma.setArg(0, in1_buf);
    krnl_ydma.setArg(1, in2_buf);
    krnl_ydma.setArg(2, out1_buf);
    krnl_ydma.setArg(3, out2_buf);

    // Map host-side buffer memory to user-space pointers
    bit64 *in1 = (bit64 *)q.enqueueMapBuffer(in1_buf, CL_TRUE, CL_MAP_WRITE, 0, sizeof(bit64) * CONFIG_SIZE);
    bit512 *in2 = (bit512 *)q.enqueueMapBuffer(in2_buf, CL_TRUE, CL_MAP_WRITE, 0, sizeof(bit512) * 3 * NUM_3D_TRI);
    bit64 *out1 = (bit64 *)q.enqueueMapBuffer(out1_buf, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(bit64) * CONFIG_SIZE);
    bit512 *out2 = (bit512 *)q.enqueueMapBuffer(out2_buf, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(bit512) * OUTPUT_SIZE);

    // Initialize the vectors used in the test
    // pack input data for better performance
    //for ( int i = 0; i < CONFIG_SIZE; i++)
    //{

      in1[0].range(63, 32) = 0x00000000;
      in1[0].range(31,  0) = 0x0000000a;

      in1[1].range(63, 32) = 0x00000000;
      in1[1].range(31,  0) = 0x00002568;

      //rasterization2_m.Output_1->zculling_top.Input_1
      in1[2].range(63, 32) = 0x00001800;
      in1[2].range(31,  0) = 0x92100fe0;
      in1[3].range(63, 32) = 0x00002080;
      in1[3].range(31,  0) = 0x21c80000;

      //zculling_top.Output_1->coloringFB_bot_m.Input_1
      in1[4].range(63, 32) = 0x00002000;
      in1[4].range(31,  0) = 0x92900fe0;
      in1[5].range(63, 32) = 0x00002880;
      in1[5].range(31,  0) = 0x22480000;


      //data_redir_m.Output_1->rasterization2_m.Input_1
      in1[6].range(63, 32) = 0x00001000;
      in1[6].range(31,  0) = 0x91900fe0;
      in1[7].range(63, 32) = 0x00001880;
      in1[7].range(31,  0) = 0x21480000;


      //coloringFB_bot_m.Output_1->DMA.Input_1
      in1[8].range(63, 32) = 0x00002800;
      in1[8].range(31,  0) = 0x90900fe0;
      in1[9].range(63, 32) = 0x00000880;
      in1[9].range(31,  0) = 0x22c80000;


      //DMA.Output_1->data_redir_m.Input_1
      in1[10].range(63, 32) = 0x00000800;
      in1[10].range(31,  0) = 0x91100fe0;
      in1[11].range(63, 32) = 0x00001080;
      in1[11].range(31,  0) = 0x20c80000;

    /*for ( int i = 0; i < NUM_3D_TRI; i++)
    {
      in2[3*i](7,0)     = triangle_3ds[i].x0;
      in2[3*i](15,8)    = triangle_3ds[i].y0;
      in2[3*i](23,16)   = triangle_3ds[i].z0;
      in2[3*i](31,24)   = triangle_3ds[i].x1;
      in2[3*i+1](7,0)   = triangle_3ds[i].y1;
      in2[3*i+1](15,8)  = triangle_3ds[i].z1;
      in2[3*i+1](23,16) = triangle_3ds[i].x2;
      in2[3*i+1](31,24) = triangle_3ds[i].y2;
      in2[3*i+2](7,0)   = triangle_3ds[i].z2;
      in2[3*i+2](31,8)  = 0;
    }*/

    for ( int i = 0; i < NUM_3D_TRI * 3; i++)
    {
    	for(int j=0; j<16; j++){
    		in2[i](32*j+31, 32*j) = i*16+j;
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
    //check_results(out2);
    for(int i=0; i<100; i++){
    	for(int j=0; j<16; j++)
    		printf("%d: %08x\n", i, (unsigned int) out2[i].range(j*32+31, j*32));
		//std::cout << "out1[" << i << "]=" << out1[i] << std::endl;
	}

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

void check_results(bit32* output)
{
  #ifndef SW
    bit8 frame_buffer_print[MAX_X][MAX_Y];

    // read result from the 32-bit output buffer
    for (int i = 0, j = 0, n = 0; n < NUM_FB; n ++ )
    {
      bit32 temp = output[n];
      frame_buffer_print[i][j++] = temp(7,0);
      frame_buffer_print[i][j++] = temp(15,8);
      frame_buffer_print[i][j++] = temp(23,16);
      frame_buffer_print[i][j++] = temp(31,24);
      if(j == MAX_Y)
      {
        i++;
        j = 0;
      }
    }
  #endif

  // print result
  {
    for (int j = MAX_X - 1; j >= 0; j -- )
    {
      for (int i = 0; i < MAX_Y; i ++ )
      {
        int pix;
        pix = frame_buffer_print[i][j].to_int();
        if (pix){
          std::cout << "1";
        }else{
          std::cout << "0";
        }
      }
      std::cout << std::endl;
    }
  }

}
/*
void check_results(bit32* output)
{
  #ifndef SW

    // read result from the 32-bit output buffer
    for (int i = 0; i<NUM_FB; i++)
    {
      printf("i=%d, %d\n", i, (int) output[i]); 
    }
  #endif
}
*/
