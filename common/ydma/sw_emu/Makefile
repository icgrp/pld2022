PRJ_NAME=ydma
SRC_DIR=../src

all: app.exe emconfig.json $(PRJ_NAME).xclbin

app.exe: $(SRC_DIR)/host.cpp
	g++ -Wall -g -std=c++11 $(SRC_DIR)/host.cpp -o app.exe \
		-I${XILINX_XRT}/include/ \
		-I${XILINX_VIVADO}/include/ \
		-L${XILINX_XRT}/lib/ -lOpenCL -lpthread -lrt -lstdc++
	
$(PRJ_NAME).xo: $(SRC_DIR)/$(PRJ_NAME).cpp
	v++ -c -t ${TARGET} --config $(SRC_DIR)/u50.cfg -k $(PRJ_NAME) \
		-I${XILINX_VIVADO}/include/ \
		-I$(SRC_DIR)/ \
		$(SRC_DIR)/$(PRJ_NAME).cpp -o $(PRJ_NAME).xo 

$(PRJ_NAME).xclbin: ./$(PRJ_NAME).xo
	v++ -l -t ${TARGET} --config $(SRC_DIR)/u50.cfg ./$(PRJ_NAME).xo -o $(PRJ_NAME).xclbin

emconfig.json:
	emconfigutil --platform xilinx_u50_gen3x16_xdma_201920_3 --nd 1

clean:
	rm -rf $(PRJ_NAME)* app.exe *json *csv *log *summary _x xilinx* .run .Xil .ipcache *.jou

# Unless specified, use the current directory name as the v++ build target
TARGET ?= $(notdir $(CURDIR))
