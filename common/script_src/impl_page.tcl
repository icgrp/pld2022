# 
# Report generation script generated by Vivado
# 

set page_num [lindex $argv 0]
set operator "dataredir"
set benchmark "rendering"
set page_name "page$page_num" 
set part xcu50-fsvh2104-2-e
set page_dcp "../../F003_syn_${benchmark}/${operator}/page_netlist.dcp"
set context_dcp "../../F001_overlay/ydma/zcu102/zcu102_dfx_manual/checkpoint/p_${page_num}.dcp"
set inst_name "pfm_top_i/dynamic_region/ydma_1/${page_name}_inst"
set bit_name "../../F005_bits_${benchmark}/${operator}.bit"
set logFileId [open ./runLogImpl_${operator}.log "w"]
set place_dcp "./${page_name}_design_place.dcp"
set route_dcp "./${page_name}_design_route.dcp"

set_param general.maxThreads 8 


proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
namespace eval ::optrace {
  variable script "/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/vivado/vpl/prj/prj.runs/impl_1/pfm_top_wrapper.tcl"
  variable category "vivado_impl"
}

# Try to connect to running dispatch if we haven't done so already.
# This code assumes that the Tcl interpreter is not using threads,
# since the ::dispatch::connected variable isn't mutex protected.
if {![info exists ::dispatch::connected]} {
  namespace eval ::dispatch {
    variable connected false
    if {[llength [array get env XILINX_CD_CONNECT_ID]] > 0} {
      set result "true"
      if {[catch {
        if {[lsearch -exact [package names] DispatchTcl] < 0} {
          set result [load librdi_cd_clienttcl[info sharedlibextension]] 
        }
        if {$result eq "false"} {
          puts "WARNING: Could not load dispatch client library"
        }
        set connect_id [ ::dispatch::init_client -mode EXISTING_SERVER ]
        if { $connect_id eq "" } {
          puts "WARNING: Could not initialize dispatch client"
        } else {
          puts "INFO: Dispatch client connection id - $connect_id"
          set connected true
        }
      } catch_res]} {
        puts "WARNING: failed to connect to dispatch server - $catch_res"
      }
    }
  }
}
if {$::dispatch::connected} {
  # Remove the dummy proc if it exists.
  if { [expr {[llength [info procs ::OPTRACE]] > 0}] } {
    rename ::OPTRACE ""
  }
  proc ::OPTRACE { task action {tags {} } } {
    ::vitis_log::op_trace "$task" $action -tags $tags -script $::optrace::script -category $::optrace::category
  }
  # dispatch is generic. We specifically want to attach logging.
  ::vitis_log::connect_client
} else {
  # Add dummy proc if it doesn't exist.
  if { [expr {[llength [info procs ::OPTRACE]] == 0}] } {
    proc ::OPTRACE {{arg1 \"\" } {arg2 \"\"} {arg3 \"\" } {arg4 \"\"} {arg5 \"\" } {arg6 \"\"}} {
        # Do nothing
    }
  }
}

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

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
OPTRACE "impl_1" END { }
}


set start_time [clock seconds]

source ./scripts/_full_init_pre.tcl
 
set_param project.enablePRFlowIPI 1
set_param bd.debug_profile.script ./scripts/debug_profile_automation.tcl
set_param ips.enableSLRParameter 2
set_param hd.Visual 0
set_param bd.ForceAppCoreUpgrade 1
set_param bd.enable_dpa 1
set_param project.loadTopLevelOOCConstrs 1
set_param project.gatelevelSubdesign 1
set_param place.ultrathreadsUsed 0
set_param chipscope.maxJobs 2
set_param compiler.enablePerformanceTrace 1
set_param bd.skipSupportedIPCheck 1


create_project -in_memory -part $part
set_property board_part_repo_paths {/home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/vivado/vpl/.local/hw_platform/board} [current_project]
set_property board_part xilinx.com:zcu102:part0:3.2 [current_project]
set_property design_mode GateLvl [current_fileset]
set_param project.singleFileAddWarning.threshold 0
set_property webtalk.parent_dir /home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/vivado/vpl/prj/prj.cache/wt [current_project]
set_property tool_flow SDx [current_project]
set_property parent.project_path /home/ylxiao/ws_211/prflow/workspace/F001_overlay/ydma/zcu102/_x/link/vivado/vpl/prj/prj.xpr [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
set_param project.isImplRun true
set_param project.isImplRun false


add_files $context_dcp 
add_files $page_dcp
set_property SCOPED_TO_CELLS { pfm_top_i/dynamic_region/ydma_1/page2_inst } [get_files $page_dcp]
read_xdc ./xdc/dynamic_impl.xdc
read_xdc ./xdc/dont_partition.xdc
read_xdc ./xdc/_post_sys_link_gen_constrs.xdc
read_xdc -mode out_of_context -cells pfm_top_i/dynamic_region ./xdc/pfm_dynamic_ooc_copy.xdc
set_property processing_order LATE [get_files ./xdc/pfm_dynamic_ooc_copy.xdc]
link_design -mode default -reconfig_partitions { pfm_top_i/dynamic_region/ydma_1/page2_inst } -part $part -top pfm_top_wrapper

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

