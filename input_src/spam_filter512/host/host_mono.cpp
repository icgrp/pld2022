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
//#include "input_data.h"

// Forward declaration of utility functions included at the end of this file
std::vector<cl::Device> get_xilinx_devices();
char *read_binary_file(const std::string &xclbin_file_name, unsigned &nb);
void check_results(FeatureType* param_vector, DataType* data_points, LabelType* labels);

// ------------------------------------------------------------------------------------
// Main program
// ------------------------------------------------------------------------------------
int main(int argc, char **argv)
{
    // ------------------------------------------------------------------------------------
    // Step 1: Initialize the OpenCL environment
    // ------------------------------------------------------------------------------------
    cl_int err;
    std::string binaryFile = (argc != 2) ? "spam_filter.xclbin" : argv[1];
    unsigned fileBufSize;
    std::vector<cl::Device> devices = get_xilinx_devices();
    devices.resize(1);
    cl::Device device = devices[0];
    cl::Context context(device, NULL, NULL, NULL, &err);
    char *fileBuf = read_binary_file(binaryFile, fileBufSize);
    cl::Program::Binaries bins{{fileBuf, fileBufSize}};
    cl::Program program(context, devices, bins, NULL, &err);
    cl::CommandQueue q(context, device, CL_QUEUE_PROFILING_ENABLE, &err);
    cl::Kernel krnl_spam_filter(program, "spam_filter", &err);

    // ------------------------------------------------------------------------------------
    // Step 2: Create buffers and initialize test values
    // ------------------------------------------------------------------------------------
    // Create the buffers and allocate memory
    cl::Buffer in1_buf(context, CL_MEM_READ_ONLY, sizeof(VectorDataType) * NUM_FEATURES * NUM_TRAINING / D_VECTOR_SIZE, NULL, &err);
    cl::Buffer in2_buf(context, CL_MEM_READ_ONLY, sizeof(VectorLabelType) * NUM_TRAINING / L_VECTOR_SIZE, NULL, &err);
    cl::Buffer out_buf(context, CL_MEM_WRITE_ONLY, sizeof(VectorFeatureType) * NUM_FEATURES / F_VECTOR_SIZE, NULL, &err);

    // Map buffers to kernel arguments, thereby assigning them to specific device memory banks
    krnl_spam_filter.setArg(0, in1_buf);
    krnl_spam_filter.setArg(1, in2_buf);
    krnl_spam_filter.setArg(2, out_buf);

    // Map host-side buffer memory to user-space pointers
    VectorDataType *data_points_for_accel = (VectorDataType *)q.enqueueMapBuffer(in1_buf, CL_TRUE, CL_MAP_WRITE, 0, sizeof(VectorDataType) * NUM_FEATURES * NUM_TRAINING / D_VECTOR_SIZE);
    VectorLabelType *labels_for_accel = (VectorLabelType *)q.enqueueMapBuffer(in2_buf, CL_TRUE, CL_MAP_WRITE, 0, sizeof(VectorLabelType) * NUM_TRAINING / L_VECTOR_SIZE);
    VectorFeatureType *param_for_accel = (VectorFeatureType *)q.enqueueMapBuffer(out_buf, CL_TRUE, CL_MAP_WRITE | CL_MAP_READ, 0, sizeof(VectorFeatureType) * NUM_FEATURES / F_VECTOR_SIZE);

    // Initialize the vectors used in the test
    printf("Spam Filter Application\n");

    // parse command line arguments
    std::string path_to_data("../data");
    // sdaccel version and sdsoc/sw version have different command line options

      //parse_sdsoc_command_line_args(argc, argv, path_to_data);

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

    // timers
    struct timeval start, end;


    // sdsoc version host code
      // allocate space for accelerator
      //VectorDataType* data_points_for_accel = (VectorDataType*)malloc(sizeof(VectorDataType) * NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE);
     // VectorLabelType* labels_for_accel = (VectorLabelType*)malloc(sizeof(VectorLabelType) * NUM_TRAINING / L_VECTOR_SIZE);
      //VectorFeatureType* param_for_accel = (VectorFeatureType*)malloc(sizeof(VectorFeatureType) * NUM_FEATURES / F_VECTOR_SIZE);

      // reorganize data for the accelerator
      // data points
      for (int i = 0; i < NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE; i ++ )
        for (int j = 0; j < D_VECTOR_SIZE; j ++ )
          data_points_for_accel[i].range((j+1)*DTYPE_TWIDTH-1, j*DTYPE_TWIDTH) = data_points[i*D_VECTOR_SIZE+j].range(DTYPE_TWIDTH-1, 0);

      // labels
      for (int i = 0; i < NUM_TRAINING / L_VECTOR_SIZE; i ++ )
        for (int j = 0; j < L_VECTOR_SIZE; j ++ )
          labels_for_accel[i].range((j+1)*LTYPE_WIDTH-1, j*LTYPE_WIDTH) = labels[i*L_VECTOR_SIZE+j].range(LTYPE_WIDTH-1, 0);

      // parameter vector
      for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE; i ++ )
        for (int j = 0; j < F_VECTOR_SIZE; j ++ )
          param_for_accel[i].range((j+1)*FTYPE_TWIDTH-1, j*FTYPE_TWIDTH) = param_vector[i*F_VECTOR_SIZE+j].range(FTYPE_TWIDTH-1, 0);


    // ------------------------------------------------------------------------------------
    // Step 3: Run the kernel
    // ------------------------------------------------------------------------------------
    // Set kernel arguments
    for (int epoch = 0; epoch < NUM_EPOCHS; epoch ++ ){
		krnl_spam_filter.setArg(0, in1_buf);
		krnl_spam_filter.setArg(1, in2_buf);
		krnl_spam_filter.setArg(2, out_buf);
		krnl_spam_filter.setArg(3, (epoch == 0));
		krnl_spam_filter.setArg(4, (epoch == 4));
		printf("epoch %d...\n", epoch);

		// Schedule transfer of inputs to device memory, execution of kernel, and transfer of outputs back to host memory
		q.enqueueMigrateMemObjects({in1_buf, in2_buf}, 0 /* 0 means from host*/);
		q.enqueueTask(krnl_spam_filter);
		q.enqueueMigrateMemObjects({out_buf}, CL_MIGRATE_MEM_OBJECT_HOST);

    }
    // Wait for all scheduled operations to finish
    q.finish();
    // reorganize the parameter vector
    for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE; i ++ )
      for (int j = 0; j < F_VECTOR_SIZE; j ++ )
        param_vector[i*F_VECTOR_SIZE+j].range(FTYPE_TWIDTH-1, 0) = param_for_accel[i].range((j+1)*FTYPE_TWIDTH-1, j*FTYPE_TWIDTH);



    // ------------------------------------------------------------------------------------
    // Step 4: Check Results and Release Allocated Resources
    // ------------------------------------------------------------------------------------
    bool match = true;
    check_results( param_vector, data_points, labels );

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


// data structure only used in this file
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
  {
    std::cout << "\nmain parameter vector: \n";
    for(int i = 0; i < 30; i ++ )
    #ifndef SW
      std::cout << "m[" << i << "]: " << param_vector[i].to_float() << " | ";
    #else
      std::cout << "m[" << i << "]: " << param_vector[i] << " | ";
    #endif
    std::cout << std::endl;

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

    std::cout << "Training TPR: " << training_tpr << " %" << std::endl;
    std::cout << "Training FPR: " << training_fpr << " %" <<  std::endl;
    std::cout << "Training Error: " << training_error << " %" <<  std::endl;
    std::cout << "Testing TPR: " << testing_tpr << " %" <<  std::endl;
    std::cout << "Testing FPR: " << testing_fpr << " %" <<  std::endl;
    std::cout << "Testing Error: " << testing_error << " %" <<  std::endl;
  }

}

