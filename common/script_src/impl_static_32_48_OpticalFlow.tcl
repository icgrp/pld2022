set logFileId [open ./runLog_impl_big_static_32_48.log "w"]

#####################
## read_checkpoint ##
#####################
set start_time [clock seconds]
open_checkpoint ../F001_static_32_leaves/floorplan_static.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_2/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_3/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_4/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_5/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_6/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_7/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_8/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_9/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_10/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_11/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_12/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_13/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_14/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_15/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_16/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_17/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_18/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_19/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_20/inst ../F003_syn_optical_flow/flow_calc_1/flow_calc_1_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_21/inst ../F003_syn_optical_flow/flow_calc_2/flow_calc_2_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_22/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_23/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_24/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_25/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_26/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_27/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_28/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_29/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_30/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
read_checkpoint -cell floorplan_static_i/leaf_empty_31/inst ../F003_syn_rendering/user_kernel/user_kernel_leaf_netlist_48.dcp
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "read_checkpoint: $total_seconds seconds"

####################
## implementation ##
####################
set start_time [clock seconds]
opt_design
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "opt: $total_seconds seconds"
set start_time [clock seconds]
place_design
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "place: $total_seconds seconds"
# write_hwdef -force pr_test_wrapper.hwdef
write_checkpoint -force init_placed_32_48.dcp
set start_time [clock seconds]
route_design
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "route: $total_seconds seconds"
write_checkpoint -force init_routed_32_48.dcp
set_param bitstream.enablePR 2341
write_bitstream -force -no_partial_bitfile  ./main.bit
#############################################
## create static design with no bft pblock ##
#############################################

set start_time [clock seconds]
update_design -cell floorplan_static_i/axi_leaf -black_box
update_design -cell floorplan_static_i/bft_01 -black_box
update_design -cell floorplan_static_i/bft_10 -black_box
update_design -cell floorplan_static_i/bft_11 -black_box
update_design -cell floorplan_static_i/bft_center -black_box
update_design -cell floorplan_static_i/leaf_empty_2/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_3/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_4/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_5/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_6/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_7/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_8/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_9/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_10/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_11/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_12/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_13/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_14/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_15/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_16/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_17/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_18/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_19/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_20/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_21/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_22/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_23/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_24/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_25/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_26/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_27/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_28/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_29/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_30/inst -black_box
update_design -cell floorplan_static_i/leaf_empty_31/inst -black_box
update_design -cell floorplan_static_i/axi_leaf -buffer_ports
update_design -cell floorplan_static_i/bft_01 -buffer_ports
update_design -cell floorplan_static_i/bft_10 -buffer_ports
update_design -cell floorplan_static_i/bft_11 -buffer_ports
update_design -cell floorplan_static_i/bft_center -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_2/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_3/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_4/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_5/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_6/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_7/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_8/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_9/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_10/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_11/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_12/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_13/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_14/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_15/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_16/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_17/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_18/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_19/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_20/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_21/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_22/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_23/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_24/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_25/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_26/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_27/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_28/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_29/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_30/inst -buffer_ports
update_design -cell floorplan_static_i/leaf_empty_31/inst -buffer_ports
lock_design -level routing
write_checkpoint -force big_static_routed_32_48.dcp
close_design
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "update, black_box: $total_seconds seconds"
# set start_time [clock seconds]
# set end_time [clock seconds]
# set total_seconds [expr $end_time - $start_time]
# puts $logFileId "write bitstream: $total_seconds seconds"
