# Makefile for BNN of Rosetta benchmarks
#
# Author: Yuanlong Xiao (ylxiao@seas.upenn.edu)
#
# Targets:
#   all   - Builds hardware and software in SDSoC.


OPERATORS_OBJ=$(addsuffix .o, $(notdir $(basename $(wildcard operators/*.cpp))))
HOST_OBJ=$(addsuffix .o, $(notdir $(basename $(wildcard standalone/*.cpp))))



INCLUDE=-I /scratch/unsafe/Xilinx/Vivado/2021.1/include 
OPT_LEVEL=-O3
CFLAGS=$(INCLUDE) $(OPT_LEVEL) -DPROFILE
CXX=g++
VPATH=src

all: main
	./main -p /scratch/unsafe/ylxiao/rosetta/optical-flow/datasets/current/ -o /scratch/unsafe/ylxiao/rosetta/optical-flow/datasets/current/out.flo 

main:$(OPERATORS_OBJ) $(HOST_OBJ)
	$(CXX) $(CFLAGS) -o main $^ 

$(HOST_OBJ):%.o:./standalone/%.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^


$(OPERATORS_OBJ):%.o:./operators/%.cpp
	$(CXX) $(CFLAGS) -o $@ -c $^

run: main
	./main -p /scratch/unsafe/ylxiao/rosetta/optical-flow/datasets/current/ -o /scratch/unsafe/ylxiao/rosetta/optical-flow/datasets/current/out.flo > out.log

install:
	echo hello

print: 
	ls ./src

tar:
	tar -czvf ./src.tar.gz ./src/ 


try:
	echo $(notdir $(wildcard ./src)) 



clean:
	rm -rf ./*.o  main


















