
SRC_DIR=../src

all: load.exe app.exe emconfig.json $(kl_name).xclbin

app.exe: $(SRC_DIR)/host.cpp
	g++ -Wall -g -std=c++11 $(SRC_DIR)/host.cpp -o app.exe \
		-I${XILINX_XRT}/include/ \
		-I${XILINX_VIVADO}/include/ \
		-L${XILINX_XRT}/lib/ -lOpenCL -lpthread -lrt -lstdc++

load.exe: $(SRC_DIR)/load.cpp
	g++ -Wall -g -std=c++11 $(SRC_DIR)/load.cpp -o load.exe \
		-I${XILINX_XRT}/include/ \
		-I${XILINX_VIVADO}/include/ \
		-L${XILINX_XRT}/lib/ -lOpenCL -lpthread -lrt -lstdc++
	
$(kl_name).xo: $(SRC_DIR)/$(kl_name).cpp
	v++ -c -t ${TARGET} --config $(SRC_DIR)/au50_dfx.cfg -k $(kl_name) \
                --kernel_frequency 200 \
		-I${XILINX_VIVADO}/include/ \
		-I$(SRC_DIR)/ \
		$(SRC_DIR)/$(kl_name).cpp -o $(kl_name).xo 

$(kl_name).xclbin: ./$(kl_name).xo
	v++ -l -t ${TARGET} --config $(SRC_DIR)/au50_dfx.cfg \
        --kernel_frequency 200 \
        --vivado.synth.jobs $(MaxJobNum) --vivado.impl.jobs $(MaxJobNum) ./$(kl_name).xo -o $(kl_name).xclbin

emconfig.json:
	emconfigutil --platform ${PLATFORM} --nd 1

clean:
	rm -rf ydma*  app.exe *json *csv *log *summary _x xilinx* .run .Xil .ipcache *.jou

# Unless specified, use the current directory name as the v++ build target
# TARGET ?= $(notdir $(CURDIR))
TARGET = hw
