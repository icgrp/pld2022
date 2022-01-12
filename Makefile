
#prj_name=digit_reg_small
#prj_name=spam_filter_small
#prj_name=data_move
#prj_name=data_shift


#prj_name=datamover
prj_name=rendering512
#prj_name=digit_reg512
#prj_name=bnn512
#prj_name=bnn1
#prj_name=face_detection512
#prj_name=spam_filter512
#prj_name=spam_filter512_old
#prj_name=optical_flow512
#prj_name=optical_flow512_debug

src=./common/verilog_src
ws=workspace
ws_sdk=$(ws)/F007_sdk_$(prj_name)
ws_overlay=$(ws)/F001_overlay
ws_hls=$(ws)/F002_hls_$(prj_name)
ws_syn=$(ws)/F003_syn_$(prj_name)
ws_impl=$(ws)/F004_impl_$(prj_name)
ws_bit=$(ws)/F005_bits_$(prj_name)
ws_mono=$(ws)/F007_mono_$(prj_name)
ws_mbft=$(ws)/F007_mono_bft_$(prj_name)

operators_dir=./input_src/$(prj_name)/operators
operators_src=$(wildcard $(operators_dir)/*.cpp)
operators=$(basename $(notdir $(operators_src)))
operators_hls_targets=$(foreach n, $(operators), $(ws_hls)/runLog$(n).log)
operators_syn_targets=$(foreach n, $(operators), $(ws_syn)/$(n)/page_netlist.dcp)
operators_impl_targets=$(foreach n, $(operators), $(ws_impl)/$(n)/page_routed.dcp)
operators_bit_targets=$(foreach n, $(operators), $(ws_bit)/$(n).bit)
operators_xclbin_targets=$(foreach n, $(operators), $(ws_bit)/$(n).xclbin)
operators_runtime_target=$(ws_bit)/sd_card/app.exe
mono_target=$(ws_mono)/ydma.xclbin
operators_ip_targets=$(foreach n, $(operators), $(ws_mbft)/ip_repo/$(n)/prj/floorplan_static.xpr)
mono_bft_target=$(ws_mbft)/prj/floorplan_static.runs/impl_1/floorplan_static_wrapper.bit
download_target=$(ws_bit)/download.tcl 
config_target=$(ws_mbft)/config.cpp 

# all: $(mono_target)
all: $(operators_runtime_target)
mono: $(mono_target)

$(mono_target):./input_src/$(prj_name)/host/top.cpp ./pr_flow/monolithic.py $(operators_hls_targets)
	python2 pr_flow.py $(prj_name) -monolithic -op '$(basename $(notdir $(operators_bit_targets)))'
	cd $(ws_mono) && ./main.sh
	
$(operators_runtime_target):./input_src/$(prj_name)/host/host.cpp $(operators_xclbin_targets) ./pr_flow/runtime.py
	python2 pr_flow.py $(prj_name) -runtime -op '$(basename $(notdir $(operators_bit_targets)))'
	cp $(operators_xclbin_targets) $(ws_bit)/sd_card
	cd $(ws_bit)/$(prj_name)/sw_emu && ./build_and_run.sh
	
$(operators_xclbin_targets):$(ws_bit)/%.xclbin:$(ws_bit)/%.bit
	python2 pr_flow.py $(prj_name) -xclbin -op $(basename $(notdir $@))
	cd $(ws_bit) && ./main_$(basename $(notdir $@)).sh

$(download_target): $(operators_bit_targets)
	python2 pr_flow.py $(prj_name) -bit -op '$(basename $(notdir $^))'

bits:$(operators_bit_targets)
# Implementation from post-synthesis DCP to bitstreams
# generate bitstream for each operator
$(operators_bit_targets):$(ws_bit)/%.bit:$(ws_overlay)/__overlay_is_ready__ $(ws_syn)/%/page_netlist.dcp 
	python2 pr_flow.py $(prj_name) -impl -op $(basename $(notdir $@))
	cd $(ws_impl)/$(basename $(notdir $@)) && ./main.sh

syn:$(operators_syn_targets)
# Out-of-Context Synthesis from Verilog to post-synthesis DCP
$(operators_syn_targets):$(ws_syn)/%/page_netlist.dcp:$(ws_hls)/runLog%.log $(ws_overlay)/__overlay_is_ready__
	python2 pr_flow.py $(prj_name) -syn -op $(subst runLog,,$(basename $(notdir $<)))
	#cd $(ws_syn)/$(subst runLog,,$(basename $(notdir $<)))/riscv && ./qsub_run.sh
	cd $(ws_syn)/$(subst runLog,,$(basename $(notdir $<))) && ./main.sh


# High-Level-Synthesis from C to Verilog
$(operators_hls_targets):$(ws_hls)/runLog%.log:$(operators_dir)/%.cpp $(operators_dir)/%.h
	python2 pr_flow.py $(prj_name) -hls -op $(basename $(notdir $<))
	cd $(ws_hls) && ./main_$(basename $(notdir $<)).sh


#$(ws_overlay)/overlay.dcp: $(ws_overlay)/src  
#	cp -rf ./common/overlay/riscv_bit_lib ./workspace/F001_overlay
#	cp -rf ./common/verilog_src ./workspace/F001_overlay/src
#	cp -rf ./common/overlay/size_table/* ./workspace/F001_overlay
#	cp -rf ./common/overlay/dcp_lib/* ./workspace/F001_overlay
#	cp -rf ./common/overlay/main.bit ./workspace/F001_overlay
#	touch ./workspace/F001_overlay/*


$(ws_overlay)/src : common/verilog_src/*  common/script_src/project_syn_gen_zcu102.tcl
	rm -rf ./workspace/F001_overlay
	mkdir -p ./workspace/F001_overlay
	python2 pr_flow.py $(prj_name) -g


config: $(config_target)

$(config_target): $(operators_src)
	python2 pr_flow.py $(prj_name) -cfg -op '$(basename $(notdir $^))'
	cp $(ws)/F008_sdk_$(prj_name)/cpp_src/* $(ws)/vitis/$(prj_name)/src/



HW:
	python2 ./pr_flow/riscv2HW.py $(prj_name)

riscv:
	python2 ./pr_flow/HW2riscv.py $(prj_name)


mono_prj: $(mono_bft_target)

# prepare the logic equivalent monolithic project 
$(mono_bft_target): $(ws_overlay)/src  $(operators_ip_targets)
	python2 pr_flow.py $(prj_name) -mbft
	cd $(ws_mbft) && ./main.sh


# prepare the ip package for monolithic project
$(operators_ip_targets):$(ws_mbft)/ip_repo/%/prj/floorplan_static.xpr:$(ws_hls)/runLog%.log
	echo $@
	python2 pr_flow.py $(prj_name) -ip -op $(subst runLog,,$(basename $(notdir $<)))
	cd $(ws_mbft)/ip_repo/$(subst runLog,,$(basename $(notdir $<))) && ./qsub_run.sh

cp_mono_prj: ./workspace/vitis/floorplan_static_wrapper.xsa 

./workspace/vitis/floorplan_static_wrapper.xsa: ./workspace/F007_mono_bft_$(prj_name)/prj/floorplan_static.sdk/floorplan_static_wrapper.xsa
	mkdir -p workspace/vitis
	cp $< ./workspace/vitis

overlay: $(ws_overlay)/__overlay_is_ready__

$(ws_overlay)/__overlay_is_ready__:
	python2 pr_flow.py $(prj_name) -g
	cp -rf ./common/overlay/size_table/* ./workspace/F001_overlay
	cd ./workspace/F001_overlay && ./main.sh
	

run:
	cd $(ws_bit) && ./run_app.sh

touch:
	touch $(operators_hls_targets)
	touch $(operators_syn_targets)
	touch $(operators_bit_targets)
	touch $(operators_xclbin_targets)
	# touch $(operators_runtime_target)




.PHONY: report 
report: 
	 python2 ./pr_flow.py $(prj_name) -op '$(basename $(notdir $(operators_bit_targets)))' -rpt

clear:
	rm -rf ./workspace/*$(prj_name) 
clean:
	rm -rf ./workspace
	rm -rf ./pr_flow/*.pyc

