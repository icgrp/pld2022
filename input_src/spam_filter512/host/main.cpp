/*===============================================================*/
/*                                                               */
/*                        spam_filter.cpp                        */
/*                                                               */
/*      Main host function for the Spam Filter application.      */
/*                                                               */
/*===============================================================*/

// standard C/C++ headers
#include <cstdio>
#include <cstdlib>
#include <getopt.h>
#include <string>
#include <time.h>
#include <sys/time.h>
#include <hls_stream.h>
#define SDSOC




// other headers
//#include "utils.h"
#include "typedefs.h"
//#include "check_result.h"
#include "top.h"

void print_usage(char* filename)
{
    printf("usage: %s <options>\n", filename);
    printf("  -f [kernel file]\n");
    printf("  -p [path to data]\n");
}

void parse_sdaccel_command_line_args(
    int argc,
    char** argv,
    std::string& kernelFile,
    std::string& path_to_data) 
{

  int c = 0;

  while ((c = getopt(argc, argv, "f:p:")) != -1) 
  {
    switch (c) 
    {
      case 'f':
        kernelFile = optarg;
        break;
      case 'p':
        path_to_data = optarg;
        break;
      default:
      {
        print_usage(argv[0]);
        exit(-1);
      }
    } // matching on arguments
  } // while args present
}

void parse_sdsoc_command_line_args(
    int argc,
    char** argv,
    std::string& path_to_data) 
{

  int c = 0;

  while ((c = getopt(argc, argv, "f:p:")) != -1) 
  {
    switch (c) 
    {
      case 'p':
        path_to_data = optarg;
        break;
      default:
      {
        print_usage(argv[0]);
        exit(-1);
      }
    } // matching on arguments
  } // while args present
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

    return result.to_float();
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
    printf("m[%d]: %f | ", i, param_vector[i].to_float());
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
  VectorDataType data_points_for_accel[NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE];
  //VectorLabelType labels_for_accel[NUM_TRAINING / L_VECTOR_SIZE];
  VectorLabelType labels_for_accel[1200];
  VectorFeatureType param_for_accel[NUM_FEATURES / F_VECTOR_SIZE];





int main(int argc, char *argv[])
{
	hls::stream<ap_uint<512> > Input_1("sbb0");; //64
	VectorLabelType b; //32
	hls::stream<ap_uint<512> > Output_1("sbb1");; //64

	int in_cnt = 0;

  setbuf(stdout, NULL);


  // parse command line arguments
  std::string path_to_data("/scratch/unsafe/ylxiao/F211230_qsub/prflow_riscv/input_src/spam_filter512_old/data");
  // sdaccel version and sdsoc/sw version have different command line options
    parse_sdsoc_command_line_args(argc, argv, path_to_data);

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

    // run the accelerator
    gettimeofday(&start, NULL);


    // labels

    for (int epoch = 0; epoch < NUM_EPOCHS; epoch ++ )
    {
    	//Input_1.write(epoch);
    	if (epoch == 0){
    	    //for (int i = 0; i < NUM_TRAINING / L_VECTOR_SIZE; i ++ ){
      	    for (int i = 0; i < 71; i ++ ){
      	    	bit512 Input_tmp;
      	    	for(int j=0; j<16; j++){
					Input_tmp(j*32+31,j*32)   = labels_for_accel[16*i+j];
      	    	}
    	    	Input_1.write(Input_tmp);
    	    	in_cnt++;
    	    }


    	}

        for (int i = 0; i < NUM_TRAINING * NUM_FEATURES / D_VECTOR_SIZE/8; i ++ )
        {
        	bit512 Input_tmp;
        	for(int j=0; j<8; j++){
				Input_tmp(j*64+63,j*64)   = data_points_for_accel[8*i+j].range(63, 0);
        	}
        	Input_1.write(Input_tmp);
        	in_cnt++;
        }

      printf("epoch %d...\n", epoch);
    }

    top(Input_1, Output_1);
    gettimeofday(&end, NULL);

    // parameter vector
    for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE / 8; i ++ )
    {
    	bit512 Output_tmp = Output_1.read();
    	for(int j=0; j<8; j++){
    		param_for_accel[8*i+j].range(63, 0) = Output_tmp(j*64+63, j*64);
    	}
    }



    // reorganize the parameter vector
    for (int i = 0; i < NUM_FEATURES / F_VECTOR_SIZE; i ++ )
      for (int j = 0; j < F_VECTOR_SIZE; j ++ )
        param_vector[i*F_VECTOR_SIZE+j].range(FTYPE_TWIDTH-1, 0) = param_for_accel[i].range((j+1)*FTYPE_TWIDTH-1, j*FTYPE_TWIDTH);



  // check results
  printf("Checking results:\n");
  printf("We should get |   97.83   |    0.18   |     0.91    |  93.48   |   2.53   |    4.00    |\n");
  check_results( param_vector, data_points, labels );
    
  // print time
  long long elapsed = (end.tv_sec - start.tv_sec) * 1000000LL + end.tv_usec - start.tv_usec;   
  printf("elapsed time: %lld us\n", elapsed);



  delete []data_points;
  delete []labels;
  delete []param_vector;

  printf("in_cnt = %d\n", in_cnt);
  return EXIT_SUCCESS;
}




