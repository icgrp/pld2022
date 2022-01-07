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

#include <sys/time.h>

#define DATA_SIZE 4096



#define CONFIG_SIZE 16
#define INPUT_SIZE 720071 //((64*1024*5+32)*4500/4/32)/16
#define OUTPUT_SIZE (64*512/32/16)

// Forward declaration of utility functions included at the end of this file
std::vector<cl::Device> get_xilinx_devices();
char *read_binary_file(const std::string &xclbin_file_name, unsigned &nb);

void check_results(FeatureType* param_vector, DataType* data_points, LabelType* labels);



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

      std::string path_to_data("/home/ylxiao/ws_211/prflow_riscv/input_src/spam_filter512/data");

      // allocate space
      // for software verification
      DataType*    data_points  = new DataType[DATA_SET_SIZE];
      LabelType*   labels       = new LabelType  [NUM_SAMPLES];
      FeatureType* param_vector = new FeatureType[NUM_FEATURES];

      // read in dataset
	  std::string str_points_filepath = path_to_data + "/shuffledfeats.dat";
	  std::string str_labels_filepath = path_to_data + "/shuffledlabels.dat";

	  FILE* data_file;
	  FILE* label_file;

	  data_file = fopen(str_points_filepath.c_str(), "r");
	  if (!data_file)
	  {
		printf("Failed to open data file %s!\n", str_points_filepath.c_str());
		return EXIT_FAILURE;
	  }
	  for (int i = 0; i < DATA_SET_SIZE; i ++ )
	  {
		float tmp;
		fscanf(data_file, "%f", &tmp);
		data_points[i] = tmp;
	  }
	  fclose(data_file);

	  label_file = fopen(str_labels_filepath.c_str(), "r");
	  if (!label_file)
	  {
		printf("Failed to open label file %s!\n", str_labels_filepath.c_str());
		return EXIT_FAILURE;
	  }
	  for (int i = 0; i < NUM_SAMPLES; i ++ )
	  {
		int tmp;
		fscanf(label_file, "%d", &tmp);
		labels[i] = tmp;
	  }
	  fclose(label_file);

	  // reset parameter vector
	  for (size_t i = 0; i < NUM_FEATURES; i++)
		param_vector[i] = 0;


	  int in2_cnt = 0;
	  int cnt_32bits = 0;
      // labels
	  VectorLabelType labels_for_accel;
	                      // 4500         4
      for (int i = 0; i < NUM_TRAINING / L_VECTOR_SIZE; i ++ ){
    	                     // 4
        for (int j = 0; j < L_VECTOR_SIZE; j ++ ){
        	                             // 8
          labels_for_accel.range((j+1)*LTYPE_WIDTH-1, j*LTYPE_WIDTH) = labels[i*L_VECTOR_SIZE+j].range(LTYPE_WIDTH-1, 0);
        }
        int offset = cnt_32bits%16;
      	in2[in2_cnt](offset*32+31, offset*32) = labels_for_accel;
      	cnt_32bits++;
      	if((cnt_32bits%16) == 0){
      		in2_cnt++;
      	}
      }

      for(int dummy_i=0; dummy_i<11; dummy_i++){
        int offset = cnt_32bits%16;
        in2[in2_cnt](offset*32+31, offset*32) = 0;
        cnt_32bits++;
        if((cnt_32bits%16) == 0){
          in2_cnt++;
        }
      }

      printf("cnt_32bits=%d\n", cnt_32bits);

      VectorDataType data_points_for_accel;
      for(int epoch=0; epoch<NUM_EPOCHS; epoch++){
        // reorganize data for the accelerator
        // data points
        for (int i = 0; i < NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE; i ++ ){
          for (int j = 0; j < D_VECTOR_SIZE; j ++ )
            data_points_for_accel.range((j+1)*DTYPE_TWIDTH-1, j*DTYPE_TWIDTH) = data_points[i*D_VECTOR_SIZE+j].range(DTYPE_TWIDTH-1, 0);
          int offset = cnt_32bits%16;
          in2[in2_cnt](offset*32+31, offset*32) = data_points_for_accel.range(31,  0);
          cnt_32bits++;
          if((cnt_32bits%16) == 0){
            in2_cnt++;
          }

          offset = cnt_32bits%16;
          in2[in2_cnt](offset*32+31, offset*32) = data_points_for_accel.range(63, 32);
          cnt_32bits++;
          if((cnt_32bits%16) == 0){
            in2_cnt++;
          }
        }
      }

      std::cout << "in2_cnt=" << in2_cnt << std::endl;
      printf("cnt_32bits=%d\n", cnt_32bits);



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
    // parameter vector
    for (int i = 0; i < 64; i ++ ){
      for(int j=0; j<16; j++){
        param_vector[i*16+j](31, 0) = out2[i](j*32+31, j*32);
    	  //printf("param_vector[%d]=%08x\n", i*2+j, (unsigned int) param_vector[i*2+j].range(31, 0));
      }
    }
    std::cout << "We should get |   97.83   |    0.18   |     0.91    |  93.48   |   2.53   |    4.00    |" << std::endl;
    check_results( param_vector, data_points, labels );
    // for(int i=0; i<CONFIG_SIZE; i++){
    int max_config = CONFIG_SIZE > 20 ? 20 : CONFIG_SIZE;
    for(int i=0; i<max_config; i++){
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

typedef struct DataSet_s 
{
  DataType*    data_points;
  LabelType*   labels;
  FeatureType* parameter_vector;
  size_t num_data_points;
  size_t num_features;
} DataSet;


// sub-functions for result checking
// dot product
float dotProduct(FeatureType* param_vector, DataType* data_point_i, const size_t num_features)
{
  FeatureType result = 0.0f;

  for (int i = 0; i < num_features; i ++ )
    result += param_vector[i] * data_point_i[i];

  #ifndef SW
    return result.to_float();
  #else
    return result;
  #endif
}

// predict
LabelType getPrediction(FeatureType* parameter_vector, DataType* data_point_i, size_t num_features, const double treshold = 0) 
{
  float parameter_vector_dot_x_i = dotProduct(parameter_vector, data_point_i, num_features);
  return (parameter_vector_dot_x_i > treshold) ? 1 : 0;
}

// compute error rate
double computeErrorRate(
    DataSet data_set,
    double& cumulative_true_positive_rate,
    double& cumulative_false_positive_rate,
    double& cumulative_error)
{

  size_t true_positives = 0, true_negatives = 0, false_positives = 0, false_negatives = 0;

  for (size_t i = 0; i < data_set.num_data_points; i++) 
  {
    LabelType prediction = getPrediction(data_set.parameter_vector, &data_set.data_points[i * data_set.num_features], data_set.num_features);
    if (prediction != data_set.labels[i])
    {
      if (prediction == 1)
        false_positives++;
      else
        false_negatives++;
    } 
    else 
    {
      if (prediction == 1)
        true_positives++;
      else
        true_negatives++;
    }
  }

  double error_rate = (double)(false_positives + false_negatives) / data_set.num_data_points;

  cumulative_true_positive_rate += (double)true_positives / (true_positives + false_negatives);
  cumulative_false_positive_rate += (double)false_positives / (false_positives + true_negatives);
  cumulative_error += error_rate;

  return error_rate;
}

// check results
void check_results(FeatureType* param_vector, DataType* data_points, LabelType* labels)
{

  printf("\nmain parameter vector: \n");
  for(int i = 0; i < 30; i ++ )
  #ifndef SW
    printf("m[%d]: %f | ", i, param_vector[i].to_float());
  #else
    printf("m[%d]: %f | ", i, param_vector[i]);
  #endif
  printf("\n");

  // Initialize benchmark variables
  double training_tpr = 0.0;
  double training_fpr = 0.0;
  double training_error = 0.0;
  double testing_tpr = 0.0;
  double testing_fpr = 0.0;
  double testing_error = 0.0;

  // Get Training error
  DataSet training_set;
  training_set.data_points = data_points;
  training_set.labels = labels;
  training_set.num_data_points = NUM_TRAINING;
  training_set.num_features = NUM_FEATURES;
  training_set.parameter_vector = param_vector;
  computeErrorRate(training_set, training_tpr, training_fpr, training_error);

  // Get Testing error
  DataSet testing_set;
  testing_set.data_points = &data_points[NUM_FEATURES * NUM_TRAINING];
  testing_set.labels = &labels[NUM_TRAINING];
  testing_set.num_data_points = NUM_TESTING;
  testing_set.num_features = NUM_FEATURES;
  testing_set.parameter_vector = param_vector;
  computeErrorRate(testing_set, testing_tpr, testing_fpr, testing_error);

  training_tpr *= 100.0;
  training_fpr *= 100.0;
  training_error *= 100.0;
  testing_tpr *= 100.0;
  testing_fpr *= 100.0;
  testing_error *= 100.0;

  printf("+-----------+-----------+-------------+----------+----------+------------+\n");
  printf("| Train TPR | Train FPR | Train Error | Test TPR | Test FPR | Test Error |\n");
  printf("+-----------+-----------+-------------+----------+----------+------------+\n");
  printf("|   %5.2f   |   %5.2f   |    %5.2f    |  %5.2f   |  %5.2f   |   %5.2f    |\n", training_tpr, 
         training_fpr, training_error, testing_tpr, testing_fpr, testing_error);
  printf("+-----------+-----------+-------------+----------+----------+------------+\n");

}
