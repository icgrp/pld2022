set page_num [lindex $argv 0]
set operator "dataredir"
set benchmark "rendering"
set page_name "page$page_num" 
set part xcu50-fsvh2104-2-e
set page_dcp "../../F003_syn_${benchmark}/${operator}/page_netlist.dcp"
set context_dcp "../../F001_overlay/ydma/zcu102/zcu102_dfx_manual/checkpoint/p_${page_num}.dcp"
set inst_name "level0_i/ulp/ydma_1/inst/${page_name}_inst"
set bit_name "../../F005_bits_${benchmark}/${operator}.bit"
set logFileId [open ./runLogImpl_${operator}.log "w"]
set place_dcp "./${page_name}_design_place.dcp"
set route_dcp "./${page_name}_design_route.dcp"

set_param general.maxThreads 8 

proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    } elseif { [info exist ::env(HOST)] } {
      set host $::env(HOST)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}


set start_time [clock seconds]
create_project -in_memory -part $part
add_files $context_dcp 
add_files $page_dcp
set_property SCOPED_TO_CELLS { level0_i/ulp/ydma_1/inst/page2_inst } [get_files $page_dcp]
add_files ./xdc/sub.xdc
set_property USED_IN {implementation} [get_files ./xdc/sub.xdc]
set_property PROCESSING_ORDER LATE [get_files ./xdc/sub.xdc]
read_xdc ./xdc/impl.xdc
read_xdc ./xdc/dont_partition.xdc
read_xdc -mode out_of_context -cells level0_i/ulp ./xdc//ulp_ooc_copy.xdc
set_property processing_order LATE [get_files ./xdc/ulp_ooc_copy.xdc]

# init design
set start_time [clock seconds]
start_step init_design
set ACTIVE_STEP init_design
puts "source ./scripts/_full_init_pre.tcl"
source ./scripts/_full_init_pre.tcl
set_param project.enablePRFlowIPI 1
set_param bd.debug_profile.script ./scripts/debug_profile_automation.tcl
set_param bd.hooks.addr.debug_scoped_use_ms_name 1
set_param ips.enableSLRParameter 2
set_param hd.Visual 0
set_param bd.enable_dpa 1
set_param project.loadTopLevelOOCConstrs 1
set_param project.gatelevelSubdesign 1
set_param chipscope.maxJobs 1
set_param place.ultrathreadsUsed 0
set_param bd.skipSupportedIPCheck 1
set_param hd.enableClockTrackSelectionEnancement 1
set_param bd.ForceAppCoreUpgrade 1
set_param compiler.enablePerformanceTrace 1
set_property design_mode GateLvl [current_fileset]
set_param project.singleFileAddWarning.threshold 0
set_property webtalk.parent_dir ./prj/prj.cache/wt [current_project]
set_property tool_flow SDx [current_project]
set_property parent.project_path ./prj/prj.xpr [current_project]
link_design -mode default -reconfig_partitions { level0_i/ulp/ydma_1/inst/page2_inst } -part $part -top level0_wrapper
puts "source ./scripts/_full_init_post.tcl"
source ./scripts/_full_init_post.tcl

set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "read_checkpoint: $total_seconds seconds"


# opt design
set start_time [clock seconds]
start_step opt_design
set ACTIVE_STEP opt_design
puts "source ./scripts/_full_opt_pre.tcl"
source ./scripts/_full_opt_pre.tcl
opt_design 
puts "source ./scripts/_full_opt_post.tcl"
source ./scripts/_full_opt_post.tcl
end_step opt_design
unset ACTIVE_STEP 
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "opt: $total_seconds seconds"

# place design
set start_time [clock seconds]
start_step place_design
set ACTIVE_STEP place_design
puts "source ./scripts/_full_place_pre.tcl"
source ./scripts/_full_place_pre.tcl
implement_debug_core 
place_design 
puts "source ./scripts/_full_place_post.tcl"
source ./scripts/_full_place_post.tcl
end_step place_design
unset ACTIVE_STEP 
write_checkpoint -force $place_dcp
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "place: $total_seconds seconds"

# opt design
set start_time [clock seconds]
start_step phys_opt_design
set ACTIVE_STEP phys_opt_design
phys_opt_design 
end_step phys_opt_design
unset ACTIVE_STEP 
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "opt_physical: $total_seconds seconds"

# route design
set start_time [clock seconds]
start_step route_design
set ACTIVE_STEP route_design
route_design 
end_step route_desing
unset ACTIVE_STEP 
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "route: $total_seconds seconds"
write_checkpoint -force $route_dcp

set_property IS_ENABLED 0 [get_drc_checks {PPURQ-1}]
# generate bistream
set start_time [clock seconds]
write_bitstream -cell $inst_name -force $bit_name
set end_time [clock seconds]
set total_seconds [expr $end_time - $start_time]
puts $logFileId "bitgen: $total_seconds seconds"
report_timing_summary > timing_${page_name}.rpt

