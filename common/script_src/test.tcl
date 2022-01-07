set logFileId [open ./runLog.log "w"]
set_param general.maxThreads 1
#####################
## read_checkpoint ##
#####################
set start_time [clock seconds]
open_checkpoint ./floorplan_wrapper_opt.dcp
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
write_checkpoint  -force  test_opt.dcp

set start_time [clock seconds]
place_design  
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "place: $total_seconds seconds"
write_checkpoint  -force  test_placed.dcp

set start_time [clock seconds]
route_design  
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "route: $total_seconds seconds"
write_checkpoint -force   test_routed.dcp


###############
## bitstream ##
###############
set start_time [clock seconds]
write_bitstream -force test.bit
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "bits: $total_seconds seconds"
report_utilization -hierarchical > utilization.rpt
