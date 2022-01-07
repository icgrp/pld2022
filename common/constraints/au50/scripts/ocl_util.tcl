package require math::bignum
package require json

namespace eval ocl_util {
  namespace export write_cookie_file_impl report_utilization_impl \
                   report_timing_and_scale_freq  get_achievable_kernel_freq write_new_clk_freq \
                   write_user_impl_clock_constraint get_kernel_cells update_kernel_info \
                   fork_for_multistrategy close_multistrategy_fork

  proc get_script_dir {} [list return [file dirname [info script]]]

  proc dict_get_default {adict key default} {
    if { [dict exists $adict $key] } {
      return [dict get $adict $key]
    }
    return $default
  }

  proc is_empty { container } {
    if { [llength $container] == 0 } {
      return true
    }
    return false
  }

  # -----------------------------------------------------------------------------
  # error2file
  #
  # Logs the error and software persona message in two ways:
  # (1) on console for vivado.log (2) in steps log. Puts the software persona
  # message in a side file for post process append to v++ log.
  # Can be used with catch, however log_exception is preferred for that.
  #
  # Arguments:
  #   dir: A relative path to the directory that encapsulates vivado_error.txt
  #   sw_persona_msg: Software persona (non-hardware savvy) user message
  #   catch_res: The result of script evaluation, which here is expected to be
  #     an error message
  # -----------------------------------------------------------------------------
  proc error2file {dir sw_persona_msg {catch_res ""}} {
    global VPL_ERROR_LOGGED
    global steps_log
    global vivado_error_file
    if { $catch_res ne "" } {
      # The format is coupled with C++ code that does post-processing!
      puts "ERROR: caught error: $catch_res"
      steps_append $steps_log [list $catch_res]
      steps_append $steps_log [list $sw_persona_msg]
    } elseif {$sw_persona_msg ne ""} {
      # The format is coupled with C++ code that does post-processing!
      puts "ERROR: caught error: $sw_persona_msg"
      steps_append $steps_log [list $sw_persona_msg]
    }
    # remove the leading "<spaces>ERROR:<spaces>" from sw_persona_msg
    regsub -nocase {^\s*ERROR\s*:*\s*} $sw_persona_msg {} sw_persona_msg
    set fname [file join $dir $vivado_error_file]
    # puts "--- DEBUG: Writing to file $fname: $sw_persona_msg"
    set fh [open $fname w]
    puts $fh $sw_persona_msg
    close $fh
    # The procedure command behaves in its calling context as if it were the
    # command error result.
    # return ?-code code? ?-errorinfo info? ?-errorcode errorcode? ?value?
    return -code error -errorinfo $sw_persona_msg -errorcode $VPL_ERROR_LOGGED $sw_persona_msg
  }

  # ----------------------------------------------------------------------------
  # log_exception
  #
  # For use when using 'catch' to trap exceptional returns. The frame stack is
  # interesting compared to error2file.
  # Logs the exception, frame info, and software persona message in two ways:
  # (1) on console for vivado.log (2) in steps log. Puts the software persona
  # message in a side file for post process append to v++ log.
  #      
  # Arguments:
  #   dir: A relative path to the directory that encapsulates vivado_error.txt
  #   sw_persona_msg: A message targeted to non-hardware savvy user.
  #   catch_res: The result of script evaluation, which here is expected to be
  #     an error message
  #   return_options_dict: A dictionary of return options returned by
  #     evaluation of a script.
  # ----------------------------------------------------------------------------
  proc log_exception {dir sw_persona_msg {catch_res ""} return_options_dict} {
    global VPL_ERROR_LOGGED
    global steps_log
    global vivado_error_file
    if [dict exists $return_options_dict "-errorinfo"] {
      set msg_with_stack [dict get $return_options_dict "-errorinfo"]
      # The format is coupled with C++ code that does post-processing!
      puts "ERROR: caught error: $msg_with_stack"
      steps_append $steps_log [list $msg_with_stack]
    } elseif { $catch_res ne "" } {
      # The format is coupled with C++ code that does post-processing!
      puts "ERROR: caught error: $catch_res"
      steps_append $steps_log [list $catch_res]
    }
    if {$sw_persona_msg ne ""} {
      steps_append $steps_log [list $sw_persona_msg]
    }
    # remove the leading "<spaces>ERROR:<spaces>" from sw_persona_msg
    regsub -nocase {^\s*ERROR\s*:*\s*} $sw_persona_msg {} sw_persona_msg
    append sw_persona_msg " An error stack with function names and arguments may be available "
    append sw_persona_msg "in the 'vivado.log'."
    set fname [file join $dir $vivado_error_file]
    # puts "--- DEBUG: Writing to file $fname: $sw_persona_msg"
    set fh [open $fname w]
    puts $fh $sw_persona_msg
    close $fh
    # The procedure command behaves in its calling context as if it were the
    # command error result.
    # return ?-code code? ?-errorinfo info? ?-errorcode errorcode? ?value?
    return -code error -errorinfo $sw_persona_msg -errorcode $VPL_ERROR_LOGGED $sw_persona_msg
  }

  proc warning2file {dir msg } {
    global vivado_warn_file
    puts "$msg"
    # remove the leading "<spaces>WARNING:<spaces>" from msg
    regsub -nocase {^\s*(CRITICAL)?\s*WARNING\s*:\s*} $msg {} msg
    set fname [file join $dir $vivado_warn_file]
    # puts "--- DEBUG: Writing warnings to file $fname: $msg"
    # this file may have multiple warning messages, we should use "append" mode
    set fh [open $fname a+]
    puts $fh $msg
    close $fh
  }

  set System "system"
  set Kernel "kernel"

  # Initialize rule-checker functionality if the environment has been configured for it.
  set drcv_connected false
  if {[info exists ::env(XILINX_RS_PORT)]} {
    if { [catch {
      # Load library (shared/common/services/rulecheck/client/tcl), if necessary.
      # We'll search the list of loaded packages to see if it is already there
      # (instead of using package present which throws if it isn't).
      if {[lsearch -exact [package names] DRCVTcl] >= 0} {
        set result true
      } else {
        set result [load librdi_drcvtcl[info sharedlibextension]]
      }
      # Connect, if necessary
      if {$result eq "true"} {
        if { [catch {
          set result [::drcv::connect]
        } catch_res] } {
          # If we are already connected, the code currently gives TCL_ERROR,
          # which needs to be caught, but the throw will give "already connected"
          # and the result should be true. If this isn't what happened, stop.
          if {$catch_res ne "already connected"} {
            set result false
          }
        }
      }
      # Load rules
      if {$result eq "true"} {
        set this_script_dir [file dirname [file normalize [info script]]]
        set rule_path [file join $this_script_dir ocl_rules.cfg]
        if {[file exists $rule_path]} {
          set result [::drcv::load_rule_data_file $rule_path]
          set drcv_connected $result
        }
      }
    } catch_res return_options_dict] } {
      #TODO: This doesn't appear to work so early in the flow because
      # can't read "vivado_warn_file": no such variable
      #warning2file [pwd] "failed to connect to rulecheck server: $catch_res"
      puts "WARNING: failed to connect to rulecheck server - $catch_res"
      if [dict exists $return_options_dict "-errorinfo"] {
        set msg_with_stack [dict get $return_options_dict "-errorinfo"]
        puts "$msg_with_stack"
      }
    }
  }
  proc is_drcv {} {
    if { $ocl_util::drcv_connected } { return true }
    return false
  }

  if {[llength [array get env XILINX_CD_CONNECT_ID]] > 0} {
    set result "true"
    if {[catch {
      if {[lsearch -exact [package names] DispatchTcl] < 0} {
        set result [load librdi_cd_clienttcl[info sharedlibextension]] 
      }
      if {$result eq "false"} {
        puts "WARNING: Could not load dispatch client library"
      }
      set connect_id [ dispatch::init_client -mode EXISTING_SERVER ]
      if { $connect_id eq "" } {
        puts "WARNING: Could not initialize dispatch client"
      } else {
        puts "INFO: Dispatch client connection id - $connect_id"
      }
    } catch_res]} {
      puts "WARNING: failed to connect to dispatch server - $catch_res"
    }
  # - XILINX_CD_CONNECT_ID is set from v++
  # - If vpl.tcl is executed outside of v++ (e.g. debugging in vivado),
  #   we need to load the library here so that existing procs which call vitis_log:: still work.
  } else {
    if {[catch {
      if {[lsearch -exact [package names] DispatchTcl] < 0} {
        load librdi_cd_clienttcl[info sharedlibextension]
      }
    } catch_res]} {
      puts "WARNING: failed to connect to dispatch server - $catch_res"
    }
  }
  
  # Dummy proc "OPTRACE".  Needs to be created in case the real OPTRACE proc
  # isn't inserted
  if { [expr {[llength [info procs ::OPTRACE]] == 0}] } {
    proc ::OPTRACE {{arg1 \"\" } {arg2 \"\"} {arg3 \"\" } {arg4 \"\"} {arg5 \"\" } {arg6 \"\"}} {
        # Do nothing
    }
  }

  # In a multi-strategy run, if we are connected to dispatch, the following procs will execute a session fork so new
  # data for this parallel run will be maintained separate from the other parallel runs; and then close the session.

  proc fork_for_multistrategy {} {
    variable parent_dispatch_session
    variable fork_dispatch_session

    if {$::dispatch::connected && [info exists ::env(XILINX_CD_SESSION)]} {
      # Get the original session ID.
      set parent_dispatch_session $::env(XILINX_CD_SESSION)
      set dir [file tail [pwd]]
      set fork_dispatch_session [dispatch::fork_session $dir -session_id $parent_dispatch_session -description "Multistrategy run $dir"]
      # Make all Tcl dispatch calls go to this new session.
      dispatch::set_default_session $fork_dispatch_session
    }
  }

  proc close_multistrategy_fork {} {
    variable parent_dispatch_session
    variable fork_dispatch_session

    if {$::dispatch::connected && [info exists fork_dispatch_session]} {
      dispatch::stop_session -session_id $fork_dispatch_session
      dispatch::set_default_session $parent_dispatch_session"
    }
  }

  # TODO: originally used for non-unified paltform only, might be useful, keep it for now
  proc is_debug {} {
    set is_dbg false
    if { [info exists ::env(VITIS_DEBUG)] } {
      set is_dbg [expr bool($::env(VITIS_DEBUG))]
    }
    return $is_dbg
  }; # end is_debug
  
  #Added by Prasad for hw_emulation and required for the designs where we have AXIMM IO
  proc generate_sim_ipc_addressing {config_info} {
  
    set vpl_output_dir       [dict get $config_info vpl_output_dir]
    
    set sim_ipc_bd_cells [get_bd_cells -quiet -hierarchical -filter {VLNV=~"xilinx.com:ip:sim_ipc_aximm_master*"} ]
    set sim_ipc_addressing_properties ""
    
    foreach sim_ipc_master $sim_ipc_bd_cells {
    
      set masterSegments [get_bd_addr_segs -addressing -of [get_bd_intf_pins $sim_ipc_master/M_AXIMM]]
      
      foreach masterSegment $masterSegments {
        set ip_inst_name [get_property name $masterSegment]
        set sim_ipc_addressing [dict create]
        dict set sim_ipc_addressing "master_base_address" [json::string2json [get_property offset $masterSegment] ]
        dict set sim_ipc_addressing "range" [json::string2json [get_property range $masterSegment] ]
        dict set sim_ipc_addressing "path" [json::string2json [get_property path $masterSegment] ]
        dict set sim_ipc_addressing "name" [json::string2json [get_property name $masterSegment] ]
        
        lappend sim_ipc_addressing_properties [json::dict2json $sim_ipc_addressing]
      }
    }
    
    if { [llength $sim_ipc_addressing_properties] ne 0 } {
      dict set json_root "sim_ipc_address_info" [json::list2json $sim_ipc_addressing_properties]
      
      set sim_ipc_output_file $vpl_output_dir/sim_ipc_addressing.json
      puts "generate_sim_ipc_addressing: Writing the Json file $sim_ipc_output_file"
      set fp_json [open $sim_ipc_output_file "w"]
      set json_str [json::dict2json $json_root]
      
      regsub -all {(,\n\})} $json_str "\n\}" json_str_1
      regsub -all {\$} $json_str_1 "" json_fmt_str
      
      puts $fp_json $json_fmt_str
      close $fp_json
    }
  }

  # added by vamshi, TODO: add comments to explain why this is needed
  proc update_kernel_clocks { kernel_clock_freqs } {

    dict for {kernel_clk dict_clock} $kernel_clock_freqs {
      set kernel_clk_inst [string range $kernel_clk 0 [string last _ $kernel_clk]-1]
      set clk_freq [dict get $dict_clock freq]
      set is_user_set   [dict get $dict_clock is_user_set]

      if { [string equal -nocase $is_user_set "true" ] } {
        set clkFreqHZ [expr {int($clk_freq*1000000)}]
        set kernel_clk_inst_cell [get_bd_cells $kernel_clk_inst]
        if { $kernel_clk_inst_cell ne ""} {
          set_property -dict [list CONFIG.FREQ_HZ $clkFreqHZ] [get_bd_cells $kernel_clk_inst]
        } else {
          puts "Warning: Unable to update the Kernel Frequency. No BD cell matched $kernel_clk_inst"
        }
      }
    }
  }; # end update_kernel_clocks

  #Procedure to return kernel name for a given run
  proc get_kernel_name_from_run {kernel_run} {
    set cand_fs [get_property srcset $kernel_run]
    if {[get_property fileset_type $cand_fs] != "BlockSrcs"} {return}
    set cand_files [get_files -of_objects $cand_fs -norecurse]
    if {[llength $cand_files] != 1} {return}
    set cand_file [lindex $cand_files 0]
    if {[get_property FILE_TYPE $cand_file] != "IP"} {return}
    set cand_ip [get_ips -all [get_property IP_TOP $cand_file]]
    if {$cand_ip == {}} {return}
    set prop_val [get_property SDX_KERNEL $cand_ip]
    if {[get_property SDX_KERNEL $cand_ip] && [get_property SDX_KERNEL_TYPE $cand_ip] eq "hls"} {
      set fields [split [get_property IPDEF $cand_ip] ":"]
      lassign $fields vender slibrary ipname version
      return $ipname
    }
  }

  ################################################################################
  # log_generated_reports
  # utility function called by tcl proc run_synthesis and run_implementation
  #   Description: 
  #      
  #   Arguments:
  #      log_file
  #      runs 
  ################################################################################

  # Procedure for tracking report files
  proc log_generated_reports {log_file runs} {
    set failed [catch {
      set generated_reports_fh [open $log_file a]
      puts $generated_reports_fh [join [get_generated_reports $runs] "\n"]
      close $generated_reports_fh
    } _error]
    if { $failed } {
      puts "WARNING: Failed while trying to create a log with all generated reports, error: '${_error}'"
      puts "         The flow will continue, but generated reports may not be listed correctly."
    }
  }

  # Assemble the content of the generated reports log
  proc get_generated_reports {runs} {
    set log_content {}
    foreach run $runs {

      # If this is a multi-strategy run case, also write out the run CmdID.
      set run_cmd_id ""
      if { [array exists ocl_util::run_ids] && [info exists ocl_util::run_ids($run)] } {
        set run_cmd_id $ocl_util::run_ids($run)

        # And log the reports that we generated.
        set file_base [file join [get_property directory $run] kernel_service]
        lappend log_content "kernel_service|1.0|${run}_kernel_service|${file_base}.json||${run_cmd_id}"
        lappend log_content "kernel_service|1.0|${run}_kernel_service|${file_base}.pb||${run_cmd_id}"
        set file_name [file join [get_property directory $run] system_diagram.json]
        lappend log_content "system_diagram_plus|1.0|${run}_system_diagram|${file_name}||${run_cmd_id}"
      }

      set props [list_property $run STEPS.*.REPORTS]
      foreach prop $props {
        set run_step_reports [get_property $prop $run]
        foreach run_step_report $run_step_reports {
          set report_obj [get_report_configs $run_step_report]
          if { [llength $report_obj] > 0 } {        
            set output_file [get_property OUTPUT_FILE $report_obj]
            # rpx support
            # usually, OUTPUT_FILE for a particular report config is set to rpt file
            # if this report config supports rpx output file, there would be a property
            # named "OPTIONS.rpx", similarly, if this report config supports pb output 
            # file, there is "OPTIONS.pb"
            set output_rpx ""
            if {[lsearch [list_property $report_obj] "OPTIONS.rpx"] != -1} {
              set output_rpx [get_property OPTIONS.rpx $report_obj]
            }

            # NOTE: report_type has format of <report_command>:<version>
            # e.g. report_utilization:1.0
            set report_type [get_property REPORT_TYPE $report_obj]
            set report_type_list [split ${report_type} ":"]
            set report_command [lindex ${report_type_list} 0]
            set version [lindex ${report_type_list} 1]
            set report_name [get_property NAME $report_obj]
            set kernel_name [get_kernel_name_from_run $run]
            if { $output_file != "" } {
              set file_path [file join [get_property directory $run] $output_file]
              lappend log_content "${report_command}|${version}|${report_name}|${file_path}|${kernel_name}|${run_cmd_id}"
            }
            if { $output_rpx != "" } {
              set file_path [file join [get_property directory $run] $output_rpx]
              lappend log_content "${report_command}|${version}|${report_name}|${file_path}|${kernel_name}|${run_cmd_id}"
              # Do we have a Vitis concise file next to the .rpx?
              if {[regsub \.rpx$ $file_path \.rpv output_rpv] && [file exists $output_rpv]} {
                lappend log_content "${report_command}_concise|${version}|${report_name}|${output_rpv}|${kernel_name}|${run_cmd_id}"
              }
            }
          }
        }
      }
    }
    return $log_content
  }

  ################################################################################
  # add_module_references
  #   Description: add any module references to the project
  #      
  #   Arguments:
  #      hw_platform_info
  ################################################################################
  proc add_module_references { hw_platform_info config_info } {
    set top_module_name   [dict get $hw_platform_info top_module_name]
    set hw_platform_dir   [dict get $hw_platform_info hw_platform_dir]

    set modrefs_dir "$hw_platform_dir/bd/modrefs"
    if {[file isdirectory $modrefs_dir]} {
      # Import the HDL files (note the -norecurse to avoid ip files being picked up)
      import_files -norecurse $modrefs_dir

      # Import any modref IPs that are listed in ip_index.txt
      set ip_index [file join $modrefs_dir ip_index.txt]
      if {[file isfile $ip_index]} {
        set FH [open $ip_index]
        while { [gets $FH filename] >= 0 } {
          import_file [file join $modrefs_dir $filename]
        }
        close $FH
      }

      # Since modrefs were added, we must explicitly set top, since there are 
      # now multiple top level candidates to choose from
      set_property top $top_module_name [get_filesets sources_1]

      # We must also enable source_mgmt_mode to connect modrefs with the BD.
      set_property source_mgmt_mode All [current_project]
    }
  }

  ################################################################################
  # create_vivado_project
  # utility function called by create_project step
  #   Description: create the vivado project
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info 
  ################################################################################
  proc create_vivado_project {hw_platform_info config_info} {
    set hw_platform_state   [dict get $hw_platform_info hw_platform_state]
    set hw_platform_dr_bd   [dict get $hw_platform_info hw_platform_dr_bd]
    set hw_platform_part    [dict get $hw_platform_info hw_platform_part]
    set hw_platform_rebuild_tcl  [dict get $hw_platform_info hw_platform_rebuild_tcl] 
    set pre_sys_link_tcl    [dict get $hw_platform_info pre_sys_link_tcl] 

    set project_name        [dict get $config_info proj_name]
    set is_hw_emu           [dict get $config_info is_hw_emu]
    set steps_log           [dict get $config_info steps_log]
    # set output_dir          [dict get $config_info output_dir]
    set vivado_output_dir   [dict get $config_info vivado_output_dir]

    steps_append $steps_log [frame2log "create_vivado_project" [info frame -1] [info frame 0]]

    # NOTES: The location where pre_sys_link should be sourced has a long history
    # 1.source the pre_sys_link_tcl before sourcing the rebuild.tcl (soc platform case)
    # 2.pre_sys_link_tcl must be sourced before importing bd (pcie platform case)
    # 3.http://jira.xilinx.com/browse/CR-1009391
    # Ben: The error occurs during generation, but the root problem occurs if that parameter has not been set 
    # before the IP catalog is loaded. Anything that triggers interaction with IP will cause a catalog load.  
    # 4.Susheel: We assume that pre_sys_link_tcl will not be written assuming a project is open
    # Currently, it is only allowed to set envars and params. 
    # This Tcl is more like an init.tcl that is exercised even before creating a project
    source_pre_create_project_tcl $hw_platform_info $config_info

    OPTRACE "Create project" START

    if { [string equal $hw_platform_state "pre_synth"] } {
      # pre_synth platform 
      #   soc platform (usesPR = false)  
      #     hw flow    : source rebuild.tcl to populate vivado project (including importing dr bd)
      #     hw_emu flow: source rebuild.tcl to populate vivado project
      #   pcie platform (i.e. kyle's usecase) (usesPR = true)
      #     hw flow    : source rebuild.tcl to populate vivado project
      #     hw_emu flow: create vivado project
      # note: example of running hw_emu flow for soc platform, /proj/testcases/fisusr/sdaccel/sdx_canary_HEAD/sdsoc/cosim_hello_vadd_ocl_102/
      # note: hw_platform_dr_bd is empty for soc platform 
      if { $is_hw_emu && $hw_platform_dr_bd ne "" && [file exists $hw_platform_dr_bd] } {
        # pcie platform + hw_emu flow 
        add_to_steps_log $steps_log "internal step: create_project -part $hw_platform_part -force $project_name $project_name" [fileName]:[lineNumber [info frame]]
        create_project -part $hw_platform_part -force $project_name $project_name
      } else {
        # The purpose for using a rebuild.tcl flow is to guarantee a match with the behavior of
        # open_hw_platform.

        # soc platform + hw/hw_emu flow; pcie_platform + hw flow
        # board repo path is set before sourcing rebuild.tcl via a param in _vivado_parmas.tcl
        set hw_platform_prj_dir [file dirname $hw_platform_rebuild_tcl]
        set ::origin_dir_loc $hw_platform_prj_dir
        puts "INFO: \[OCL_UTIL\] set ::origin_dir_loc $hw_platform_prj_dir"
        set ::user_project_name $project_name
        puts "INFO: \[OCL_UTIL\] set ::user_project_name $project_name"
 
        add_to_steps_log $steps_log "internal step: source $hw_platform_rebuild_tcl to create $project_name project" [fileName]:[lineNumber [info frame]]
        if { [catch {source $hw_platform_rebuild_tcl} result return_options_dict] } {
          # Return code is not zero, so result is an error message
          set sw_persona_msg "Failed to rebuild a project required for hardware synthesis. "
          append sw_persona_msg "The project is '$project_name'. The rebuild script is "
          append sw_persona_msg "'$hw_platform_rebuild_tcl'. The rebuild script was delivered as "
          append sw_persona_msg "part of the hardware platform. Consult with the hardware platform "
          append sw_persona_msg "provider to investigate the rebuild script contents."
          OPTRACE "Create project" END
          log_exception $vivado_output_dir $sw_persona_msg $result $return_options_dict
        }
      }
    } elseif { [string equal $hw_platform_state "synth"] } {
      # synth platform
      #   hw_emu flow: create vivado project 
      #   hw flow    : create and configure a hybrid GateLvl (GateLvlSubDesign) project and add synth_bb dcp
      if { $is_hw_emu } {
        # hw_emu flow, create the vivado project 
        add_to_steps_log $steps_log "internal step: create_project -part $hw_platform_part -force $project_name $project_name" [fileName]:[lineNumber [info frame]]
        create_project -part $hw_platform_part -force $project_name $project_name
        add_module_references $hw_platform_info $config_info
      } else {
        # hw flow, create vivado project, set design_mode to GateLvlSubDesign and add synth_bb dcp
        create_project_for_synth_platform $hw_platform_info $config_info
      }
    } else {
      # impl platform (pcie only at least for 2019.1)
      #   hw_emu flow: create vivado project 
      #   hw flow    : create vivado project, create reconfigurable module and pr configuration
      if { $is_hw_emu } {
        # hw_emu flow, create the vivado project 
        add_to_steps_log $steps_log "internal step: create_project -part $hw_platform_part -force $project_name $project_name" [fileName]:[lineNumber [info frame]]
        create_project -part $hw_platform_part -force $project_name $project_name
        add_module_references $hw_platform_info $config_info
      } else {
        # hw flow, create the vivado porject, add the bb_locked dcp to the design, 
        #          create partition def and reconfig module for pcie platform
        create_project_and_init_rm_pcie $hw_platform_info $config_info
      }
    }
    set_property tool_flow SDx [current_project]

    OPTRACE "Create project" END
  }

  ################################################################################
  #   create_system_diagram_metadata
  #
  #   Description: Updates an existing system diagram with kernel use data.
  #      
  #   Arguments:
  #     run_step   - The run step being examined: synthed, placed, or routed.
  #     output_dir - The output directory (where the utilization json files can be found)
  ################################################################################
  proc create_system_diagram_metadata { run_step output_dir } {
    # -- Predetermined files
    set kernel_util_synthed_file [ file normalize "kernel_util_synthed.json" ]
    set kernel_util_placed_file [ file normalize "kernel_util_placed.json" ]
    set kernel_util_routed_file [ file normalize "kernel_util_routed.json" ]
    set valid_run_step 0

    set kernel_usage_file_names [list]
    
    puts "INFO: System Diagram: Run step: $run_step"

    # -- Remove any files that shouldn't be part of a given run step
    if { [expr {$run_step eq "synthed"}] } {
      set kernel_util_placed_file ""
      set kernel_util_routed_file ""
      set valid_run_step 1
    }

    if { [expr {$run_step eq "placed"}] } {
      set kernel_util_routed_file ""
      set valid_run_step 1
    }

    if { [expr {$run_step eq "routed"}] } {
      set valid_run_step 1
    }

    if { $valid_run_step == 0} {
      puts "CRITICAL WARNING: System Diagram: Run step '${run_step}' not supported for kernel use data. Skipping operation."
      return
    }

    # kernel_util_synthed.json
    if { [expr {$kernel_util_synthed_file ne ""}] } {
      if { [file exists $kernel_util_synthed_file] == 1} {  
        lappend kernel_usage_file_names "${kernel_util_synthed_file}"
      }
    }

    # kernel_util_placed_file.json
    if {[expr {$kernel_util_placed_file ne ""}] } {
      if { [file exists $kernel_util_placed_file] == 1} {  
        lappend kernel_usage_file_names "${kernel_util_placed_file}"
      }
    }

    # kernel_util_routed_file.json
    if {[expr {$kernel_util_routed_file ne ""}] } {
      if { [file exists $kernel_util_routed_file] == 1} {  
        lappend kernel_usage_file_names "${kernel_util_routed_file}"
      }
    }
    
    if { [llength $kernel_usage_file_names] == 0 } {
      puts "CRITICAL WARNING: System Diagram: No kernel utilization data found. Skipping production of merged system diagram."
      return
    }

    # puts "calling update_with_kernel_usage: $kernel_usage_file_names"
    # read the json files and add the "actual_resouces" info to dispatch server
    if { [ catch { ::system_diagram::update_with_kernel_usage $kernel_usage_file_names } results ] } {
      puts "CRITICAL WARNING: System Diagram: $results"
      return
    }

    # If we are done with routing, write out a diagram to the local directory.
    # This will be used for multi-strategy runs, and could otherwise be useful.
    if { $run_step eq "routed" } {
      set output_path [ file normalize "system_diagram.json" ]
      if { [ catch { ::system_diagram::write_current_system_diagram $output_path SYSTEM_DIAGRAM_PLUS } results ] } {
        puts "CRITICAL WARNING: System Diagram: $results"
        return
      }
    }

    # Print out the output results from executing merge_kernel_utilization
    puts ${results}
  }


  ################################################################################
  # Expected to be used by VPL script generator
  #
  ################################################################################
  proc source_pre_create_project_tcl {hw_platform_info config_info} {
    set pre_sys_link_tcl    [dict get $hw_platform_info pre_sys_link_tcl]  
    set steps_log           [dict get $config_info steps_log] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set project_name        [dict get $config_info proj_name]
    set hook_name           "pre_sys_link"

    # If platform has pre_create_project_tcl, use it instead of legacy pre_sys_link_tcl
    set pre_create_project_tcl [dict get $hw_platform_info pre_create_project_tcl]
    if {![string equal $pre_create_project_tcl ""]} {
      set pre_sys_link_tcl $pre_create_project_tcl
      set hook_name "pre_create_project"
    }

    if { ![string equal $pre_sys_link_tcl ""] && [file exists $pre_sys_link_tcl] } {
      # code refactoring
      # OPTRACE "Source $hook_name Tcl script" START
      # global env
      # add_to_steps_log $steps_log "internal step: source $pre_sys_link_tcl" [fileName]:[lineNumber [info frame]]
      # if { [catch {source $pre_sys_link_tcl} result return_options_dict] } {
      #   set sw_persona_msg "Failed to configure a project required for hardware synthesis. "
      #   append sw_persona_msg "The project is '$project_name'. The configuration script is "
      #   append sw_persona_msg "'$pre_sys_link_tcl'. The configuration script was delivered as "
      #   append sw_persona_msg "part of the hardware platform."
      #   OPTRACE "Source $hook_name Tcl script" END
      #   log_exception $vivado_output_dir $sw_persona_msg $result $return_options_dict
      # }
      # OPTRACE "Source $hook_name Tcl script" END
      global env
      set optrace_task "Source $hook_name Tcl script"
      set sw_persona_msg "Failed to configure a project required for hardware synthesis. \
                          The project is '$project_name'. The configuration script is '$pre_sys_link_tcl'. \
                          The configuration script was delivered as part of the hardware platform."
      run_cmd "source $pre_sys_link_tcl"
    }
    
    # this is to source user sepcified pre_create_project Tcl using param compiler.userPreCreateProjectTcl
    set user_pre_create_project_tcl [dict get $hw_platform_info user_pre_create_project_tcl]
    set hook_name "pre_create_project"
    if { ![string equal $user_pre_create_project_tcl ""] && [file exists $user_pre_create_project_tcl] } {
      # OPTRACE "Source user $hook_name Tcl script" START
      # global env
      # add_to_steps_log $steps_log "internal step: source $user_pre_create_project_tcl" [fileName]:[lineNumber [info frame]]
      # if { [catch {source $user_pre_create_project_tcl} result return_options_dict] } {
      #   set sw_persona_msg "Failed to configure a project required for hardware synthesis. "
      #   append sw_persona_msg "The project is '$project_name'. The configuration script is "
      #   append sw_persona_msg "'$user_pre_create_project_tcl'. The configuration script was "
      #   append sw_persona_msg "set using param 'compiler.userPreCreateProjectTcl'."
      #   OPTRACE "Source $hook_name Tcl script" END
      #   log_exception $vivado_output_dir $sw_persona_msg $result $return_options_dict
      # }
      # OPTRACE "Source $hook_name Tcl script" END
      set optrace_task "Source user $hook_name Tcl script"
      set sw_persona_msg "Failed to configure a project required for hardware synthesis. \
                          The project is '$project_name'. The configuration script is '$user_pre_create_project_tcl'. \
                          The configuration script was set using param 'compiler.userPreCreateProjectTcl'."
      run_cmd "source $user_pre_create_project_tcl"
    }
  }

  ################################################################################
  # create_project_for_synth_platform
  # utility function called by tcl proc create_vivado_project
  #   Description: Directly creates and configures a hybrid GateLvl project 
  #                and adds the top synth_bb dcp. The project has no DFX.
  # 
  #   Assumptions:
  #   - The hardware platform state is 'synth'
  #   - build target is 'hw'
  #   - no shell dcp support
  #
  #   Arguments:
  #      hw_platform_info
  #      config_info 
  ################################################################################
  proc create_project_for_synth_platform {hw_platform_info config_info} {
    set hw_platform_part    [dict get $hw_platform_info hw_platform_part]
    set bb_synth_dcp        [dict get $hw_platform_info bb_synth_dcp]
    set project_name        [dict get $config_info proj_name]
    set steps_log           [dict get $config_info steps_log]
    set design_mode         GateLvlSubdesign

    # -- Create the project --
    add_to_steps_log $steps_log "internal step: create_project -part $hw_platform_part -force $project_name $project_name" [fileName]:[lineNumber [info frame]]
    create_project -part $hw_platform_part -force $project_name $project_name
    add_module_references $hw_platform_info $config_info

    puts "INFO: \[OCL_UTIL\] set_property design_mode $design_mode \[current_fileset\]"
    set_property design_mode $design_mode [current_fileset]

    # Memory initialization isn't supported, disable BMM/MMI creation to speed up the flow
    set_property mem.enable_memory_map_generation 0 [current_project]

    # bb_synth_dcp dcp should always be there for unified platforms of state "synth"
    if { $bb_synth_dcp ne ""} {
      add_to_steps_log $steps_log "internal step: add_files $bb_synth_dcp" [fileName]:[lineNumber [info frame]]
      add_files $bb_synth_dcp
    }
  }

  ################################################################################
  # create_project_and_init_rm_pcie
  # utility function called by tcl proc create_vivado_project
  #   Description: Directly creates and configures a project with a reconfigurable
  #     module; this tcl proc is used for pcie platform and hw flow only
  # 
  #   Assumptions:
  #   - The hardware platform state is 'impl' (supports implementation)
  #   - build target is 'hw'
  #
  #   Arguments:
  #      hw_platform_info
  #      config_info 
  ################################################################################
  proc create_project_and_init_rm_pcie {hw_platform_info config_info} {
    set hw_platform_dr_bd   [dict get $hw_platform_info hw_platform_dr_bd] 
    set hw_platform_part    [dict get $hw_platform_info hw_platform_part]
    set bb_locked_dcp       [dict get $hw_platform_info bb_locked_dcp]
    set uses_pr_shell_dcp   [dict get $hw_platform_info uses_pr_shell_dcp]
    set link_output_format  [dict get $hw_platform_info link_output_format]
    set pr_shell_dcp        [dict get $hw_platform_info pr_shell_dcp]
    set ocl_inst_path       [dict get $hw_platform_info ocl_region]

    set project_name        [dict get $config_info proj_name] 
    set steps_log           [dict get $config_info steps_log] 
    set partition_def       [dict get $config_info partition_def]
    set reconfig_module     [dict get $config_info reconfig_module]
    set pr_config_name      [dict get $config_info pr_config_name]
    set vivado_output_dir   [dict get $config_info vivado_output_dir]

    # -- Create the project --
    add_to_steps_log $steps_log "internal step: create_project -part $hw_platform_part -force $project_name $project_name" [fileName]:[lineNumber [info frame]]
    create_project -part $hw_platform_part -force $project_name $project_name

    puts "INFO: \[OCL_UTIL\] set_property design_mode GateLvl \[current_fileset\]"
    set_property design_mode GateLvl [current_fileset]
    add_module_references $hw_platform_info $config_info
    puts "INFO: \[OCL_UTIL\] set_property PR_FLOW 1 \[current_project\]"
    if { [catch {set_property PR_FLOW 1 [current_project]} catch_res return_options_dict] } {
      add_to_steps_log $steps_log "status: fail" [fileName]:[lineNumber [info frame]] 
      set sw_persona_msg "Failed to configure a project required for hardware synthesis. "
      append sw_persona_msg "The project is '$project_name'. Exception when setting project properties "
      append sw_persona_msg "for dynamic function exchange. Consult with the hardware platform provider "
      append sw_persona_msg "to investigate the platform state."
      OPTRACE "Create project" END
      log_exception $vivado_output_dir $sw_persona_msg $catch_res $return_options_dict
    }

    # Memory initialization isn't support, speed up flow by disabling creation
    # of the BMM / MMI file.
    set_property mem.enable_memory_map_generation 0 [current_project]

    # support bb_locked dcp (enhanced link_design pr flow)
    # bb_locked dcp should always be there for unified platforms since 2018.1
    # abstract shell dcp in 2018.2 only supports FaaS
    # if AcceleratorBinaryContent is set to "bitstream" or "pdi", we should use bb_locked dcp
    # if AcceleratorBinaryContent is set to "dcp", abstract shell dcp should take precedence
    # necessary error check has already been done in frontend, we can only consider the valid usecase here
    if { $bb_locked_dcp ne "" || $uses_pr_shell_dcp} {
      # if { [string equal $link_output_format "bitstream"] || [string equal $link_output_format "pdi"] } 
      if { [has_output_format $link_output_format "bitstream"] || [has_output_format $link_output_format "pdi"] } {
        set hw_platform_dcp $bb_locked_dcp
      } else {
        set hw_platform_dcp [expr { $uses_pr_shell_dcp ? $pr_shell_dcp : $bb_locked_dcp} ] 
      }

      add_to_steps_log $steps_log "internal step: add_files $hw_platform_dcp" [fileName]:[lineNumber [info frame]]
      add_files $hw_platform_dcp

      # -- Create the partion and rm that will contain the bd
      # use dr_bd base name as the dr top
      set dr_top [file rootname [file tail $hw_platform_dr_bd]]
      add_to_steps_log $steps_log "internal step: create_partition_def -name $partition_def -module $dr_top" [fileName]:[lineNumber [info frame]]
      create_partition_def -name $partition_def -module $dr_top
      add_to_steps_log $steps_log "internal step: create_reconfig_module -name $reconfig_module -partition_def \[get_partition_defs $partition_def \] -top $dr_top" [fileName]:[lineNumber [info frame]]
      create_reconfig_module -name $reconfig_module -partition_def [get_partition_defs $partition_def ] -top $dr_top

      puts "INFO: \[OCL_UTIL\] set_property use_blackbox_stub false \[get_filesets $reconfig_module -of_objects \[get_reconfig_modules $reconfig_module\]\]"
      set_property use_blackbox_stub false [get_filesets $reconfig_module -of_objects [get_reconfig_modules $reconfig_module]]
      puts "INFO: \[OCL_UTIL\] set_property USE_BLACKBOX_STUB 0 \[get_partition_defs $partition_def\]"
      set_property USE_BLACKBOX_STUB 0 [get_partition_defs $partition_def]

      # create pr configuration and set properties on it
      # -- Create the PR configuration alone with data on where the BD will go --
      # set config_name "config_1"
      add_to_steps_log $steps_log "internal step: create_pr_configuration -name $pr_config_name -partitions \[list $ocl_inst_path:$reconfig_module\]" [fileName]:[lineNumber [info frame]]
      create_pr_configuration -name $pr_config_name -partitions [list $ocl_inst_path:$reconfig_module]
      # disable the generation of the cell level checkpoints for RMs during post bitstream 
      set_property AUTO_IMPORT 0 [get_pr_configuration $pr_config_name]
      # disable the generation of wrapper black box checkpoint during post bitstream
      set_property USE_BLACKBOX 0 [get_pr_configuration $pr_config_name]

    # TODO: SmartXplore (multiple impl runs)
    # should be moved to config_hw_runs step where we can set configurations to all the impl runs
      # puts "INFO: \[OCL_UTIL\] set_property PR_CONFIGURATION $pr_config_name \[get_runs impl_1\]"
      # set_property PR_CONFIGURATION $pr_config_name [get_runs impl_1]
    }
  }

  ################################################################################
  # apply_constrs_for_impl
  # utility function called by generate_target step
  #   Description: add _post_sys_link_gen_constrs.xdc which is generated by sourcing post_sys_link_tcl 
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info 
  ################################################################################
  proc apply_constrs_for_impl {hw_platform_info config_info} {
    set impl_xdc               [dict get $hw_platform_info impl_xdc] 

    set steps_log              [dict get $config_info steps_log] 
    set vivado_output_dir      [dict get $config_info vivado_output_dir] 
    set enable_dont_partition  [dict get $config_info enable_dont_partition]

    # impl_constrs support
    add_xdc_files $impl_xdc $steps_log
  
    # read the _post_sys_link_gen_constrs.xdc generated by sourcing post_sys_link_tcl
    set post_sys_link_gen_xdc "_post_sys_link_gen_constrs.xdc"
    if { [file exists $post_sys_link_gen_xdc] } {
      add_to_steps_log $steps_log "internal step: add_files $post_sys_link_gen_xdc" [fileName]:[lineNumber [info frame]]
      add_files $post_sys_link_gen_xdc
    }
  
    # write dont_partition.xdc file and read_xdc
    # when executed in the non-design environment, read_xdc is same as add_files
    apply_dont_partition $enable_dont_partition $steps_log $vivado_output_dir

  }

  proc check_single_impl_run_status {hw_platform_info config_info clk_info} {
    set steps_log           [dict get $config_info steps_log] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set strategies_impl     [dict get $config_info strategies_impl] 
    set wns_threshold       [dict get $clk_info worst_negative_slack]

    # note: this may return a useless run for usesPR platform, e.g. my_rm_impl_1
    set impl_runs [get_runs -filter {IS_IMPLEMENTATION == 1} ]

    # capture impl reports
    set generated_reports_log [file join $vivado_output_dir "generated_reports.log"]
    add_to_steps_log $steps_log "internal step: log_generated_reports for implementation '${generated_reports_log}'" [fileName]:[lineNumber [info frame]]
    log_generated_reports $generated_reports_log $impl_runs

    # check impl run status
    # we are only interested in the default impl run - impl_1
    set run_status [get_property STATUS [get_runs impl_1]]
    if { [string match "*ERROR" $run_status] } {
      set run_dir [get_property DIRECTORY [get_runs impl_1]]
      add_to_steps_log $steps_log "internal step: problem implementing dynamic region, impl_1: $run_status" [fileName]:[lineNumber [info frame]]
      add_to_steps_log $steps_log "status: fail ($run_status)" [fileName]:[lineNumber [info frame]]
      add_to_steps_log $steps_log "log: $run_dir/runme.log" [fileName]:[lineNumber [info frame]]
      error2file $vivado_output_dir "problem implementing dynamic region, impl_1: $run_status, please\
                                       look at the run log file '$run_dir/runme.log' for more information" 
    } 
    set best_run "impl_1"

    return $best_run
  }

  ################################################################################
  # check_impl_run_status
  # utility function called by impl step
  #   Description: log generated implementation report files, check the implementation
  #                run status
  #                called by wait_on_all_runs_(), used only for multi-strategies usecase
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info
  ################################################################################
  proc check_impl_run_status {hw_platform_info config_info clk_info} {
    set steps_log           [dict get $config_info steps_log] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set strategies_impl     [dict get $config_info strategies_impl] 
    set wns_threshold       [dict get $clk_info worst_negative_slack]
    set error_hold_vio      [dict get $clk_info error_on_hold_violation]

    set ignore_hold_vio     [expr ! $error_hold_vio]

    # SmartXplore (multiple impl runs)
    # note: this may return a useless run for usesPR platform, e.g. my_rm_impl_1
    # TODO
    set impl_runs [get_runs -filter {IS_IMPLEMENTATION == 1} ]

    # capture impl reports
    set generated_reports_log [file join $vivado_output_dir "generated_reports.log"]
    add_to_steps_log $steps_log "internal step: log_generated_reports for implementation '${generated_reports_log}'" [fileName]:[lineNumber [info frame]]
    log_generated_reports $generated_reports_log $impl_runs

    # check impl run status
    set best_run ""
    set enable_multi_strategies [expr {$strategies_impl ne ""}]
    if {$enable_multi_strategies} {
      # in SmartXplore, we need to find a qualified implementation run
      # in which all three WNS/WHS/TPWS numbers are >=0
      report_wns_stats $impl_runs $wns_threshold $ignore_hold_vio $steps_log best_run
      if {$best_run eq ""} {
        add_to_steps_log $steps_log "internal step: problem finding a qualified implementation run" [fileName]:[lineNumber [info frame]]
        add_to_steps_log $steps_log "status: fail (timing failure)" [fileName]:[lineNumber [info frame]]
        error2file $vivado_output_dir "problem finding a qualified implemenation run in Multi-Strategies mode, none of the\
                                       implementation runs can meet timing, please look at the run log file (runme.log)\
                                       under each implementation run directory for more information" 
      }

    } else {
      # TODO: remove the section below since this tcl proc is used for multi-strategies usecase only
      # we are only interested in the default impl run - impl_1
      set run_status [get_property STATUS [get_runs impl_1]]
      if { [string match "*ERROR" $run_status] } {
        set run_dir [get_property DIRECTORY [get_runs impl_1]]
        add_to_steps_log $steps_log "internal step: problem implementing dynamic region, impl_1: $run_status" [fileName]:[lineNumber [info frame]]
        add_to_steps_log $steps_log "status: fail ($run_status)" [fileName]:[lineNumber [info frame]]
        add_to_steps_log $steps_log "log: $run_dir/runme.log" [fileName]:[lineNumber [info frame]]
        error2file $vivado_output_dir "problem implementing dynamic region, impl_1: $run_status, please\
                                       look at the run log file '$run_dir/runme.log' for more information" 
      } 
      set best_run "impl_1"
    }

    return $best_run
  }

  ################################################################################
  # update_kernel_info
  # utility function called by impl step, part of post_route tcl hook
  #   Description: Looks for kernels in the design and updates data in the
  #                kernel service, so that other code can perform checks, etc.
  #      
  #   Arguments:
  #      hw_platform_info (probably not needed)
  #      config_info
  ################################################################################
  proc update_kernel_info {steps_log output_dir ocl_inst_path} {
    variable parent_dispatch_session
    variable fork_dispatch_session

    set cu_roots [get_kernel_cells $ocl_inst_path]
    foreach cu_root $cu_roots {

      set parent [get_property PARENT $cu_root]
      set pos [string last "/" $parent]
      if {$pos == -1} { 
         puts "CRITICAL WARNING: Failed to determine compute unit name for cell $cu_root"
         continue
      }
      set name [string range $parent [expr $pos+1] end]
      set inst_path [get_property NAME $cu_root]

      #current_instance $cu_root
      #llength [get_cells -hier -filter "NAME =~ $inst_path/* && STATUS==PLACED"]

      set cu_cells [get_cells -hier -filter "NAME =~ $inst_path/* && STATUS==PLACED"]
      set slrs [lsort -unique [get_property SLR_INDEX $cu_cells]]

      # Update the compute unit in the kernel service
      if { [ catch { ::kernel_service::upsert_compute_unit $name -instance $inst_path -slr $slrs } results ] } {
        puts "CRITICAL WARNING: Kernel service failed to update compute unit for $cu_root: $results"
      }

      # For now, vitis_analyzer is interested in tiles, not locations, but the following
      # code could be used for those:
      #set locs_prop [lsort -unique [get_property LOC $cu_cells]]
      #set locs_objs [get_sites -of_objects $cu_cells]

      set tiles [get_tiles -of_objects [get_sites -of_objects $cu_cells]]
      set unique_tiles [lsort -unique $tiles]
      # Get the X-Y coordinates for all of the tiles, and consolidate.
      # We will make an array, indexed by x, with a list of y's
      set coords [dict create]
      foreach tile $unique_tiles {
        set x [get_property TILE_X $tile]
        set y [get_property TILE_Y $tile]
        dict lappend coords $x $y
      }
      # Sort and uniqueify. The dict insures the X values are unique, but they aren't sorted.
      # The Y values appear to be sorted and unique (as a result of the tile sorting?) but just
      # in case, we'll sort those as well.
      set sorted_coords [dict create]
      foreach x [lsort -dictionary [dict keys $coords]] {
        dict set sorted_coords $x [lsort -dictionary -unique [dict get $coords $x]]
      }
      if { [ catch { ::kernel_service::upsert_cu_tile_dict $name $sorted_coords } results ] } {
        puts "CRITICAL WARNING: Kernel service failed to update compute unit tile information for $cu_root: $results"
      }
    }

    # Also add some platform information so the consumers of the compute unit
    # information have some context. We want to get the overall tile dimenions,
    # SLR regions (as rectangles), and the platform static region (also rectangles).
    set part [get_parts -of_objects [current_project]]
    # We compute the overall dimensions as the bounding box of the SLRs, so here's
    # a store for them, before we iterate over the SLRs.
    set num_cols 0
    set num_rows 0
    foreach slr [get_slrs] {
      set slr_name [get_property name $slr]
      set x1 [get_property LOWER_RIGHT_X $slr]
      set y1 [get_property LOWER_RIGHT_Y $slr]
      set x2 [get_property UPPER_LEFT_X $slr]
      set y2 [get_property UPPER_LEFT_Y $slr]
      if { [ catch { ::kernel_service::upsert_platform -slr_tiles [list $slr_name $x1 $y1 $x2 $y2] } results ] } {
        puts "CRITICAL WARNING: Kernel service failed to update platform SLR information: $results"
      }    
      if {$x2 > $num_cols} { set num_cols $x2 }
      if {$y2 > $num_rows} { set num_rows $y2 }
    }
    if { [ catch { ::kernel_service::upsert_platform -part $part -tile_size [list $num_cols $num_rows] } results ] } {
      puts "CRITICAL WARNING: Kernel service failed to update platform information: $results"
    }

    # Now let's get the platform static region. We don't know what really is the static region,
    # and there isn't a standard naming convention. But we may know what the dynamic region is,
    # based on ocl_inst_path. So the static = design - dynamic.
    if { $ocl_inst_path ne "" } {
      # Construct the filter
      set filter "NAME != $ocl_inst_path && NAME !~ $ocl_inst_path/*"
      set static_cells [get_cells -hierarchical -filter $filter]
      set static_pblocks [get_pblocks -of_objects $static_cells]
      foreach pblock $static_pblocks {
        # If this is a child block and the parent is in the list, skip it because
        # the parent will report all the rectangles of children, possibly merging them.
        set parent [get_property PARENT $pblock]
        if {[lsearch -exact $static_pblocks $parent] >= 0} {
          continue
        }
        # We presume that disparate pblocks won't have duplicate rectangles,
        # so just send the data that we have now.
        set rects [get_property RECTANGLE_TILES $pblock]
        foreach rect $rects {
          if { [ catch { ::kernel_service::upsert_platform -static_rect $rect } results ] } {
            puts "CRITICAL WARNING: Kernel service failed to update platform static information: $results"
          }
        }
      }
    }

    # Get the rest of the dynamic region that doesn't include the compute units.
    # A faster way to do this is to use
    # highlight_objects -leaf_cells [get_cells pfm_top_i/dynamic_region]
    # unhighlight_objects -leaf_cells $cu_roots
    # But this doesn't work without the GUI up. But it suggests there might be
    # a better way than the following.
    # First construct the filter.
    set filter "STATUS==PLACED"
    if { $ocl_inst_path ne "" } {
      append filter " && NAME =~ $ocl_inst_path/*"
    }
    foreach cu_root $cu_roots {
      append filter " && NAME !~ $cu_root/*"
    }
    # Get the cells and tiles based on the filter.
    set dyn_cells [get_cells -hier -filter $filter]
    set tiles [get_tiles -of_objects [get_sites -of_objects $dyn_cells]]
    set unique_tiles [lsort -unique $tiles]
    # Get the X-Y coordinates for all of the tiles, and consolidate.
    # We will make an array, indexed by x, with a list of y's
    set coords [dict create]
    foreach tile $unique_tiles {
      set x [get_property TILE_X $tile]
      set y [get_property TILE_Y $tile]
      dict lappend coords $x $y
    }
    # Sort and uniqueify. The dict insures the X values are unique, but they aren't sorted.
    # The Y values appear to be sorted and unique (as a result of the tile sorting?) but just
    # in case, we'll sort those as well.
    set sorted_coords [dict create]
    foreach x [lsort -dictionary [dict keys $coords]] {
      dict set sorted_coords $x [lsort -dictionary -unique [dict get $coords $x]]
    }
    if { [ catch { ::kernel_service::upsert_platform -dynamic_placement_dict $sorted_coords } results ] } {
      puts "CRITICAL WARNING: Kernel service failed to update platform dynamic information: $results"
    }

    # Write out a snapshot of the kernel service information to vpl output dir
    set ks_json $output_dir/kernel_service.json
    if { [ catch { ::kernel_service::write_data $ks_json } results ] } {
      puts "CRITICAL WARNING: Kernel service failed to write file $ks_json: $results"
    } else {
      vitis_log::report $ks_json -file_type JSON -report_type KERNEL_SERVICE
    }
    set ks_protobuf $output_dir/kernel_service.pb
    if { [ catch { ::kernel_service::write_data $ks_protobuf -format BINARY_PROTOBUF } results ] } {
      puts "CRITICAL WARNING: Kernel service failed to write file $ks_protobuf: $results"
    } else {
      vitis_log::report $ks_protobuf -file_type BINARY_PROTOBUF -report_type KERNEL_SERVICE
    }
  }

  proc wait_on_all_runs_ {impl_runs hw_platform_info config_info clk_info} {
    set steps_log           [dict get $config_info steps_log] 

    # old wait on run behavior - wait on completion of all impl runs 
    # this tcl proc is used when param compioler.multiStrategiesWaitOnAllRuns is set to true (regardless lsf or not)
    foreach run $impl_runs {
      if { [catch {
        # use vivado built-in wait_on_run
        # puts "dbg: wait_on_run $run"
        wait_on_run $run
      } catch_result return_options_dict] } {
        set run_dir [get_property DIRECTORY $run]
        ocl_util::add_to_steps_log $steps_log "status: fail" [ocl_util::extFileName]:[expr {[dict get [info frame -1] line] + [dict get [info frame 0] line]}] 
        ocl_util::add_to_steps_log $steps_log "log: $run_dir/runme.log" [ocl_util::extFileName]:[expr {[dict get [info frame -1] line] + [dict get [info frame 0] line]}]
        # TODO
        # set sw_persona_msg "Failed to complete hardware generation. The run name is 'impl_1'."
        # ocl_util::log_exception $output_dir $sw_persona_msg $catch_result $return_options_dict
      }
    }
    set best_run [ocl_util::check_impl_run_status $hw_platform_info $config_info $clk_info]
    return $best_run
  }

  # rely on the disptach server, tasklog service, and optrace messages
  # this is more reliable than wait_on_first_run_lsf_, but currently (in 2020.1)
  # it doesn't support lsf
  proc wait_on_first_run_local_ {impl_runs hw_platform_info config_info clk_info demoted_up} {
    upvar 1 $demoted_up demoted_runs

    set steps_log           [dict get $config_info steps_log] 
    set wait_on_all_runs    [dict get $config_info wait_on_all_impl_runs] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set wns_threshold       [dict get $clk_info worst_negative_slack]
    set error_hold_vio      [dict get $clk_info error_on_hold_violation]

    set ignore_hold_vio     [expr ! $error_hold_vio]

    # new wait on run behavior - only wait on completion of the first qualified impl run
    set is_wait true
    set best_run ""
    while {$is_wait} {
      # the return value of get_impl_runs_status can be used as a tcl dict
      set runs_status [::vitis_log::get_impl_runs_status -completed]
      # puts "debug: runs_status is\n$runs_status"
      # dict for {key value} $runs_status {puts "key is $key ;; value is $value"}
      if {[dict exists $runs_status "completed_runs:"]} {
        set completed_runs [dict get $runs_status "completed_runs:"]
        # completed_runs is a (space separated) list of run names
        if {$completed_runs ne ""} {
          foreach _run $completed_runs {
            # puts "dbg: found completed run $_run"
            # check if this run meets timing
            if { [is_best_run $_run $wns_threshold $ignore_hold_vio] } {
              # puts "debug: found the best run $_run"
              set best_run $_run
              # puts "debug: wait_on_run $_run"
              # at this point, the run has already completed, so wait_on_run
              # doesn't wait at all, all it does here is to copy the messages
              # from runme.log to vivado.log
              wait_on_run $_run
              set is_wait false
              break
            } else {
              # This run failed.
              if {[lsearch $demoted_runs $_run] < 0} {
                # And this is the first time we've encountered it.
                lappend demoted_runs $_run
                # Tell the world about this immediately.
                set run_cmd_id $ocl_util::run_ids($_run)
                ::vitis_log::status $run_cmd_id DEMOTED
              }
            }
          }
        }
      }

      # if we couldn't find any qualified run in *all* the impl runs
      # we exit the while loop
      if {$is_wait} {
        set num_total_runs [dict get $runs_status "num_total_runs:"]
        if {[dict exists $runs_status "num_completed_runs:"]} {
          set num_completed_runs [dict get $runs_status "num_completed_runs:"]
          # puts "dbg: num_total_runs is $num_total_runs; num_completed_runs is $num_completed_runs"
          if {$num_total_runs == $num_completed_runs} {
            set is_wait false
          }
        }
      }

      if {$is_wait} {
        # wait 10 seconds
        after [expr {int(10 * 1000)}]
      }
    }

    if {$best_run ne ""} {
      set summary "First Timing Closed Implementation Run: $best_run"
      # capture impl reports
      # note at this point, not all impl runs are complete, so the report files in generated_reports.log
      # may not be complete for each run
      set generated_reports_log [file join $vivado_output_dir "generated_reports.log"]
      add_to_steps_log $steps_log "internal step: log_generated_reports for implementation '${generated_reports_log}'" [fileName]:[lineNumber [info frame]]
      log_generated_reports $generated_reports_log $impl_runs
    } else {
      set summary "Timing Closed Implementation Run: NONE" 
    }

    # puts "\n$summary\n"
    # add an summary entry to steps.log
    add_to_steps_log $steps_log "Multi-strategy Flow: $summary" [fileName]:[lineNumber [info frame]]

    if {$best_run eq ""} {
      add_to_steps_log $steps_log "internal step: problem finding a qualified implementation run" [fileName]:[lineNumber [info frame]]
      add_to_steps_log $steps_log "status: fail (timing failure)" [fileName]:[lineNumber [info frame]]
      error2file $vivado_output_dir "problem finding a qualified implemenation run in Multi-Strategies mode, none of the\
                                     implementation runs can meet timing, please look at the run log file (runme.log)\
                                     under each implementation run directory for more information" 
    }
    return $best_run
  }

  # in 2020.1, dispatch server doesn't support lsf, we have rely on run's status property
  # to track the status of multiple impl runs
  proc wait_on_first_run_lsf_ {impl_runs hw_platform_info config_info clk_info demoted_up} {
    upvar 1 $demoted_up demoted_runs

    set steps_log           [dict get $config_info steps_log] 
    set wait_on_all_runs    [dict get $config_info wait_on_all_impl_runs] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set wns_threshold       [dict get $clk_info worst_negative_slack]
    set error_hold_vio      [dict get $clk_info error_on_hold_violation]

    set ignore_hold_vio     [expr ! $error_hold_vio]

     # new wait on run behavior - only wait on completion of the first qualified impl run
     set is_wait true
     set best_run ""
     while {$is_wait} {
       foreach _run $impl_runs {
         set run_status [get_property STATUS $_run]
         # puts "debug: run $_run, status is $run_status"
         # note: for versal platform, the final run status is "write_device_image ..."
         if {$run_status eq "write_bitstream Complete!" || $run_status eq "write_device_image Complete!"}  {
           # puts "debug: found completed run $_run"
           # check if this run meets timing
           if { [is_best_run $_run $wns_threshold $ignore_hold_vio] } {
             # puts "debug: found the best run $_run"
             set best_run $_run
             # puts "debug: wait_on_run $_run"
             # at this point, the run has already completed, so wait_on_run
             # doesn't wait at all, all it does here is to copy the messages
             # from runme.log to vivado.log
             wait_on_run $_run
             set is_wait false
             break
           } else {
             # This run failed.
             if {[lsearch $demoted_runs $_run] < 0} {
               # And this is the first time we've encountered it.
               lappend demoted_runs $_run
               # Tell the world about this immediately.
               set run_cmd_id $ocl_util::run_ids($_run)
               ::vitis_log::status $run_cmd_id DEMOTED
             }
           }
         }
       }

       # TODO: move this to a seprate utility tcl proc
       # if we couldn't find any qualified run in *all* the impl runs
       # we exit the while loop
       if {$is_wait} {
         # puts "debug: check if we need to wait"
         set continue_wait false
         foreach _run $impl_runs {
           set run_status [get_property STATUS $_run]
           # puts "debug: run $_run, status is $run_status"
           # a run has started
           if { [string equal $run_status "Scripts Generated"] } {
             set continue_wait true
             break;
           }
           if { [string equal $run_status "Not Started"] } {
             set continue_wait true
             break;
           }
           # a run is queued 
           if { [string first "Queued" $run_status] == 0 } {
             set continue_wait true
             break;
           }
           # a run is running
           if { [string first "Running" $run_status] == 0 } {
             set continue_wait true
             break;
           }
         }
         if {!$continue_wait} {
           set is_wait false
           # puts "debug: all the runs are done, no need to wait any longer"
         }
       }

       if {$is_wait} {
         # wait 10 seconds
         after [expr {int(10 * 1000)}]
       }
     }

     # TODO: move this to a seprate utility tcl proc
     if {$best_run ne ""} {
       set summary "First Timing Closed Implementation Run: $best_run"
       # capture impl reports
       # note at this point, not all impl runs are complete, so the report files in generated_reports.log
       # may not be complete for each run
       set generated_reports_log [file join $vivado_output_dir "generated_reports.log"]
       add_to_steps_log $steps_log "internal step: log_generated_reports for implementation '${generated_reports_log}'" [fileName]:[lineNumber [info frame]]
       log_generated_reports $generated_reports_log $impl_runs
     } else {
       set summary "Timing Closed Implementation Run: NONE" 
     }

     # puts "\n$summary\n"
     # add an summary entry to steps.log
     add_to_steps_log $steps_log "Multi-strategy Flow: $summary" [fileName]:[lineNumber [info frame]]

     if {$best_run eq ""} {
       add_to_steps_log $steps_log "internal step: problem finding a qualified implementation run" [fileName]:[lineNumber [info frame]]
       add_to_steps_log $steps_log "status: fail (timing failure)" [fileName]:[lineNumber [info frame]]
       error2file $vivado_output_dir "problem finding a qualified implemenation run in Multi-Strategies mode, none of the\
                                      implementation runs can meet timing, please look at the run log file (runme.log)\
                                      under each implementation run directory for more information" 
     }
     return $best_run
  }
  
  ################################################################################
  # wait_on_impl_runs
  # utility function called by impl step
  #   Description: wait on impl run, work with both single run and 
  #                multi-strategies
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info
  ################################################################################
  proc wait_on_impl_runs {impl_runs hw_platform_info config_info clk_info} {
    set steps_log           [dict get $config_info steps_log] 
    set wait_on_all_runs    [dict get $config_info wait_on_all_impl_runs] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set wns_threshold       [dict get $clk_info worst_negative_slack]
    set lsf_string          [dict get $config_info lsf_string_impl]
    set output_dir          [dict get $config_info output_dir]
    
    set is_lsf false
    if {$lsf_string ne ""} {
      set is_lsf true
    }

    if {[llength $impl_runs] > 1} {
      # multi-strategies
      if {$wait_on_all_runs} {
        # old wait on run behavior - wait on completion of all impl runs 
        # puts "debug: wait_on_all_runs_"
        set best_run [wait_on_all_runs_ $impl_runs $hw_platform_info $config_info $clk_info]
        foreach run $impl_runs {
          set run_cmd_id $ocl_util::run_ids($run)
          if {$run eq $best_run} {
            set status PROMOTED
          } else {
            set status DEMOTED
          }
          ::vitis_log::status $run_cmd_id $status
        }
      } else {
        # new wait on run behavior - only wait on completion of the first qualified impl run
        # We want to keep track of which runs finish but don't work (DEMOTED), which run passes and is PROMOTED,
        # and which runs we just ABANDONED because we already found a satisfactory result. The PROMOTED run is
        # easy, since that is the one returned by the wait_on_first_run_* procs. The procs know which runs are
        # DEMOTED, because it evaluates them. That leaves the ABANDONED runs, which we don't explicitly know,
        # but we can figure out by process of elimination.
        set demoted_runs {}
        if {$is_lsf || ![is_drcv] } {
          # puts "debug: wait_on_first_run_lsf_"
          set best_run [wait_on_first_run_lsf_ $impl_runs $hw_platform_info $config_info $clk_info demoted_runs]
        } else {
          # puts "debug: wait_on_first_run_local_"
          set best_run [wait_on_first_run_local_ $impl_runs $hw_platform_info $config_info $clk_info demoted_runs]
        }
        # We need to log the best_run and the ABANDONED runs.
        foreach run $impl_runs {
          if {[lsearch $demoted_runs $run] >= 0} {
            # The DEMOTED runs were already logged.
            continue
          }
          set run_cmd_id $ocl_util::run_ids($run)
          if {$run eq $best_run} {
            set status PROMOTED
          } else {
            set status ABANDONED
          }
          ::vitis_log::status $run_cmd_id $status
        }
      }
      set cmd_name "vivado.impl"
      set impl_id $ocl_util::run_ids($cmd_name)
      if {$best_run eq ""} {
        set status FAILED
      } else {
        set status PASSED
      }
      ::vitis_log::status $impl_id $status
      log_runs_update $impl_runs
    } else {
      # single impl run, impl_runs only contains impl_1
      foreach run $impl_runs {
        if { [catch {
          # use vivado built-in wait_on_run
          wait_on_run $run
        } catch_result return_options_dict] } {
          set run_dir [get_property DIRECTORY $run]
          ocl_util::add_to_steps_log $steps_log "status: fail" [ocl_util::extFileName]:[expr {[dict get [info frame -1] line] + [dict get [info frame 0] line]}] 
          ocl_util::add_to_steps_log $steps_log "log: $run_dir/runme.log" [ocl_util::extFileName]:[expr {[dict get [info frame -1] line] + [dict get [info frame 0] line]}]
          set sw_persona_msg "Failed to complete hardware generation. The run name is 'impl_1'."
          ocl_util::log_exception $output_dir $sw_persona_msg $catch_result $return_options_dict
        }
      }
      set best_run [ocl_util::check_single_impl_run_status $hw_platform_info $config_info $clk_info]
    }

    return $best_run
  }

  ################################################################################
  # copy_impl_run_output_files
  # utility function called by impl step
  #   Description: copy the output files of impl run (e.g. bit, pdi, dcp ...) to vpl output dir (i.e. int)
  #                for multi-strategies, we only copy the results for the "best" impl run
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info
  ################################################################################
  proc copy_impl_run_output_files {best_run hw_platform_info config_info} {
    set link_output_format  [dict get $hw_platform_info link_output_format]
    set hw_platform_uses_pr [dict get $hw_platform_info hw_platform_uses_pr]

    set vpl_output_dir      [dict get $config_info vpl_output_dir] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set out_partial_bit     [dict get $config_info out_partial_bitstream]
    set out_partial_pdi     [dict get $config_info out_partial_pdi]
    set out_partial_clear_bit  [dict get $config_info out_partial_clear_bit]
    set out_full_bit        [dict get $config_info out_full_bitstream]
    set out_full_pdi        [dict get $config_info out_full_pdi] 
    set out_mcs_file        [dict get $config_info out_mcs] 
    set out_primary_mcs_file    [dict get $config_info out_primary_mcs] 
    set out_secondary_mcs_file  [dict get $config_info out_secondary_mcs] 
    set encrypt_impl_dcp    [dict get $config_info encrypt_impl_dcp]
    set clbinary_name       [dict get $config_info clbinary_name]
    set reconfig_module     [dict get $config_info reconfig_module]
    set impl_to_step        [dict get $config_info impl_to_step]
    set steps_log           [dict get $config_info steps_log] 
    set gen_fixed_xsa_in_top_prj [dict get $config_info gen_fixed_xsa_in_top_prj] 
    set is_hw_export        [dict get $config_info is_hw_export]

    set run_name $best_run
    set run_dir [get_property DIRECTORY [get_runs $run_name]]
    add_to_steps_log $steps_log "internal step: copy implementation run ($run_name) output files" [fileName]:[lineNumber [info frame]]

    set copy_dcp false
    set copy_bitstream false
    set copy_pdi false

    # note: link_output_format could be "dcp", "bitstream", "pdi", "dcp, bitstream"
    #       "dcp, pdi"
    if { [has_output_format $link_output_format "dcp"] } {
      set copy_dcp true
    } 
    # bitstream and pdi are mutually exclusive
    if { [has_output_format $link_output_format "bitstream"] } {
      set copy_bitstream true
    } elseif { [has_output_format $link_output_format "pdi"] } {
      set copy_pdi true
    }

    # aws dcp support
    # copy the post-route dcp to vpl output directory
    # TODO: we need a better way to handle route vs post_route_phys_opt
    if { $copy_dcp } {
      if { $encrypt_impl_dcp} {
        if { [file exists $run_dir/encrypted_postroute_physopt.dcp] } {
          set impl_dcp [glob -nocomplain "$run_dir/encrypted_postroute_physopt.dcp"]
        } else {
          set impl_dcp [glob -nocomplain "$run_dir/encrypted_routed.dcp"]
        }
      } else {
        set impl_dcp [glob -nocomplain "$run_dir/*_postroute_physopt.dcp"]
        if { [string equal $impl_dcp ""] } {
          set impl_dcp [glob -nocomplain "$run_dir/*_routed.dcp"]
        }
      }
      # TODO: we may need to change the output file name to not hardcode "routed"
      set out_routed_dcp "$vpl_output_dir/routed.dcp"
      if { ![string equal $impl_dcp ""] } {
        puts "INFO: \[OCL_UTIL\] copy -force $impl_dcp $out_routed_dcp"
        file copy -force $impl_dcp $out_routed_dcp
      }
    } 
    
    if { $copy_bitstream } {
      # copy the generated bit files to vpl output dir 
      if { $hw_platform_uses_pr } {
        # there could be one partial bit and one partial clear bit files.
        # kcu1500 generates both bit files while vcu1525 only generats the partial bit file
        set partial_bit [glob -nocomplain "$run_dir/*_partial.bit"]
        set partial_clear_bit [glob -nocomplain "$run_dir/*_partial_clear.bit"]
        # puts "--- DEBUG: partial_bit is $partial_bit"
        # puts "--- DEBUG: partial_clear_bit is $partial_clear_bit"

        if { ![string equal $partial_bit ""] && [file exists $partial_bit] } {
          file copy -force $partial_bit $out_partial_bit
        }
        if { ![string equal $partial_clear_bit ""] && [file exists $partial_clear_bit] } {
          file copy -force $partial_clear_bit $out_partial_clear_bit
        }

      } else {
        # flat flow (i.e. zynq)
        set full_bit [glob -nocomplain "$run_dir/*.bit"]
        if { ![string equal $full_bit ""] && [file exists $full_bit] } {
          file copy -force $full_bit $out_full_bit
        }
        # Pre-clean up the int directory in case write_cfgmem was rerun 
        # with different flash values
        file delete -force $out_mcs_file
        file delete -force $out_primary_mcs_file
        file delete -force $out_secondary_mcs_file
        set mcs_file "$run_dir/system.mcs"
        if { [file exists $mcs_file] } {
          file copy -force $mcs_file $out_mcs_file
        }
        set primary_mcs_file "$run_dir/system_primary.mcs"
        if { [file exists $primary_mcs_file] } {
          file copy -force $primary_mcs_file $out_primary_mcs_file
        }
        set secondary_mcs_file "$run_dir/system_secondary.mcs"
        if { [file exists $secondary_mcs_file] } {
          file copy -force $secondary_mcs_file $out_secondary_mcs_file
        }
      }
    } 
    
    if { $copy_pdi }  {
      # copy the generated pdi file to vpl output dir
      if { $hw_platform_uses_pr } {
        set partial_pdi [glob -nocomplain "$run_dir/*_partial.pdi"]
        # when run property "GEN_FULL_BITSTREAM" is set to true, we may end up with multiple 
        # partial pdi files. as of 07/26/19, the write_device_image command that generates the full
        # pdi file doesn't have "-no_partial_pdifile"
        if {[llength $partial_pdi] > 1} {
          set partial_pdi [glob -nocomplain "$run_dir/*${reconfig_module}_partial.pdi"]
          if {$partial_pdi ne ""} {
            puts "INFO: multiple partial pdi files detected, use '$partial_pdi' as the primary output"
          } else {
            puts "ERROR: multiple partial pdi files detected, but there is none that matches '*${reconfig_module}_partial.pdi'"
            error2file $vivado_output_dir "no proper partial pdi file generated"
          }
        }
        if { ![string equal $partial_pdi ""] && [file exists $partial_pdi] } {
          file copy -force $partial_pdi $out_partial_pdi
        }
      } else {
        set full_pdi [glob -nocomplain "$run_dir/*.pdi"] 
        if { ![string equal $full_pdi ""] && [file exists $full_pdi] } { 
          file copy -force $full_pdi $out_full_pdi
        }
        # Pre-clean up the int directory in case write_cfgmem was rerun 
        # with different flash values
        file delete -force $out_mcs_file
        file delete -force $out_primary_mcs_file
        file delete -force $out_secondary_mcs_file
        set mcs_file "$run_dir/system.mcs"
        if { [file exists $mcs_file] } {
          file copy -force $mcs_file $out_mcs_file
        }
        set primary_mcs_file "$run_dir/system_primary.mcs"
        if { [file exists $primary_mcs_file] } {
          file copy -force $primary_mcs_file $out_primary_mcs_file
        }
        set secondary_mcs_file "$run_dir/system_secondary.mcs"
        if { [file exists $secondary_mcs_file] } {
          file copy -force $secondary_mcs_file $out_secondary_mcs_file
        }
      } 
    } 

    # copy ram.rpt file to vpl output dir
    set ram_utilization_report [glob -nocomplain "$run_dir/ram.rpt"]
    if {$ram_utilization_report ne ""} {
       catch {file copy -force $ram_utilization_report $vpl_output_dir}
    }

    # copy logic location file to vpl output dir
    # set filename [get_property top [current_fileset]]
    # append filename ".ll"
    set logic_location_file [glob -nocomplain "$run_dir/*.ll"]
    if {$logic_location_file ne ""} {
       catch {file copy -force $logic_location_file $vpl_output_dir}
    }

    # copy _new_clk_freq file to vpl output dir
    set clk_freq_file [glob -nocomplain "$run_dir/_new_clk_freq"]
    if {$clk_freq_file ne ""} {
       # puts "debug point 2: copy $clk_freq_file to $vpl_output_dir"
       catch {file copy -force $clk_freq_file $vpl_output_dir}
    }

    # --to_step vpl.impl.<step> support
    # if parameter is set to true, we want to copy the *dcp files to vpl output directory
    # (_x/link/int)
    set enable_int_dcp [get_param project.writeIntermediateCheckpoints]
    if { ![string equal $impl_to_step ""] && $enable_int_dcp } {
      set dcp_files [glob -nocomplain "$run_dir/*.dcp"]
      if { ![string equal $dcp_files ""] } {
        file copy -force {*}$dcp_files $vpl_output_dir
      }
    }

    # Copy LTX files up to vpl output dir
    # CR 1011484: copy *just* debug_nets.ltx and rename it to <binary>.ltx
    # ltx file generation is usually triggered by --dk chipscope, it is also possible
    # for users to manually insert ILA core(s) into the RTL kernel
    # ltx file is consumed by labtools hardware debug tools only, it is NOT part of xclbin
    # ltx file contains debug sumbols for hardware
    set ltx_file [glob -nocomplain "$run_dir/debug_nets.ltx"]
    if {$ltx_file ne ""} {
       set out_ltx_file "$clbinary_name.ltx"
       catch {file copy -force $ltx_file $vpl_output_dir/$out_ltx_file}
    }

    # generate fixed platform
    if {$gen_fixed_xsa_in_top_prj && $is_hw_export} {
      generate_fixed_hw_platform $hw_platform_info $config_info true
    }
  }

  proc get_full_pdi_file {hw_platform_uses_pr} {
    set full_pdi ""
    set pdi_files [glob -nocomplain "./*.pdi"]
    # puts "--- DEBUG: pdi_files is $pdi_files"

    if {$hw_platform_uses_pr} {
      set partial_pdi_files [glob -nocomplain "./*_partial.pdi"]
      # puts "--- DEBUG: partial_pdi_files is $partial_pdi_files"

      # remove partial pdi files from pdi_files, the only thing left
      # should be just full pdi
      # when run property "GEN_FULL_BITSTREAM" is set to true, we may end up with multiple 
      # partial pdi files
      set full_pdi $pdi_files
      foreach partial_pdi $partial_pdi_files {
        if { ![string equal $partial_pdi ""] && [file exists $partial_pdi] } {
          set idx [lsearch $full_pdi $partial_pdi]
          set full_pdi [lreplace $full_pdi $idx $idx]
        }
      }
    } else {
      if { ![string equal $pdi_files ""] && [file exists $pdi_files] } { 
        set full_pdi $pdi_files
      }
    }
    # puts "--- DEBUG: full_pdi is $full_pdi"

    return $full_pdi
  }

  proc generate_fixed_hw_platform {hw_platform_info config_info {open_design false}} {
    set hw_platform_uses_pr          [dict get $hw_platform_info hw_platform_uses_pr]
    set design_intent_server_managed [dict get $hw_platform_info design_intent_server_managed]
    set design_intent_external_host  [dict get $hw_platform_info design_intent_external_host]
    set design_intent_datacenter     [dict get $hw_platform_info design_intent_datacenter]
    set design_intent_embedded       [dict get $hw_platform_info design_intent_embedded]
    set ocl_inst_path                [dict get $hw_platform_info ocl_region]

    set fixed_xsa            [dict get $config_info fixed_xsa]
    set vpl_output_dir       [dict get $config_info vpl_output_dir]
    set is_hw_emu            [dict get $config_info is_hw_emu]
    set is_versal            [dict get $config_info is_versal]
    set enable_versal_dfx    [dict get $config_info enable_versal_dfx]

    if { [catch {
      if {$open_design} {
        # this tcl proc is invoked at the top vivado project (see copy_impl_run_output_files)
        # current working directory is the _x/link/vivado/vpl
        # open the impl run
        # TODO: in order for generated fixed platform to contain hdf content, we 
        # need an implemented design in memory
        # in this case, write_hw_platform can find the bit/pdi file from the impl run directory 
        puts "hw_export: open_run impl_1"
        open_run impl_1
      } else {
        # this tcl proc is invoked as part of the write_bit/pdi post tcl hook in impl run
        # current working directory is the impl run directory (_x/link/vivado/vpl/prj/prj.runs/impl_1/)
        # when hw_export is enabled for versal platform, run property GEN_FULL_BISTREAM is set to 
        # true (see HPIVplScriptWriter). when usesPR is true, this will generate both full and partial
        # bit/pdi files. we will get the full pdi and pass it write_hw_platform
        
        # find the full pdi for hw flow
        # full pdi is not applicable for hw_emu
        if {$is_versal && !$is_hw_emu} {
          set full_pdi [get_property platform.full_pdi_file [current_project]]
          if {$full_pdi eq ""} {
            set full_pdi [get_full_pdi_file $hw_platform_uses_pr]
            if {$full_pdi ne ""} {
              puts "hw_export: set_property platform.full_pdi_file $full_pdi \[current_project\]" 
              set_property platform.full_pdi_file $full_pdi [current_project]
            }
          }
        }
      }

      # SDXFLO-3415: for v++ package to use fixed XSA from v++ link, usesPr and 
      # designIntent needs to be populated in the fixed XSA with values from the 
      # expandable platform/xsa passed to v++ link
      puts "hw_export: set design_intent and uses_pr properties"
      set_property platform.design_intent.server_managed $design_intent_server_managed [current_project] 
      set_property platform.design_intent.external_host $design_intent_external_host [current_project] 
      set_property platform.design_intent.datacenter $design_intent_datacenter [current_project] 
      set_property platform.design_intent.embedded $design_intent_embedded [current_project] 
      set_property platform.uses_pr $hw_platform_uses_pr [current_project] 

      set include_bit_option ""
      if {!$is_hw_emu} {
        set include_bit_option "-include_bit"
      }

      set rp_option ""
      if {!$is_hw_emu && $enable_versal_dfx} {
        set rp_option "-rp $ocl_inst_path"
      }

      # note: tool_flow property is set to SDx in the impl run driver script for child vivado 
      #       currently, this property is only set as part of init_design step
      # special usecases:
      # 1. when running in the reuse_impl mode, we create a new project instead of using
      # the existing project, so we have to set tool_flow explicitly
      # 2. when running --from vpl.impl.<step>, impl run driver script doesn't set it
      #
      # puts "hw_export: tool_flow = [get_property tool_flow [current_project]]"
      set_property tool_flow SDx [current_project]
      puts "hw_export: tool_flow = [get_property tool_flow [current_project]]"

      puts "hw_export: write_hw_platform -fixed $include_bit_option $rp_option $vpl_output_dir/$fixed_xsa"
      write_hw_platform -fixed {*}$include_bit_option {*}$rp_option $vpl_output_dir/$fixed_xsa
    } catch_res] } {
      puts "WARNING: Failed to generate fixed platform $vpl_output_dir/$fixed_xsa: $catch_res"
    }
  }

  ################################################################################
  # set_board_part_repo_and_connections
  # utility function called by create_bd step
  #   Description: set board_part_repo_paths and board_connections properties on current project
  #      
  #   Arguments:
  #      config_info 
  #      bd_file is an output argument
  #
  #   Reference: http://confluence.xilinx.com/display/XSW/Support+Board+DIMM+Modeling+-+Framework+Spec
  ################################################################################
  proc set_board_part_repo_and_connections {hw_platform_info config_info} {
    set hw_platform_board_repo     [dict get $hw_platform_info hw_platform_board_repo]
    set hw_platform_board_part     [dict get $hw_platform_info hw_platform_board_part]
    set hw_platform_bconn_locked   [dict get $hw_platform_info hw_platform_bconn_locked]
    set hw_platform_bconn_unlocked [dict get $hw_platform_info hw_platform_bconn_unlocked]
   
    set user_board_repo            [dict get $config_info user_board_repo]
    set user_bconn                 [dict get $config_info user_bconn]

    # set board_part_repo_paths property on current project. $user has higher priority than $hw_platform (first one wins)
    # set_board_repo_paths_property $user_board_repo $hw_platform_board_repo
    set board_repo [list]
    if { $user_board_repo ne "" } {
      lappend board_repo {*}$user_board_repo
    }
    if { $hw_platform_board_repo ne "" } {
      lappend board_repo {*}$hw_platform_board_repo
    }
    if { $board_repo ne "" } {
      puts "INFO: \[OCL_UTIL\] set_property board_part_repo_paths $board_repo \[current_project\]"
      set_property board_part_repo_paths $board_repo [current_project]
    } 

    # set the board part
    if {$hw_platform_board_part ne ""} {
      puts "INFO: \[OCL_UTIL\] set_property board_part $hw_platform_board_part \[current_project\]"
      set_property board_part $hw_platform_board_part [current_project]
    }
 
    # set board_connections property on current project. $user has higher priority than $hw_platform_unlocked.
    # $hw_platform_locked cannot be overwritten (last one wins) 
    # set_board_connections_property $hw_platform_bconn_unlocked $user_bconn $hw_platform_bconn_locked
    set board_connections [list]
    if { $hw_platform_bconn_unlocked ne "" } {
      lappend board_connections {*}$hw_platform_bconn_unlocked
    }
    if { $user_bconn ne "" } {
      lappend board_connections {*}$user_bconn
    }
    if { $hw_platform_bconn_locked ne "" } {
      lappend board_connections {*}$hw_platform_bconn_locked
    }
    if { $board_connections ne "" } {
      puts "INFO: \[OCL_UTIL\] set_property board_connections $board_connections \[current_project\]"
      set_property board_connections $board_connections [current_project]
    }

  }

  ################################################################################
  # source_user_pre_sys_link_tcl
  #   utility function called by create_bd step
  #   Description: source the user specified pre_sys_link tcl hook
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info 
  ################################################################################
  proc source_user_pre_sys_link_tcl {hw_platform_info config_info} {
    set user_pre_sys_link_tcl   [dict get $hw_platform_info user_pre_sys_link_tcl] 

    set dr_bd_tcl           [dict get $config_info dr_bd_tcl] 
    set steps_log           [dict get $config_info steps_log] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set project_name        [dict get $config_info proj_name]
    set return_pre_sys_link_tcl [dict get $config_info return_pre_sys_link_tcl]

    if { ![string equal $user_pre_sys_link_tcl ""] && [file exists $user_pre_sys_link_tcl] } {
      # OPTRACE "Sourcing user pre_sys_link Tcl script" START
      # add_to_steps_log $steps_log "internal step: source $user_pre_sys_link_tcl" [fileName]:[lineNumber [info frame]]
      # if { [catch {source $user_pre_sys_link_tcl} result return_options_dict] } {
      #   set sw_persona_msg "Failed to update block diagram in project required for hardware synthesis. "
      #   append sw_persona_msg "The project is '$project_name'. The user supplied update script is "
      #   append sw_persona_msg "'$user_pre_sys_link_tcl'. The script was provided using parameter "
      #   append sw_persona_msg "'compiler.userPreSysLinkTcl'."
      #   OPTRACE "Sourcing user pre_sys_link Tcl script" END
      #   log_exception $vivado_output_dir $sw_persona_msg $result $return_options_dict
      # }
      # OPTRACE "Sourcing user pre_sys_link Tcl script" END
      set optrace_task "Source user pre_sys_link Tcl script"
      set sw_persona_msg "Failed to update block diagram in project required for hardware synthesis. \
                         The project is '$project_name'. The user supplied update script is '$user_pre_sys_link_tcl'. \
                         The configuration script was provided using parameter 'compiler.userPreSysLinkTcl'.
      run_cmd "source $user_pre_sys_link_tcl"
    }

    if { $return_pre_sys_link_tcl } {
      puts "INFO: return_pre_sys_link_tcl enabled, skip sourcing $dr_bd_tcl and everything after"
      return
    }
  }

  ################################################################################
  # import_dr_bd
  #   utility function called by create_bd step
  #   Description: import the dr bd 
  #      
  #   Arguments:
  #      hw_platform_info 
  #      config_info 
  ################################################################################
  proc import_dr_bd {hw_platform_info config_info} {
    set hw_platform_dr_bd   [dict get $hw_platform_info hw_platform_dr_bd] 
    set hw_platform_state   [dict get $hw_platform_info hw_platform_state] 
    set emu_src_dir         [dict get $hw_platform_info emu_src_dir]
    set hw_platform_uses_pr [dict get $hw_platform_info hw_platform_uses_pr]
    set ocl_inst_path       [dict get $hw_platform_info ocl_region]

    set is_hw_emu           [dict get $config_info is_hw_emu] 
    set steps_log           [dict get $config_info steps_log] 
    set reconfig_module     [dict get $config_info reconfig_module]
    set explicit_emu_data   [dict get $config_info enable_explicit_emu_data]

    # impl platform (pcie: platformState = impl && usesPR = true)
    #   hw flow    : import the dr bd from hw_platform, and associate it with the reconfigurable module 
    #   hw_emu flow: import the emu dr bd (i.e. emu/emu.bd) from hw_platform
    #
    # synth platform (pcie: platformState = synth && usesPR = false)
    #   import the dr bd from hw_platform
    #
    # pre_synth platform
    #   soc platform (usesPR = false)
    #     hw     flow: no need to import the dr bd, it is already done as part of rebuild.tcl
    #     hw_emu flow: no need to import the dr bd, it is already done as part of rebuild.tcl
    #   pcie platform (i.e. kyle' usecase) (usesPR = true)
    #     hw     flow: no need to import the dr bd, it is already done as part of rebuild.tcl
    #     hw_emu flow: import the emu dr bd (i.e. emu.bd) from hw_platform
      # note: hw_platform_dr_bd is empty for soc platform
    if { [string equal $hw_platform_state "pre_synth"] } {
      # pre_synth platform
      if { $is_hw_emu && $hw_platform_dr_bd ne "" && [file exists $hw_platform_dr_bd] } {
        # pcie platform + hw_emu flow (for kyle)
        add_to_steps_log $steps_log "internal step: import_files -norecurse $hw_platform_dr_bd" [fileName]:[lineNumber [info frame]]
        import_files -norecurse $hw_platform_dr_bd 
      }
    } else {
      # impl or synth platform
      set rm_switch ""
      if { !$is_hw_emu} {
        # note synth platform has usesPR set to false
        if { $hw_platform_uses_pr } {
          set rm_switch "-of_objects [get_reconfig_modules $reconfig_module]"
        }
      }
      add_to_steps_log $steps_log "internal step: import_files -norecurse $hw_platform_dr_bd $rm_switch" [fileName]:[lineNumber [info frame]]
      # we should use import_files to copy the bd file to the local project
      #   1. the temporaray location might be read-only 
      #   2. user could potentially delete the temporary location
      import_files -norecurse $hw_platform_dr_bd {*}$rm_switch

      # for synth platform and hw target only
      if { [string equal $hw_platform_state "synth"] && !$is_hw_emu} {
        set bd_file [file tail $hw_platform_dr_bd]
        puts "INFO: \[OCL_UTIL\] set_property scoped_to_cells $ocl_inst_path \[get_files $bd_file\]"
        set_property scoped_to_cells $ocl_inst_path [get_files $bd_file]
      }

      # TODO: this support may not be needed any more with new style hw_emu platform
      # new style hw_emu platform is generated using write_hw_platform -hw_emu
      # hw_emu re-arch 2019.2 (explicity emu data support)
      # import all the sources files in the emu src directory
      if {$is_hw_emu && $explicit_emu_data} {
        if {$emu_src_dir ne ""} {
          set emu_source_files [glob -nocomplain "$emu_src_dir/*"]
          foreach emu_source $emu_source_files {
            add_to_steps_log $steps_log "internal step: import_files -fileset sim_1 -norecurse $emu_source" [fileName]:[lineNumber [info frame]]
            import_files -fileset sim_1 -norecurse $emu_source
          }
          update_compile_order -fileset sim_1
        }
      }
    }
  }

  proc get_bd_file {hw_platform_info config_info} {
    set hw_platform_dr_bd   [dict get $hw_platform_info hw_platform_dr_bd] 
    set dr_bd_name          [dict get $hw_platform_info dr_bd_name] 
    set hw_platform_state   [dict get $hw_platform_info hw_platform_state] 
    set is_hw_emu           [dict get $config_info is_hw_emu] 

    # starting 2018.3 hw_platform captures the dr_bd_name (the bd file name)
    # for pcie platform, the dr_bd_name refers to the regular dr bd used by hw flow,
    # so, we can *not* use dr_bd_name for hw_emu flow
    # note: we should be able to use dr_bd_name for soc platform + hw_emu flow
    if {$dr_bd_name ne "" && !$is_hw_emu} {
      # pcie platform + hw flow; soc platform + hw flow
      set bd_file $dr_bd_name
    } else {
      # pcie platform + hw_emu flow
      # get the base file name of $hw_platform_dr_bd (i.e. emu.bd)
      if {$hw_platform_dr_bd ne ""} {
        set bd_file [file tail $hw_platform_dr_bd]
      } else {

        # old soc platform (where dr_bd_name is not captured in the hw platform metadata)
        # for soc platform, there is no dr_bd file captured in the hw platform
        # we assume there is only bd in the project after sourcing rebuild.tcl
        if { [string equal $hw_platform_state "pre_synth"] } {
          set bd_file [file tail [lindex [get_files *.bd] 0]]
        }
      }
    }
    return $bd_file
  }

  ################################################################################
  # source_post_sys_link_tcls
  #   utility function called by update_bd step
  #   Description: source post_sys_link and user_post_sys_link tcl hooks
  #      
  #   Arguments:
  #      hw_platform_info 
  #      config_info 
  ################################################################################
  proc source_post_sys_link_tcls {hw_platform_info config_info} {
    set post_sys_link_tcl   [dict get $hw_platform_info post_sys_link_tcl] 
    set user_post_sys_link_tcl [dict get $hw_platform_info user_post_sys_link_tcl] 

    # variables to handle correct hook and compiler names in messaging
    set hook_name post_sys_link
    set param_name compiler.userPostSysLinkTcl

    # post_sys_link_tcl is deprecated in 20.1 and replaced with post_debug_profile_overlay_tcl
    # so if this new value is specified in platform, use it to override post_sys_link_tcl 
    set post_debug_profile_overlay_tcl [dict get $hw_platform_info post_debug_profile_overlay_tcl]
    if {![string equal $post_debug_profile_overlay_tcl ""]} {
      set post_sys_link_tcl $post_debug_profile_overlay_tcl
      set hook_name post_debug_profile_overlay
    }

    # user_post_sys_link_tcl is deprecated in 20.1 and replaced with user_post_debug_profile_overlay_tcl
    # so if this new value is specified by user, use it to override user_post_sys_link_tcl 
    set user_post_debug_profile_overlay_tcl [dict get $hw_platform_info user_post_debug_profile_overlay_tcl]
    if {![string equal $user_post_debug_profile_overlay_tcl ""]} {
      set user_post_sys_link_tcl $user_post_debug_profile_overlay_tcl
      set hook_name post_debug_profile_overlay
      set param_name compiler.userPostDebugProfileOverlayTcl
    }

    set steps_log           [dict get $config_info steps_log] 
    # set output_dir          [dict get $config_info output_dir] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set project_name        [dict get $config_info proj_name]

    # post_sys_link_tcl needs to be sourced after sourcing dr_bd_tcl
    if { ![string equal $post_sys_link_tcl ""] && [file exists $post_sys_link_tcl] } {
      # OPTRACE "Sourcing hardware platform $hook_name Tcl script" START
      # add_to_steps_log $steps_log "internal step: source $post_sys_link_tcl" [fileName]:[lineNumber [info frame]]
      # if { [catch {source $post_sys_link_tcl} result return_options_dict] } {
      #   set sw_persona_msg "Failed to update block diagram in project required for hardware synthesis. "
      #   append sw_persona_msg "The project is '$project_name'. The update script is "
      #   append sw_persona_msg "'$post_sys_link_tcl'. The update script was delivered as "
      #   append sw_persona_msg "part of the hardware platform."
      #   OPTRACE "Sourcing hardware platform $hook_name Tcl script" END
      #   log_exception $vivado_output_dir $sw_persona_msg $result $return_options_dict
      # }
      set optrace_task "Source hardware platform $hook_name Tcl script"
      set sw_persona_msg "Failed to update block diagram in project required for hardware synthesis. \
                         The project is '$project_name'. The update script is '$post_sys_link_tcl'. \
                         The update script was delivered as part of the hardware platform."
      run_cmd "source $post_sys_link_tcl"

      # this generates a xdc file _post_sys_link_gen_constrs.xdc

      # bd validation is not needed here. sourcing a post-sys-link tcl hook *could* change the bd, in 
      # which case, it is hw_platform developer's responsibility to call validation in that tcl hook

      set post_sys_link_gen_xdc "_post_sys_link_gen_constrs.xdc"
      if { ![file exists $post_sys_link_gen_xdc] } {
        puts "WARNING: the output of $post_sys_link_gen_xdc doesn't exist - $post_sys_link_gen_xdc"
      } else {
        # move the file to vivado_output_dir
        if { ![file exists $vivado_output_dir/$post_sys_link_gen_xdc] } {
          file rename $post_sys_link_gen_xdc $vivado_output_dir
        }
      }
      # OPTRACE "Sourcing hardware platform $hook_name Tcl script" END
    }

    if { ![string equal $user_post_sys_link_tcl ""] && [file exists $user_post_sys_link_tcl] } {
      OPTRACE "Validate BD" START
      add_to_steps_log $steps_log "internal step: validate_bd_design -force" [fileName]:[lineNumber [info frame]]
      validate_bd_design -force
      OPTRACE "Validate BD" END

      # OPTRACE "Sourcing user $hook_name Tcl script" START
      # add_to_steps_log $steps_log "internal step: source $user_post_sys_link_tcl" [fileName]:[lineNumber [info frame]]
      # if { [catch {source $user_post_sys_link_tcl} result return_options_dict] } {
      #   set sw_persona_msg "Failed to update block diagram in project required for hardware synthesis. "
      #   append sw_persona_msg "The project is '$project_name'. The user provided update script is "
      #   append sw_persona_msg "'$user_post_sys_link_tcl'. The script was provided using parameter "
      #   append sw_persona_msg "'$param_name'."
      #   OPTRACE "Sourcing user $hook_name Tcl script" END
      #   log_exception $vivado_output_dir $sw_persona_msg $result $return_options_dict
      # }
      # OPTRACE "Sourcing user $hook_name Tcl script" END
      set optrace_task "Source user $hook_name Tcl script"
      set sw_persona_msg "Failed to update block diagram in project required for hardware synthesis. \
                         The project is '$project_name'. The user provided update script is '$user_post_sys_link_tcl'.\
                         The script was provided using parameter '$param_name'."
      run_cmd "source $user_post_sys_link_tcl"
    }
  }

  ################################################################################
  # ip_cache_export_and_report
  #   utility function called by generate_target step
  #   Description: ip earch cache check and (optionally) generate ip cache report file
  #      
  #   Arguments:
  #      config_info 
  #      bd_file 
  ################################################################################
  proc ip_cache_export_and_report {config_info bd_file} {
    set no_ip_cache         [dict get $config_info no_ip_cache] 
    set ip_cache_report     [dict_get_default $config_info ip_cache_report {}]
    set steps_log           [dict get $config_info steps_log] 

    # ip early cache check (if an ip is already generated, this prevents an occ run to be created for that ip)
    if { !$no_ip_cache } { 
      add_to_steps_log $steps_log "internal step: config_ip_cache -export \[get_ips -all -of_object \[get_files $bd_file\]\]" [fileName]:[lineNumber [info frame]]
      catch {config_ip_cache -export [get_ips -all -of_object [get_files $bd_file]]}

      if { $ip_cache_report ne "" } {
        # Create a single file with all the information correctly formatted as JSON.
        # It would be nice to just have the ::debug::debug_cache_miss build the file,
        # but it only takes one IP at a time. And just appending to a file doesn't add
        # the JSON open and close braces, and separator commas needed. JSON is nice,
        # but not entirely flexible in its application. And this is probably slightly
        # more efficient since we aren't opening and closing the file repeatedly.
        set report_file [open $ip_cache_report "w"]
        puts $report_file "{ \"ips\": \["
        set first_entry true
        foreach file [get_files *.xci] { 
          if {$first_entry} {
            set first_entry false
          } else { 
            puts $report_file ","
          }
          set json_entry [::debug::debug_cache_miss $file -json]
          puts -nonewline $report_file $json_entry
        }
        puts $report_file ""
        puts $report_file "\] }"
      }
    }
  }

  ################################################################################
  # set_ip_repo_and_caching
  #   utility function called by create_bd step
  #   Description: set ip_repo_path and ip caching environment
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info 
  ################################################################################
  proc set_ip_repo_and_caching {hw_platform_info config_info} {
    set hw_platform_ip_repo     [dict get $hw_platform_info hw_platform_ip_repo] 
    set hw_platform_ip_cache    [dict get $hw_platform_info hw_platform_ip_cache] 
    set emu_user_ip_repo        [dict get $hw_platform_info emu_user_ip_repo] 

    set hw_platform_state       [dict get $hw_platform_info hw_platform_state]
    set contains_emu_dir        [dict get $hw_platform_info contains_emu_dir]
    set is_hw_emu               [dict get $config_info is_hw_emu] 
    set is_hw_emu_rebuild_flow  [dict get $config_info is_hw_emu_rebuild_flow]
    set user_ip_repo            [dict get $config_info user_ip_repo] 
    # set emu_user_ip_repo        [dict get $config_info emu_user_ip_repo] 
    set kernel_ip_dirs          [dict get $config_info kernel_ip_dirs] 
    set install_ip_cache        [dict get $config_info install_ip_cache] 
    set remote_ip_cache         [dict get $config_info remote_ip_cache] 
    set no_ip_cache             [dict get $config_info no_ip_cache] 
    set no_hw_platform_ip_cache [dict get $config_info no_hw_platform_ip_cache] 
    set no_install_ip_cache     [dict get $config_info no_install_ip_cache] 
    set ip_cache_report         [dict_get_default $config_info ip_cache_report {}]
    set steps_log               [dict get $config_info steps_log] 
    set emu_pfm_metadata_version  [dict get $hw_platform_info emu_pfm_metadata_version]

    OPTRACE "Create IP caching environment" START
    # construct ip_repo_paths with the order below (first one wins)
    #  1. User IP repo from --user_ip_repo_paths
    #  2. User emulation IP repo  -- hw_emu only 
    #     2.1 $::env(SDX_EM_REPO)) 
    #         Obsolete in Vitis, use --user_ip_repo_paths instead
    #     2.2 emu_user_ip_repo from hardware platform emu directory (see "USER_IP_REPO" in emu.xml)
    #  3. Kernel IP definitions (vpl --iprepo switch value)
    #  4. IP definitions stored inside hw_platform (IP_REPO_PATH)
    #     4.1 for hw, always set
    #     4.2 for hw_emu, set IF a platform state is pre_synth and xsa does not contain hw_emu/emu dir 
    #  5. IP cache dir from Install area (/proj/xbuilds/2019.2_daily_latest/installs/lin64/Vitis/2019.2/data/cache/xilinx)
    #  6. IP cache stored inside hw_platform (IP_CACHE_DIR) -- hw only
    #  7. $::env(XILINX_VITIS)/data/emulation/hw_em/ip_repo -- hw_emu only
    #  8. $::env(XILINX_VIVADO)/data/emulation/hw_em/ip_repo -- hw_emu only
    #  9. Vitis Specific Xilinx IP repo from install area (/proj/xbuilds/2019.2_daily_latest/installs/lin64/Vitis/2019.2/data/ip/)
    # 10. General Xilinx IP repo from install area (/proj/xbuilds/2018.2_daily_latest/installs/lin64/Vivado/2018.2/data/ip/)
    # note: 10 is automatically handled by IP Services as the final fallback, so we don't need to add it explicitly

    # 1. append the user ip repo
    if { $user_ip_repo ne "" } {
      lappend ip_repo_paths {*}$user_ip_repo 
    } 

    # 1.1. new style hw_emu platforms (is_hw_emu_rebuild_flow) need to append
    #      the local iprepo before the emu repo paths.
    if { $is_hw_emu_rebuild_flow && ![is_empty $hw_platform_ip_repo]} {
      lappend ip_repo_paths $hw_platform_ip_repo
    }

    # 1.2 Append the following IP repo. Recently Vitis_hls is enabled by default, and that resulted the change in the Alveo Platforms
    # that are developed until 2020.1 version. And we cannot change the older platforms, and we continue to support the Platform for 
    # next 1 year. And these IPs are obsolete will not be valid for 2020.2 and later platforms. Even the fix is applied in the IPs to 
    # support Vitis_hls, one should modify to the updated IPs when targetted the 2020.1 or older Alveo platforms. 
    # To reduce the burden for users and enable the older Alveo Platforms to support by default, adding the modified IPs directly by the Vitis tool
    if { $is_hw_emu } {
      if  {[file exists $::env(XILINX_VIVADO)/data/emulation/hw_em/ip_repo_ert_firmware ] } {
        lappend ip_repo_paths $::env(XILINX_VIVADO)/data/emulation/hw_em/ip_repo_ert_firmware
      }
    }

    # 2. append emulation ip repo from hw_platform -- hw_emu only
    #    SDX_EM_REPO is Obsolete in Vitis, use --user_ip_repo_paths instead
    if { $is_hw_emu && $emu_user_ip_repo ne "" } {
      lappend ip_repo_paths $emu_user_ip_repo
    }
    # 3. append kernel ip repo
    lappend ip_repo_paths {*}$kernel_ip_dirs
    # 4. append hw_platform ip repo
    if { $hw_platform_ip_repo ne "" } {
      if { !$is_hw_emu} {
        lappend ip_repo_paths $hw_platform_ip_repo 
      # hw_emu flow uses its own copy of these ip's from $(XILINX_VITIS)/data/emulation/hw_em/ip_repo. but if a platform state is pre_synth and xsa does not contain emu or hw_emu dir, hw_emu flow needs to set this.
      } elseif { $is_hw_emu && [string equal $hw_platform_state "pre_synth"] && [string equal $contains_emu_dir "false"] } {
        lappend ip_repo_paths $hw_platform_ip_repo 
      }
    }
    # 5. append xilinx ip cache dir from install area
    if { !$no_ip_cache && !$no_install_ip_cache && $install_ip_cache ne "" } {
      lappend ip_repo_paths $install_ip_cache 
    }
    # 6. append hw_platform ip cache -- hw_only
    # note: hw_platform ip cache dir is not even extracted, see HPICompilerUtils::extractPlatform
    if { !$no_ip_cache && !$no_hw_platform_ip_cache && $hw_platform_ip_cache ne "" && !$is_hw_emu } {
      lappend ip_repo_paths $hw_platform_ip_cache 
    }
    # for debug and profiling -- hw_emu only
    if { $is_hw_emu } {
	  
      # 7. append General xilinx emulation ip repo
      if { [info exists ::env(XILINX_VIVADO)] } {
        if { [file exists $::env(XILINX_VIVADO)/data/emulation/hw_em/ip_repo] } {
          lappend ip_repo_paths $::env(XILINX_VIVADO)/data/emulation/hw_em/ip_repo 
        }
      }

      # 8. append General xilinx emulation ip repo legacy for older platform created with 2019.2 and previous releases
      if { [info exists ::env(XILINX_VIVADO)] && $emu_pfm_metadata_version == "Legacy"} {
        if { [file exists $::env(XILINX_VIVADO)/data/emulation/hw_em/ip_repo_legacy] } {
          lappend ip_repo_paths $::env(XILINX_VIVADO)/data/emulation/hw_em/ip_repo_legacy
        }
      }
    }

    # 9. append Vitis Specific xilinx ip repo from install area
    if { [info exists ::env(XILINX_VITIS)] } {
      if { [file exists $::env(XILINX_VITIS)/data/ip] } { 
        lappend ip_repo_paths $::env(XILINX_VITIS)/data/ip
      }
    }

    if { $ip_repo_paths ne "" } {
      puts "INFO: \[OCL_UTIL\] setting ip_repo_paths: $ip_repo_paths"
      set_property ip_repo_paths $ip_repo_paths [current_project] 
      add_to_steps_log $steps_log "internal step: update_ip_catalog" [fileName]:[lineNumber [info frame]]
      update_ip_catalog
    }

    # ip caching
    if { $no_ip_cache || $is_hw_emu} { 
      add_to_steps_log $steps_log "internal step: config_ip_cache -disable_cache" [fileName]:[lineNumber [info frame]]
      config_ip_cache -disable_cache
    } else {
      if { $remote_ip_cache ne ""} {
        add_to_steps_log $steps_log "internal step: config_ip_cache -use_cache_location $remote_ip_cache" [fileName]:[lineNumber [info frame]]
        config_ip_cache -use_cache_location $remote_ip_cache
      } 
      # from nabeel: project level cache became default in 2016.3, no need
      # to explicitly call "config_ip_cache -use_project_cache" in else clause
    }

    #Based on the request from the Emulation team, we did set the property if the platform is 
    #pre_synth platform.
    #Disaling for now as it is causing issues with pre-synth platforms
    #if { [string equal $hw_platform_state "pre_synth"] && $is_hw_emu } {
    #  set_property preferred_sim_model "tlm" [current_project] 
    #}

    OPTRACE "Create IP caching environment" END
  }

  proc set_tlm_model_for_kernel_instances {hw_platform_info config_info} {
  
    set kernel_tlm_model_instances [dict get $config_info kernel_tlm_model_instances]
    set instances [get_bd_cells -quiet -hier -filter "SDX_KERNEL==true"]
    
    set tlm_instances_list [split ${kernel_tlm_model_instances} ","]    
    
    if {[lsearch $tlm_instances_list "all"] != -1} {
      foreach instance $instances {
        set_property SELECTED_SIM_MODEL tlm [get_bd_cells $instance]
      }
    } else {
      foreach instance $instances {
        set cu_name [file tail $instance]
        if {[lsearch $tlm_instances_list $cu_name] != -1} {
          set_property SELECTED_SIM_MODEL tlm [get_bd_cells $instance]
        }
      }
    }
  }

  ################################################################################
  # copy_ooc_xdc_files
  #   utility function called by generate_target step
  #   Description: Copy the OOC constraint files in BD, and add them to the top level 
  #      design in order for the clock constraints to be applied. For DFX (uses_pr) platforms,
  #      move the copied ooc.xdc to RM's fileset.
  #      
  #   Arguments:
  #      bd_file is_hw_emu kernel_clock_freqs 
  ################################################################################
  proc copy_ooc_xdc_files {bd_file kernel_clock_freqs config_info hw_platform_info} {
    set is_hw_emu           [dict get $config_info is_hw_emu]
    set reconfig_module     [dict get $config_info reconfig_module]
    set steps_log           [dict get $config_info steps_log]
    set vivado_output_dir   [dict get $config_info vivado_output_dir]
    set hw_platform_uses_pr [dict get $hw_platform_info hw_platform_uses_pr]

    set var [lineNumber [info frame]]
    set ooc_xdc_files [get_files -of_object [get_files $bd_file] -norecurse -filter { FILE_TYPE == "XDC" && USED_IN =~ "*out_of_context*" }]
    
    foreach ooc_xdc_file $ooc_xdc_files {
      if {![string equal $ooc_xdc_file ""] && [file exists $ooc_xdc_file]} {
        set used_in_value [get_property used_in $ooc_xdc_file]
        set xdc_file_copy "[file rootname [file tail $ooc_xdc_file]]_copy.xdc"
        set xdc_file_copy $vivado_output_dir/$xdc_file_copy
        # file copy $ooc_xdc_file ./$xdc_file_copy
        file copy -force $ooc_xdc_file $xdc_file_copy

        if { !$is_hw_emu } { 
          # create a kernel clock constraint for synthesis, and overwrite the default frequency from hw_platform
          add_to_steps_log $steps_log "internal step: writing user synth clock constraints in $xdc_file_copy" [fileName]:[expr [lineNumber [info frame]] + $var]
          write_user_synth_clock_constraint $xdc_file_copy $kernel_clock_freqs
        } 

        add_to_steps_log $steps_log "internal step: add_files $xdc_file_copy -fileset \[current_fileset -constrset\]" [fileName]:[expr [lineNumber [info frame]] + $var]
        set xdc_file_obj [add_files $xdc_file_copy -fileset [current_fileset -constrset]]
        if {$xdc_file_obj ne ""} {
          puts "INFO: \[OCL_UTIL\] set_property used_in $used_in_value $xdc_file_obj"
          set_property used_in $used_in_value $xdc_file_obj
          puts "INFO: \[OCL_UTIL\] set_property processing_order early $xdc_file_obj"
          set_property processing_order "early" $xdc_file_obj

          # CR-1074685, 1064987
          # DFX: move the ooc_copy.xdc to RM's fileset, and set processing order to late  
          #      because the original ooc.xdc from bd needs to be read first before ooc_copy.xdc.
          # get_reconfig_modules command requires that current project has a PR_FLOW property as true.
          # PR_FLOW is only set to true for hw flow and dfx platform
          set pr_flow [get_property PR_FLOW [current_project]]   
          if { $hw_platform_uses_pr && $pr_flow } {
            add_to_steps_log $steps_log "internal step: move_files \[get_files $xdc_file_obj\] -of_objects \[get_reconfig_modules $reconfig_module\] -quiet" [fileName]:[expr [lineNumber [info frame]] + $var]
            # TODO: add -quiet as a temporary solution for the following usecase
            # user runs v++ once with --to_step vpl.generate_target, then v++ --from_step vpl.generate_target
            # move_files would error out the second time since it couldn't move the file into fileset
            # which already contains the same file
            move_files [get_files $xdc_file_obj] -of_objects [get_reconfig_modules $reconfig_module] -quiet
            puts "INFO: \[OCL_UTIL\] set_property processing_order late $xdc_file_obj"
            set_property processing_order "late" $xdc_file_obj
          } 
        }
      }
    }
  }

  ################################################################################
  # write_address_map
  #   utility function called by update_bd step
  #   Description: write the address_map.xml file
  #      
  #   Arguments:
  #      vpl_output_dir
  ################################################################################
  proc write_address_map { vpl_output_dir } {
    # Note: there is already an open bd design

    # create Address Map file
    set xml_file $vpl_output_dir/address_map.xml
    set fp [open $xml_file w] 
    set addr_segs [get_bd_addr_segs -hier]
    # puts "--- DEBUG: current_bd_design: [current_bd_design]"
    # puts "--- DEBUG: addr_segs is $addr_segs"
    puts $fp "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    puts $fp "<xd:addressMap xmlns:xd=\"http://www.xilinx.com/xd\">"
    foreach addr_seg $addr_segs {
      set path [get_property PATH $addr_seg]
      set offset [get_property OFFSET $addr_seg]
      # puts "--- DEBUG: addr_seg: $addr_seg\n\tpath: $path\n\toffset: $offset"
      if {$offset != ""} {
        set range [format 0x%X [get_property RANGE $addr_seg]]
        set high_addr [format 0x%X [expr $offset + $range - 1]]
        set slave [get_bd_addr_segs -of_object $addr_seg]

        if { [regexp {^/(.+)/([^/]+)/([^/]+)$} $path match componentRef addressSpace segment] } {

        } elseif { [regexp {([^/]+)/([^/]+)$} $path match addressSpace segment] }  {
          # In this case, address space is an external interface. For now, 
          # just use addressSpace as componentRef
          set componentRef $addressSpace
        } else {
          puts "warning: path doesn't match the regular expression ($path)"
          continue
        }

        if { [regexp {^/(.+)/([^/]+)/([^/]+)$} $slave match slaveRef slaveMemoryMap slaveSegment] } {
          set slaveIntfPin [get_bd_intf_pins -of_objects $slave]                      
        
        } elseif { [regexp {/([^/]+)/([^/]+)$} $slave match slaveMemoryMap slaveSegment] }  {
          # In this case, address segement is an external interface.
          set slaveIntfPin [get_bd_intf_ports -of_objects $slave]                      
          set slaveRef $slaveMemoryMap
        } else {
           puts "warning: slave doesn't match the regular expression ($slave)"
           continue
        }
        # set slaveIntfPin [get_bd_intf_pins -of_objects $slave]

        if { ![regexp {([^/]+)$} $slaveIntfPin match slaveInterface] } {
          puts "warning: slaveIntfPin doesn't match the regular expression ($slaveIntfPin)"
          continue
        }

        puts $fp "  <xd:addressRange xd:componentRef=\"${componentRef}\" xd:addressSpace=\"${addressSpace}\" xd:segment=\"${segment}\" xd:slaveRef=\"${slaveRef}\"\
xd:slaveInterface=\"${slaveInterface}\" xd:slaveSegment=\"${slaveSegment}\" xd:baseAddr=\"${offset}\" xd:range=\"${range}\"/>" 
      } 
    } 
    puts $fp "</xd:addressMap>"
    close $fp
  }

  ################################################################################
  # create_bitstreams_without_implementation
  # utility function called by interactive step
  #   Description: open the implemented checkpoint and run through bitstream
  #      
  #   Arguments:
  #      hw_platform_info
  #      config_info 
  ################################################################################
  # used by --reuse_impl
  proc create_bitstreams_without_implementation { hw_platform_info config_info clk_info } {
    set hw_platform_uses_pr [dict get $hw_platform_info hw_platform_uses_pr]
    set ocl_inst_path       [dict get $hw_platform_info ocl_region]
    set link_output_format  [dict get $hw_platform_info link_output_format]
    set design_name         [dict get $config_info design_name]
    set out_partial_bit     [dict get $config_info out_partial_bitstream]
    set out_full_bit        [dict get $config_info out_full_bitstream]
    set out_partial_pdi     [dict get $config_info out_partial_pdi]
    set out_full_pdi        [dict get $config_info out_full_pdi] 
    set steps_log           [dict get $config_info steps_log] 
    set reuse_impl_dcp      [dict get $config_info reuse_impl_dcp] 
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set vpl_output_dir      [dict get $config_info vpl_output_dir] 
    set clbinary_name       [dict get $config_info clbinary_name]
    set is_hw_export        [dict get $config_info is_hw_export]

    set cwd [pwd]
    # puts "debug: cwd is $cwd; reuse_impl_dcp is $reuse_impl_dcp"

    # open reuse_impl_dcp and run write_bistream
    # open_checkpoint creates a diskless project
    add_to_steps_log $steps_log "internal step: open_checkpoint $reuse_impl_dcp" [fileName]:[lineNumber [info frame]]
    open_checkpoint $reuse_impl_dcp

    # Make sure the part in the checkpoint matches the part in the project.
    set hw_platform_part [dict get $hw_platform_info hw_platform_part]
    set dcp_part [get_property part [current_design]]
    if {[string compare -nocase $hw_platform_part $dcp_part] != 0} {
      puts "ERROR: The supplied design '$reuse_impl_dcp' with part '$dcp_part' does not match the project part '$hw_platform_part'. Please supply a design with the appropriate part when using the --reuse_impl option."
      add_to_steps_log $steps_log "status: fail" [fileName]:[lineNumber [info frame]]
      error2file $vivado_output_dir "improper dcp supplied (part mismatch)"
    }

    # Make sure the design is fully routed
    if { ![report_route_status -boolean_check ROUTED_FULLY] } {
      puts "ERROR: The supplied design '$reuse_impl_dcp' is not fully routed. Please supply a routed design when using the --reuse_impl option."
      add_to_steps_log $steps_log "status: fail" [fileName]:[lineNumber [info frame]]
      error2file $vivado_output_dir "improper dcp supplied (not routed)"
    }

    # timing check and frequency scaling
    set is_in_run false
    if { ![report_timing_and_scale_freq $ocl_inst_path $design_name $vivado_output_dir $vpl_output_dir $clk_info $clbinary_name $is_in_run] } {
      return false
    }

    # the call above geneates _new_clk_freq in current working directory _x/link/vivado/vpl
    # it needs to be copied to vpl outut dir
    set clk_freq_file [glob -nocomplain "./_new_clk_freq"]
    if {$clk_freq_file ne ""} {
      # puts "debug: copy $clk_freq_file to $vpl_output_dir"
      catch {file copy -force $clk_freq_file $vpl_output_dir}
    }

    # to disable the generation of webtalk files (e.g. usage_statistics_webtalk.xml)
    # we want to keep the vivado directory as clean as possible
    config_webtalk -user off

    set out_bit $out_full_bit
    set out_pdi $out_full_pdi
    set cell_switch ""
    if { $hw_platform_uses_pr } {
      set out_bit $out_partial_bit
      set out_pdi $out_partial_pdi
      set cell_switch "-cell $ocl_inst_path"
    }

    # we assume the dcp user passed in is the "last" dcp before write_bitstream
    # we don't consider the usecase where user pass in a routed dcp, but
    # expect us to generate post_route_phys_opt dcp if that step is enabled
    if { [has_output_format $link_output_format "dcp"] } {
      # copy the dcp file to int directory
      set out_routed_dcp "$vpl_output_dir/routed.dcp"
      puts "INFO: \[OCL_UTIL\] copy -force $reuse_impl_dcp $out_routed_dcp"
      file copy -force $reuse_impl_dcp $out_routed_dcp
    }

    if { [has_output_format $link_output_format "pdi"] } {
      if { $hw_platform_uses_pr && $is_hw_export } {
        # generate the full pdi to be used by write_hw_platform when usesPR=true
        add_to_steps_log $steps_log "internal step: write_device_image -no_partial_pdifile -force $out_full_pdi" [fileName]:[lineNumber [info frame]]
        write_device_image -no_partial_pdifile -force $out_full_pdi
      }
      # generate either partial pdi (usesPR=true) or full pdi (usesPR=false)
      add_to_steps_log $steps_log "internal step: write_device_image $cell_switch -force $out_pdi" [fileName]:[lineNumber [info frame]]
      write_device_image {*}$cell_switch -force $out_pdi
    } elseif { [has_output_format $link_output_format "bitstream"] } {
      # link_output_format = bitstream
      if { $hw_platform_uses_pr && $is_hw_export } {
        # generate the full bit to be used by write_hw_platform when usesPR=true
        add_to_steps_log $steps_log "internal step: write_bitstream -no_partial_bitfile -force $out_full_bit" [fileName]:[lineNumber [info frame]]
        write_bitstream -no_partial_bitfile -force $out_full_bit
      } 
      # generate either partial bit (usesPR=true) or full bit (usesPR=false)
      add_to_steps_log $steps_log "internal step: write_bitstream $cell_switch -force $out_bit" [fileName]:[lineNumber [info frame]]
      write_bitstream {*}$cell_switch -force $out_bit
    }

    # hw_export suport - generate fixed platform
    # note: we can't use launch_runs in diskless project 
    # TODO: consider changing this tcl proc to open the existing vivado project
    #       and then launch_runs -to_step write_bitstream
    #       but in this case, user has to make sure the routed dcp is generated
    #       inside the impl run directory
    # TODO: what to do if link_output_format=dcp?
    if {$is_hw_export} {
      if { [has_output_format $link_output_format "pdi"] } {
        puts "hw_export: set_property platform.full_pdi_file $out_full_pdi \[current_project\]" 
        set_property platform.full_pdi_file $out_full_pdi [current_project]
      } elseif { [has_output_format $link_output_format "bitstream"] }  {
        puts "hw_export: set_property platform.full_bit_file $out_full_bit \[current_project\]" 
        set_property platform.full_bit_file $out_full_bit [current_project]
      }
      generate_fixed_hw_platform $hw_platform_info $config_info false
    }
  }

  # used to add synth_constrs and impl_constrs files in hw_platform
  proc add_xdc_files {xdc_dict steps_log} { 
    set var [lineNumber [info frame]] 
    foreach xdc_name [dict keys $xdc_dict] {
      set xdc_info [dict get $xdc_dict $xdc_name]
      set file_path [dict get $xdc_info file_path]
      set used_in [dict get $xdc_info used_in]
      set processing_order [dict get $xdc_info processing_order]
  
      if { [string equal $file_path ""] || ![file exists $file_path] } {
        continue;
      }

      add_to_steps_log $steps_log "internal step: add_files $file_path -fileset \[current_fileset -constrset\]" [fileName]:[expr [lineNumber [info frame]] + $var]
      add_files $file_path -fileset [current_fileset -constrset]
      if {$used_in ne ""} {
        puts "INFO: \[OCL_UTIL\] set_property USED_IN \"$used_in\" \[get_files $file_path\]"
        set_property USED_IN $used_in [get_files $file_path]
      }
      if {$processing_order ne ""} {
        puts "INFO: \[OCL_UTIL\] set_property PROCESSING_ORDER \"$processing_order\" \[get_files $file_path\]"
        set_property PROCESSING_ORDER $processing_order [get_files $file_path]
      }
    }
  }

  proc enable_incr_hw_emu {hw_platform_info config_info} {
    set steps_log              [dict get $config_info steps_log] 
    set is_incr_hw_emu         [dict get $config_info is_incr_hw_emu] 

    if {$is_incr_hw_emu} { 
      # get all the bds from the project
      # set bd_files [get_files *.bd]
      set bd_file [get_bd_file $hw_platform_info $config_info]
      # puts "bd_file: '$bd_file'"

      add_to_steps_log $steps_log "internal step: reimport_files" [extFileName]:[expr {[dict get [info frame -1] line] + [dict get [info frame 0] line]}]
      reimport_files 
      # for debug only, if we want to see what files have been re-imported
      # set reimported_files [reimport_files] 
      # puts "reimported_files: $reimported_files"
    
      # open_bd_design
      # add_to_steps_log $steps_log "internal step: open_bd_design -auto_upgrade \[get_files $bd_file\]" [extFileName]:[expr {[dict get [info frame -1] line] + [dict get [info frame 0] line]}]
      # open_bd_design -auto_upgrade [get_files $bd_file]

      add_to_steps_log $steps_log "internal step: generate_target simulation \[get_files $bd_file\]" [extFileName]:[expr {[dict get [info frame -1] line] + [dict get [info frame 0] line]}]
      generate_target simulation [get_files $bd_file]
    }
  }

  ################################################################################
  # generate_kernel_inst_path_data
  #   utility function called by config_simualtion step for hw_emu flow
  #   Description: write the _kernel_inst_paths.dat and kernel_service.json file
  #      
  #   Arguments:
  #      config_info
  ################################################################################
  # proc generate_kernel_inst_path_data {steps_log vpl_output_dir} 
  proc generate_kernel_inst_path_data {config_info} { 
    set steps_log       [dict get $config_info steps_log] 
    set vpl_output_dir  [dict get $config_info vpl_output_dir] 
    set dr_bd           [dict get $config_info dr_bd] 
    # set top_bd          [dict get $config_info top_bd] 
    set dr_bd_inst_path [dict get $config_info dr_bd_inst_path] 

    # Note: inst_path for EMU_DR_BD is introduced in 2020.1, if 
    #    this entry exist, we should use it as the dr bd inst path
    # hw_emu.json looks like the following
    # {
    #   "type": "EMU_DR_BD",
    #   "name": "pfm_dynamic/pfm_dynamic.bd",
    #   "inst_path": "emu_wrapper/emu_i/dynamic_region"
    # },
    # Note: this entry may not exist in older platforms, in which case
    #   we should figure it out by looking up the instance name of the
    #   dr bd.

    # note: this file is used by rtdgen, see HPIRtdGen::execHwEmu_simple
    add_to_steps_log $steps_log "internal step: creating $vpl_output_dir/_kernel_inst_paths.dat" [fileName]:[lineNumber [info frame]]
    set outfile [open "$vpl_output_dir/_kernel_inst_paths.dat" w]
    puts $outfile "# This file was automatically generated by Vpl"
    puts $outfile "version: 1.0"

    # top bd is already open at this point, verify with get_bd_design or current_bd_design
    # puts "--- DEBUG: current_bd_design:\n[join [current_bd_design] \n]"

    # two BD usecae
    # when targeting a 2RP platform the open BD design is the top level BD which does not 
    # contain any kernels. the kernels exist inside the dynamic BD portion, which is a 
    # separate bd that has to be opened before it can be traversed.
    
    # for one BD usecase, dr_bd is same as top_bd
    # for two BD usecase, dr_bd is different from top_bd
    # puts "--- DEBUG: dr_bd is $dr_bd"

    # get the basename of $dr_bd ( <basename>.bd )
    set dr_bd_name [file rootname $dr_bd]
    # puts "--- DEBUG: dr_bd_name is $dr_bd_name"
    
    set top_bd_name [get_property name [current_bd_design]]
    # puts "--- DEBUG: top_bd_name $top_bd_name"

    set resolved_dr_bd_inst_path $dr_bd_inst_path
    # If dr_bd is empty, set resolved_dr_bd_inst_path using only top_bd_name.
    # The dr_bd could be empty if the platform is pre_synth, e.g. zcu102.
    if {$dr_bd_name ne "" && $dr_bd_name ne $top_bd_name} {
      # two BD usecase
      if {$resolved_dr_bd_inst_path eq ""} {
        # in the two BD usecase, the dr bd itself is a bd cell in the top bd,
        # the instance name doesn't always match the dr bd base name, we need
        # to find out the instance name given a dr bd name (module name)
        # important: this must be done before open the dr bd
        set dr_bd_inst $dr_bd_name
        # without -hier, get_bd_cells returns the top level bd cells
        set top_level_bd_cells [get_bd_cells -quiet]
        # top_elvel_bd_cells include dynamic region and static region
        foreach bd_cell $top_level_bd_cells {
          # check the VLNV value of each bd cell
          set vlnv [get_property VLNV $bd_cell]
          # puts "2bd $bd_cell : vlnv is $vlnv"
          # we are only interested in the "name" portion, this should match
          # match the dr bd name
          set vlnv_list [split $vlnv ":"]
          set name [lindex $vlnv_list 2]
          # puts "2bd $name : $dr_bd_name"
          if {$name == $dr_bd_name} {
            set dr_bd_inst [get_property NAME $bd_cell]
          }
        }
        set resolved_dr_bd_inst_path "/${top_bd_name}_wrapper/${top_bd_name}_i/${dr_bd_inst}"
        # puts "--- DEBUG: 2bd resolved_dr_bd_inst_path is $resolved_dr_bd_inst_path"
      } else {
        # CR-1092777: if dr_bd_inst_path is already set and does not have a 
        # leading '/', pre-pend '/'
        if { [string first "/" $resolved_dr_bd_inst_path] != 0 } { 
          set resolved_dr_bd_inst_path "/${resolved_dr_bd_inst_path}"
        } 
        # puts "--- DEBUG: 2bd resolved_dr_bd_inst_path is $resolved_dr_bd_inst_path" 
      }

      # open the dynamic BD
      puts "INFO: \[OCL_UTIL\] open_bd_design \[get_files $dr_bd\]"
      if { [catch {open_bd_design [get_files $dr_bd]} catch_res] } {
        puts "WARNING: problem opening the dynamic BD $dr_bd, failed to generate kernel inst path file: $catch_res"
        return 
      }

    } else {
      # one BD usecase
      # this could be pre_synth platform which has no "hw_emu" folder,
      #     in this case, dr_bd is empty
      # or dfx platform which has a "hw_emu" folder, but there is only one emu bd
      #     in this case, dr_bd == top_bd
      if {$resolved_dr_bd_inst_path eq ""} {
        set resolved_dr_bd_inst_path "/${top_bd_name}_wrapper/${top_bd_name}_i"
        #puts "--- DEBUG: 1bd resolved_dr_bd_inst_path is $resolved_dr_bd_inst_path"
      } else {
        # CR-1092777: if dr_bd_inst_path is already set and does not have a
        # leading '/', pre-pend '/'
        if { [string first "/" $resolved_dr_bd_inst_path] != 0 } { 
          set resolved_dr_bd_inst_path "/${resolved_dr_bd_inst_path}"
        }
        # puts "--- DEBUG: 1bd resolved_dr_bd_inst_path is $resolved_dr_bd_inst_path" 
      } 
    }

    # dr bd should be opened at this point, verify
    # puts "--- DEBUG: current_bd_design:\n[join [current_bd_design] \n]"

    set instances [get_bd_cells -quiet -hier -filter "SDX_KERNEL==true"]
    # puts "--- DEBUG: bd cells: $instances:"
    foreach instance $instances {
      # $instance returns "/OCL_Region_0/adder_stage_cu0"
      # we need to prepend the wrapper and bd name
      #
      # puts "--- DEBUG: instance properties:"
      # report_property $instance
      
      # get the ip component name (xilinx.com:hls:vadd:1.0)
      set vlnv [get_property VLNV $instance]
      # we are only interested in the "name" portion (i.e. kernel name)
      set vlnv_list [split $vlnv ":"]
      set kernel_name [lindex $vlnv_list 2]
      set kernel_type [get_property SDX_KERNEL_TYPE $instance]
      # puts "--- DEBUG: bd cell: $instance; kernel_type: $kernel_type"

      # get ip instance name in sim netlist (CR-1081216)
      # 1. get top ip wrapper name
      # 2. get top ip wrapper simulation file
      # 3. ip instance name depends on the file extension
      # - "inst" if verilog
      # - "U0" if vhdl
      set sim_instance_name ""
      set top_wrapper_name [get_property CONFIG.Component_Name $instance]
      if {$top_wrapper_name ne ""} {
        set wrapper_filter "NAME =~ *sim/${top_wrapper_name}.v*"
        set wrapper_files [get_files -of_objects [get_filesets sources_1] -filter $wrapper_filter]
        if { [llength $wrapper_files] > 0 } {
          set file_extension [file extension [lindex $wrapper_files 0]]
          if {$file_extension eq ".v"} {
            set sim_instance_name "inst"
          } elseif {$file_extension eq ".vhd"} {
            set sim_instance_name "U0"
          } 
        }
      }

      # note $instance already has a "/" in front
      set instance "${resolved_dr_bd_inst_path}${instance}"
      puts $outfile "$kernel_name:"
      puts $outfile "   instance path: $instance"
      puts $outfile "   type: $kernel_type"

      # the compute unit name is simply the last element of $instance
      set cu_name [file tail $instance]
      # puts "upsert_compute_unit: cu_name is $cu_name; instance is $instance"
      if { [ catch { ::kernel_service::upsert_compute_unit $cu_name -kernel_name $kernel_name -instance $instance -sim_instance_name $sim_instance_name } results ] } {
        puts "CRITICAL WARNING: Kernel service failed to update compute unit $cu_name with instance path: $results"
      }
    }

    close $outfile

    # Write out a snapshot of the kernel service information to vpl output dir
    # _x/link/int, $vpl_output_dir is a full path
    set ks_output $vpl_output_dir/kernel_service.json
    if { [ catch { ::kernel_service::write_data $ks_output } results ] } {
      puts "CRITICAL WARNING: Kernel service failed to write file $ks_output: $results"
    }

  }

  ################################################################################
  # check_synth_runs_status
  # utility function called by tcl proc run_synthesis
  #   Description: log generated synthesis report files and check the synthesis runs status
  #      
  #   Arguments:
  #      steps_log vivado_output_dir
  #   
  #   return false if any run fails
  ################################################################################
  proc check_synth_runs_status { steps_log vivado_output_dir} {
    # upvar $err_str _err_str

    # capture synth reports
    set generated_reports_log [file join $vivado_output_dir "generated_reports.log"]
    set report_synth_runs [get_runs -filter {IS_SYNTHESIS==1}]
    add_to_steps_log $steps_log "internal step: log_generated_reports for synthesis '${generated_reports_log}'" [fileName]:[lineNumber [info frame]]
    log_generated_reports $generated_reports_log $report_synth_runs

    # check for any run failure
    # and write the "cookie file" for Dennis' messaging support
    set any_run_not_done false
    set runs [get_runs -filter {IS_SYNTHESIS == 1}]
    # puts "--- DEBUG: get_filesets: [get_filesets]"
    set var [lineNumber [info frame]]

    foreach _run $runs {
      set run_name [get_property NAME $_run]
      # puts "--- DEBUG: run: $run_name"
      set run_status [get_property STATUS $_run]
      set run_dir [get_property DIRECTORY $_run]
      set run_fileset [get_property SRCSET $_run]
      # puts "--- DEBUG: run_fileset: $run_fileset"

      # having a run returned by get_runs does NOT guarantee the run dir would exist
      if { ![file exists $run_dir] } {
        puts "INFO: \[OCL_UTIL\] the run directory for run '$run_name' doesn't exist"
        continue;
      }
      #info frame returns line number of current stack inside foreach loop. So adding the line numbers to get current line number
      add_to_steps_log $steps_log "internal step: launched run $run_name" [fileName]:[expr [lineNumber [info frame]] + $var]

      # generate the cookie file for Dennis' messaging support
      set cookie_file $run_dir/.runmsg.txt
      set outfile [open $cookie_file w]
      
      # single project flow, the "top" level synthesis run is not synth_1, it is <rm>_synth_1
      # it is associated with reconfig module
      set fs_obj [get_filesets $run_fileset]
      # puts "--- DEBUG: fs_obj is '$fs_obj'"
      if { $fs_obj == "" } {
        # this fileset is associated with reconfig module, get_filesets without -of_object returns empty
        puts $outfile "Compiling (reconfig module level synthesis checkpoint) dynamic region"
      } elseif { [string equal $run_name "synth_1"] } {
        # TODO: hard-coded "synth_1
        puts $outfile "Compiling (top level synthesis checkpoint) dynamic region"
      } else {
        set ip_file [get_files -norecurse -of_objects $fs_obj]
        if {![is_empty $ip_file]} {
          # puts "--- DEBUG: ip_file: $ip_file"
          # ip_top is only applicable to ip file type
          set file_type [get_property FILE_TYPE $ip_file]
          set ip_top ""
          if { [string equal -nocase $file_type "ip"] } {
            set ip_top [get_property IP_TOP $ip_file] 
            # puts "--- DEBUG: ip_top: $ip_top"
          }
        }
        puts $outfile "Compiling (synthesis checkpoint) kernel/IP: $ip_top"
      }
      puts $outfile "Log file: $run_dir/runme.log"
      close $outfile

      # puts "--- DEBUG: run '$_run' has status '$run_status'"
      if { [string equal $run_status "synth_design ERROR"] } {
        puts "ERROR: run '$_run' failed, please look at the run log file '$run_dir/runme.log' for more information"
        append _err_str "\nrun '$_run' failed, please look at the run log file '$run_dir/runme.log' for more information"
        add_to_steps_log $steps_log "status: fail" [fileName]:[expr [lineNumber [info frame]] + $var]
        add_to_steps_log $steps_log "log: $run_dir/runme.log" [fileName]:[expr [lineNumber [info frame]] + $var]
        set any_run_not_done true
      }
      if { [string equal $run_status "Scripts Generated"] } {
        puts "ERROR: run '$_run' couldn't start because one or more of the prerequisite runs failed"
        append _err_str "\nrun '$_run' couldn't start because one or more of the prerequisite runs failed"
        set any_run_not_done true
      }
    }

    if {$any_run_not_done} {
      error2file $vivado_output_dir "One or more synthesis runs failed during dynamic region dcp generation $_err_str"
      # return false
    }

    # return true
  }

  proc write_utilization_drc { config_info hw_platform_info outfile } {
    set enable_util_report  [dict get $config_info enable_util_report] 
    # enable_util_report is a boolean, true or false, the string length is always > 0
    # if { [string length $enable_util_report] eq 0 } 
    if { !$enable_util_report } {
      puts "INFO: post-synthesis utilization DRC check skipped"
      return
    }

    # set xpfm_file     [dict get $hw_platform_info xpfm_file]
    set ocl_inst_path [dict get $hw_platform_info ocl_region]
    set utilization   [dict get $hw_platform_info utilization] 
    set threshold     [dict get $config_info utilization_threshold] 
    set steps_log     [dict get $config_info steps_log] 
    set vivado_output_dir  [dict get $config_info vivado_output_dir] 

    # ocl_inst_path may be empty for SoC platforms
    puts $outfile "ocl_util::report_utilization_drc \"$utilization\" \"$ocl_inst_path\" $threshold \$steps_log \$vivado_output_dir"
  }

  ################################################################################
  # after open_bd_design report on the status of the IPs.
  #
  # Look for all the IPs and get the locked status property on the
  # vivado netlist. The rule is in the ocl_rules.cfg file.
  ################################################################################
  proc report_ips_drc { config_info } {
    set vivado_output_dir   [dict get $config_info vivado_output_dir] 
    set local_dir           [dict get $config_info local_dir] 
    set vpl_output_dir      [dict get $config_info vpl_output_dir] 
    set steps_log           [dict get $config_info steps_log] 
    set project_name        [dict get $config_info proj_name] 
    set design_name         [dict get $config_info design_name]

    set all_kernel_ips [get_ips -quiet -all]
    set size_all_ips [llength $all_kernel_ips]
    set txt_fname link_ip_guidance.txt

    if { $size_all_ips > 0 } {
      foreach kernel_ip $all_kernel_ips {
        set lockstatus   [get_property IS_LOCKED $kernel_ip]
        set lockdetails  [get_property LOCK_DETAILS $kernel_ip]

        if { $lockstatus == 1 } {
          warning2file $vivado_output_dir "WARNING: IP $kernel_ip is locked. Locked reason: $lockdetails."
          if {[is_drcv]} { 
            report_ip_status -quiet -file $txt_fname 
            set current_dir [pwd]
            set guidance_file [ file normalize "$current_dir/$txt_fname" ]
            set report_ip_ref [::drcv::create_reference FILE -name "report_ip_status" -url "file:///$guidance_file"]
            set resolution_msg "Check the IP and the install area for the latest version of the IPs. For additional information about designing with IP - refer to %URI. In vivado you can run the report_ip_status Tcl command for additional information. In addition, %REF the can be viewed.";

            ::drcv::create_violation IP-LOCK-01 -s $project_name -s $design_name -s $kernel_ip -s $lockdetails -resolution $resolution_msg -URI UG896 www.xilinx.com/support/documentation/sw_manuals/xilinx2019_2/ug896-vivado-ip.pdf -REF $report_ip_ref
            # a create_violation that uses the rule spec.
            # not using - use the override resoltuion message feature
            # keep here just for possibe future reference.
            # ::drcv::create_violation IP-LOCK-01 -s $project_name -s $design_name -s $kernel_ip -s $lockdetails 
          }
        }
      }
      add_to_steps_log $steps_log "internal step: report locked IPs" [fileName]:[lineNumber [info frame]] 
    }
  }

  # check utilization of the device and report problems
  # this is done as part of pre tcl hook for opt_design
  proc report_utilization_drc { utilization ocl_inst_path threshold steps_log output_dir } {
    
    # Get resources available from the hw_platform
    # the available resource data is already captured in ipirun.tcl
    # no need to get them again
    set availluts      [dict get $utilization luts]
    set availregisters [dict get $utilization registers]
    set availbrams     [dict get $utilization brams]
    set availdsps      [dict get $utilization dsps]

    set cwd [pwd]

    puts "Post-synthesis utilization DRC check..."
    puts "available resources:" 
    puts "   luts      : $availluts"
    puts "   registers : $availregisters"
    puts "   brams     : $availbrams"
    puts "   dsps      : $availdsps"

    # get the utilization numbers for dynamic region
    # The following would include platform logic
    # puts "utilization: [get_utilization]"
    set cells {}
    if {$ocl_inst_path ne ""} {
      set cells [get_cells $ocl_inst_path]
    }
    if {[llength $cells] eq 0} {
      # Couldn't find the dynamic region (SoC platform?), so look for kernels
      set cells [get_cells -hier -filter SDX_KERNEL==true]
      if {[llength $cells] eq 0} {
        puts "WARNING: Could not find any kernels, nor the dynamic region, in the design. Utilization DRC skipped."
        return
      }
    }
    set ocl_utils [get_utilization -cells $cells]

    # Compare the utilization with ones from hw_platform
    # First set values to 0, in case the utilization doesn't report any.
    set luts 0
    set registers 0
    set brams 0
    set dsps 0
    foreach util $ocl_utils {
      # puts "demand utilization is $util"
      set utilspec [split $util ":"]
      # puts "[lindex $utilspec 0] [lindex $utilspec 1] [lindex $utilspec 2]"
      if {[string equal -nocase [lindex $utilspec 0] "LUT"]} {
        set luts [lindex $utilspec 1]
      }
      if {[string equal -nocase [lindex $utilspec 0] "REG"]} {
        set registers [lindex $utilspec 1]
      }
      if {[string equal -nocase [lindex $utilspec 0] "BRAM"]} {
        set brams [lindex $utilspec 1]
      }
      if {[string equal -nocase [lindex $utilspec 0] "DSP"]} {
        set dsps [lindex $utilspec 1]
      }
    } 
    puts "required resources:"
    puts "   luts      : $luts"
    puts "   registers : $registers"
    puts "   brams     : $brams"
    puts "   dsps      : $dsps"
    
    # if hw_platform doesn't contains utilization data, the avilable resource number would be set to -1
    if { $availluts == -1 || $availregisters == -1 || $availbrams == -1 || $availbrams == -1 } {
      puts "WARNING: There is no resource utilization data in hardware platform, utilization DRC is skipped"
    }

    if { $availluts != -1 && $luts >= $threshold * $availluts} {
      warning2file $output_dir "CRITICAL WARNING: The available LUTs may not be sufficient to accommodate the kernels"
      if {[is_drcv]} { ::drcv::create_violation ACCELERATOR-FIT-04 -d $luts -d $availluts -f $threshold }
    }
    if { $availregisters != -1 && $registers >= $threshold * $availregisters} {
      warning2file $output_dir "CRITICAL WARNING: The available Registers may not be sufficient to accommodate the kernels"
      if {[is_drcv]} { ::drcv::create_violation ACCELERATOR-FIT-03 -d $registers -d $availregisters -f $threshold }
    }
    if { $availbrams != -1 && $brams >= $threshold * $availbrams} {
      warning2file $output_dir "CRITICAL WARNING: The available BRAMs may not be sufficient to accommodate the kernels"
      if {[is_drcv]} { ::drcv::create_violation ACCELERATOR-FIT-02 -f $brams -f $availbrams -f $threshold }
    }
    if { $availdsps != -1 && $dsps >= $threshold * $availdsps} {
      warning2file $output_dir "CRITICAL WARNING: The available DSPs may not be sufficient to accommodate the kernels"
      if {[is_drcv]} { ::drcv::create_violation ACCELERATOR-FIT-01 -d $dsps -d $availdsps -f $threshold }
    }
    
    # generate the utilization reports, one for each kernel
    set kernel_util_string ""
    # puts "--- DEBUG:  generating kernel utilization reports after dynamic region dcp synthesis"
    foreach kernel_inst [get_kernel_cells $ocl_inst_path] {
      if { ![string equal $kernel_inst ""] } {
        # puts "--- DEBUG: kernel instance is $kernel_inst"
        # report_property $kernel_inst
        # get the kernel name (for hls kernel, the orig_ref_name seems to be the kernel name) 
        set kernel [get_property ORIG_REF_NAME $kernel_inst]

        # vadd_cu0/inst
        set ki_split [split $kernel_inst "/"]
        # assume the second to the last element is the kernel instance name (i.e. "mmult_cu1")
        # this is not reliable, but couldn't figure out a better way
        set kernel_inst_base [lindex $ki_split end-1]

        set kernel_util_string "$kernel_util_string $kernel:$kernel_inst:$kernel_inst_base"
      }
    }

    if {$kernel_util_string ne ""} {
      # report_sdx_utilization is replace by report_accelerator_utilization
      # puts "INFO: \[OCL_UTIL\] report_accelerator_utilization -kernels \"$kernel_util_string\" -file \"kernel_util_synthed.rpt\" -name kernel_util_synthed"
      # note: report_accelerator_utilization generates rpt (text), xutil (pb) and json files
      report_accelerator_utilization -kernels "$kernel_util_string" -file "kernel_util_synthed.rpt" -name kernel_util_synthed -json
      # per Kreymer's request, add report_utilization call for post-synthesis
      # we dont' need to call report_utilization with -slr because it is only
      # after place_design that we know which SLR the primitives are in and thus
      # the utilization of the SLRs 
      report_utilization -file "full_util_synthed.rpt" -pb "full_util_synthed.pb"
      create_system_diagram_metadata "synthed" $output_dir
    }
  }

  ################################################################################
  # create_run_script_map_file
  # utility function called by config_hw_runs step
  #   Description: used for "--export_script"
  #      
  #   Arguments:
  ################################################################################
  proc create_run_script_map_file { run_type vpl_output_dir {kernels ""} } {
    # get all the kernels
    if { $kernels eq "" && [string equal $run_type "synth"] } {
      set instances [get_bd_cells -quiet -hier -filter "SDX_KERNEL==true"]
      # puts "--- DEBUG: bd cells: $instances:"
      if { [llength $instances] > 0 } { 
        foreach instance $instances {
          # $instance returns "/OCL_Region_0/adder_stage_cu0"
          # get the ip component name (xilinx.com:hls:vadd:1.0)
          set vlnv [get_property VLNV $instance]
          # we are only interested in the "name" portion
          set vlnv_list [split $vlnv ":"]
          set name [lindex $vlnv_list 2]
          lappend kernels $name
        }
      }
    }
    # puts "--- DEBUG: kernels: $kernels"

    # the cwd is "ipi"
    set file_exist [file exists "$vpl_output_dir/run_script_map.dat"]
    set outfile [open "$vpl_output_dir/run_script_map.dat" a+]
    
    # header
    if { !$file_exist} {
      puts $outfile "#"
      puts $outfile "# Run script mapping file created by Vpl"
      puts $outfile "#"
      puts $outfile "# This is the template file for user to use custom script feature"
      puts $outfile "# Format: <run name>: <custom script>"
      puts $outfile "# Usage:"
      puts $outfile "#   User can modify this file directly, to specify a custom script for a particular run,"
      puts $outfile "#   first find the entry below that matches the run name, uncomment it, replace the default"
      puts $outfile "#   run script with the *absolute* path to the custom script"
      puts $outfile "#   note: do NOT use the original (default) run script as the custom script"
      puts $outfile "# Note: if the custom script doesn't exist, it will be ignored by vivado"
    }

    # <run name> : <run driver script>
    if { [string equal $run_type "synth"] } { 
      set runs [get_runs -filter {IS_SYNTHESIS == 1}]
      puts $outfile ""
      puts $outfile "# ################"
      puts $outfile "# Synthesis runs"
      puts $outfile "# ################"
    } else {
      set runs [get_runs -filter {IS_IMPLEMENTATION == 1}]
      puts $outfile ""
      puts $outfile "# #################"
      puts $outfile "# Implmentation runs"
      puts $outfile "# #################"
    }

    # group the runs, list the kernel ooc runs first
    # for synthesis, there are three groups - top level, kernel ooc, other ip ooc
    set top_level ""
    set kernel_ooc ""
    set other_ooc ""

    foreach _run $runs {
      set run_name [get_property NAME [get_runs $_run]]
      # TODO: remove the hard-coding of "my_rm"
      if { [string equal $run_name "synth_1"] || 
           [string equal $run_name "my_rm_synth_1"] ||
           [string equal $run_name "impl_1"] } {
        lappend top_level $_run
        continue;
      } 
     
      set kernel_ooc_run_found false
      foreach _kernel $kernels {
        if { [string match "*_${_kernel}_*" $run_name] } {
          lappend kernel_ooc $_run
          set kernel_ooc_run_found true
          break;
        }
      }
      if { $kernel_ooc_run_found } {
        continue;
      }
      
      lappend other_ooc $_run
    }

    # top level runs, i.e. synth_1, my_rm_synth_1 or impl_1
    if { [llength $top_level] > 0 } {
      puts $outfile "#"
      puts $outfile "# top level runs"
      puts $outfile "# ---------------------------------------"
    }

    foreach _run $top_level {
      set run_dir [get_property DIRECTORY [get_runs $_run]]
      set run_name [get_property NAME [get_runs $_run]]
      # get the run driver script
      set run_script [glob -nocomplain "$run_dir/*.tcl"]

      puts $outfile ""
      puts $outfile "# $run_name: $run_script"
    }

    # kernel ooc runs
    if { [llength $kernel_ooc] > 0 } {
      puts $outfile "#"
      puts $outfile "# kernel ooc runs"
      puts $outfile "# ---------------------------------------"
    }

    foreach _run $kernel_ooc {
      set run_dir [get_property DIRECTORY [get_runs $_run]]
      set run_name [get_property NAME [get_runs $_run]]
      # get the run driver script
      set run_script [glob -nocomplain "$run_dir/*.tcl"]

      if { $run_script ne ""} { 
        puts $outfile ""
        puts $outfile "# $run_name: $run_script"
      }
    }

    # other ooc runs (supporting ips)
    if { [llength $other_ooc] > 0 } {
      puts $outfile "#"
      puts $outfile "# supporting ip ooc runs"
      puts $outfile "# ---------------------------------------"
    }

    foreach _run $other_ooc {
      set run_dir [get_property DIRECTORY [get_runs $_run]]
      set run_name [get_property NAME [get_runs $_run]]
      # get the run driver script
      set run_script [glob -nocomplain "$run_dir/*.tcl"]

      if { $run_script ne ""} { 
        puts $outfile ""
        puts $outfile "# $run_name: $run_script"
      }
    }

    close $outfile
  }
  
  proc lineNumber {frame_info} {
    set result [dict get [info frame $frame_info] line]
    return "$result"
  }
  
  proc fileName {} {
    set script_path [dict get [info frame 0] file] 
    return "$script_path"
  }
  
  proc extFileName {} {
    set script_path [ info script ]
    return "$script_path"
  }
  
  proc add_to_steps_log { steps_log content file_name {indent "   "} } {
    # this is not a fatal problem from flow's perspective, hence using WARNING
    if { [catch {set outfile [open $steps_log a+]} catch_res] } {
      puts "WARNING: problem opening file $steps_log: $catch_res"
    }

    # echo the message
    puts "INFO: \[OCL_UTIL\] $content"

    set tool_flow "VPL"
    if { [string match "internal step:*" $content] } {
      puts $outfile "${indent}-----------------------"
      puts $outfile "${indent}$tool_flow $content"
      puts $outfile "${indent}File: $file_name"
    
      # get current timestamp
      set systemTime [clock seconds]
      puts $outfile "${indent}timestamp: [clock format $systemTime -format {%d %B %Y %H:%M:%S}]"
    } else {
      puts $outfile "${indent}-----------------------"
      puts $outfile "  $content"
    }

    close $outfile
  }

  # -----------------------------------------------------------------------------
  # Returns list to pass to the logger (for steps log).
  #
  # Arguments:
  #   stepname: internal step to log
  #
  #   rel_info_frame (dict): Info for frame relative to the frame for the
  #   current command on the stack. Might contain further context for the log
  #
  #   info_frame_0 (dict): Info for a command on the stack.
  #
  #   Client can get the dictionary using Tcl command: [info frame ?number?]
  #   If the number is positive (> 0), 1 refers to the top-most active command,
  #   2 to the command it was called from, and so on. Otherwise the number
  #   gives a level relative to the current command, where zero refers to
  #   current command, -1 to its caller, and so on.
  # -----------------------------------------------------------------------------
  proc frame2log {stepname rel_info_frame info_frame_0} {
    lappend list1 "internal step: $stepname"
    set frameType [dict get $info_frame_0 "type"]
    if {[string equal $frameType "precompiled"]} {
      return $list1
    }
    set line [dict get $info_frame_0 "line"]
    set relativeLine [dict get $rel_info_frame "line"]
    if {[string equal $frameType "source"]} {
      if {[dict exists $info_frame_0 "proc"]} {
        lappend list1 "Proc: [dict get $info_frame_0 "proc"]"
      }
      lappend list1 "File: [file tail [dict get $info_frame_0 "file"]]:$line"
    } else {
      if {[dict exists $rel_info_frame "file"]} {
        if {[dict exists $rel_info_frame "proc"]} {
          lappend list1 "Proc: [dict get $rel_info_frame "proc"]"
        }
        lappend list1 "File: [file tail [dict get $rel_info_frame "file"]]:[expr {$relativeLine + $line}]"
        lappend list1 "Line computed from base: $relativeLine offset: $line"
      } elseif {[dict exists $rel_info_frame "proc"]} {
        lappend list1 "Proc: [dict get $rel_info_frame "proc"]"
        lappend list1 "Line: [expr {$relativeLine + $line}]"
        lappend list1 "Line computed from base: $relativeLine offset: $line"
      } else {
        if {[dict exists $info_frame_0 "proc"]} {
          lappend list1 "Proc: [dict get $info_frame_0 "proc"]"
        }
        lappend list1 "Line: [dict get $info_frame_0 "line"]"
      }
    }
    return $list1
  }

  # ----------------------------------------------------------------------------
  # Arguments:
  #   steps_log: Fully qualified path to log file
  #   lines: List of lines to print to log, usually frame information
  #   indent: indentation level
  # ----------------------------------------------------------------------------  
  proc steps_append { steps_log lines {indent "   "} } {
    # this is not a fatal problem from flow's perspective, hence using WARNING
    if {[catch {set outfile [open $steps_log a+]} catch_result]} {
      puts "WARNING: problem opening file $steps_log: $catch_result"
      return
    }
    set tool_flow "VPL"
    if {[string match "internal step:*" [lindex $lines 0]]} {
      puts $outfile "${indent}-----------------------"
      puts $outfile "${indent}$tool_flow [lindex $lines 0]"
      set list1 [lreplace $lines 0 0]
      foreach elem $list1 {
        puts $outfile "${indent}[string trim $elem]"  ;# Trim to remove the extra space after the comma
      } 
      set systemTime [clock seconds]
      puts $outfile "${indent}timestamp: [clock format $systemTime -format {%d %B %Y %H:%M:%S}]"
    } else {
      puts $outfile "${indent}$tool_flow [lindex $lines 0]"
    }
    close $outfile
  }

  # code simplication prototype
  proc run_cmd {cmd2} {
    upvar cmd cmd
    set cmd $cmd2
    # puts "dbg: run_cmd: $cmd2 (frame:[info frame])"

    uplevel {
      # note: vivado_output_dir and other variables are accessible in uplevel
      # puts "dbg: inside uplevel block (frame:[info frame])"
      # current frame (0) is inside uplevel block
      # frame -1 is inside run_cmd
      # frame -2 is the caller of run_cmd (a "catch" block in vpl.tcl)
      # frame -3 is vpl.tcl
      ocl_util::add_to_steps_log $steps_log "internal step: $cmd" [ocl_util::extFileName]:[expr {[dict get [info frame -3] line] + [dict get [info frame -2] line]}]
      # OPTRACE <task> <action> <tag>
      OPTRACE $optrace_task START
      if { [catch {eval $cmd}  catch_result return_options_dict] } {
        OPTRACE $optrace_task END
        ocl_util::log_exception $vivado_output_dir $sw_persona_msg $catch_result $return_options_dict 
      }
      # puts "debug point 1"
      # puts [dict get [dict get $sw_msgs msg_1] msg]
      # puts [dict get [dict get $sw_msgs msg_1] step_name]
      OPTRACE $optrace_task END
    }
  }

  proc get_sw_persona_msgs {} {
    uplevel {

      set msg_1 [dict create \
        step_name  "test1" \
        msg        "Failed to source Vivado impl properties. The project is '$project_name'.\
                    The internal Vivado impl script is '$impl_props_tcl'. The script was\
                    generated by VPL." \
      ];

      set msg_2 [dict create \
        step_name  "test2"  \
        msg        "This is message 2." \
      ];

      set sw_msgs [dict create \
        msg_1         $msg_1 \
        msg_2         $msg_2 \
      ];
    }
  }

  # only used for wait_on_first_run cases of multi-strategies, check if a run meets timing
  proc is_best_run {impl_run wns_threshold ignore_hold_vio} {

    # timing closed best run => Condition for this is WNS/WHS/TPWS values are >=0
    # non timing closed best run => 
    #    check the slack value provided by param compiler.worstNegativeSlack=-0.050
    set run_obj [get_runs $impl_run]
    set run_status [get_property STATUS [get_runs $impl_run]]
    # puts "debug: $impl_run status is $run_status"

    if {$run_status ne "write_bitstream Complete!" && $run_status ne "write_device_image Complete!"} {
      return false
    }

    # worst negative slack (setup)
    set wns [get_property STATS.WNS $run_obj]
    # worst hold slack
    set whs [get_property STATS.WHS $run_obj]
    # Total pulse width slack
    set tpws [get_property STATS.TPWS $run_obj]
    # puts "\tWNS: $wns"
    # puts "\tWHS: $whs"
    # puts "\tTPWS: $tpws" 


    if {$wns >= 0 && $whs >= 0 && $tpws >=0} {
      return true
    } else {
      # take compiler.worstNegativeSlack and compiler.errorOnHoldViolation into account
      if { $wns >= $wns_threshold && 
           ($whs >= 0 || $ignore_hold_vio) && 
           $tpws >=0 } {
        return true
      } else {
        return false
      }
    }
  }

  # only used for wait_on_all_runs case of multi-strategies
  proc report_wns_stats {impl_runs wns_threshold ignore_hold_vio steps_log best_run_var} {
    upvar $best_run_var best_run

    # timing closed best run => 
    #     wns >= 0 AND whs >= 0 AND tpws >= 0
    #     in this case, the first impl run that meets this criteria would be picked
    # non timing closed best run => 
    #     wns >= compiler.worstNegativeSlack AND whs >= 0 AND tpws >= 0
    #     note: if compiler.errorOnHoldViolation is false, negative whs value would be ignored
    # timing failed =>    
    #     wns < compiler.worstNegativeSlack value OR whs < 0 OR tpws < 0
    #     note: if compiler.errorOnHoldViolation is false, negative whs value would be ignored
    #
    set timing_closed_best ""
    set non_timing_closed_best ""

    puts "\nMulti-strategy Flow Summary:"
    puts "     compiler.worstNegativeSlack: $wns_threshold"
    puts "     compiler.errorOnHoldViolation: [expr ! $ignore_hold_vio]"
    foreach impl_run $impl_runs {
      set run_status [get_property STATUS [get_runs $impl_run]]
      # puts "$impl_run status is $run_status"
      # impl_runs may contain useless run, e.g. my_rm_impl_1
      # we should filter it out
      if {$run_status eq "Not started"} {
        continue
      }

      # worst negative slack (setup)
      set wns [get_property STATS.WNS $impl_run]
      # set wns -$wns
      # worst hold slack
      set whs [get_property STATS.WHS $impl_run]
      # Total pulse width slack
      set tpws [get_property STATS.TPWS $impl_run]


      if {$wns >= 0 && $whs >= 0 && $tpws >=0} {
        if { $timing_closed_best eq ""} {
          # * indicates the selected timing closed best run
          puts "*Run: $impl_run : $run_status (timing closed)"
          set timing_closed_best $impl_run
        } else {
          puts "Run: $impl_run : $run_status (timing closed)"
        }
      } else {
        # take compiler.worstNegativeSlack and compiler.errorOnHoldViolation into account
        if { $wns >= $wns_threshold && 
             ($whs >= 0 || $ignore_hold_vio) && 
             $tpws >=0 } {
          if { $non_timing_closed_best eq ""} {
            puts "Run: $impl_run : $run_status (non timing closed)"
            set non_timing_closed_best $impl_run
          } else {
            puts "Run: $impl_run : $run_status (non timing closed)"
          }
        } else {
          puts "Run: $impl_run : $run_status (timing failed)"
        }
      }
      puts "\tWNS: $wns"
      puts "\tWHS: $whs"
      puts "\tTPWS: $tpws" 
    }

    if {$timing_closed_best ne ""} {
      set summary "Timing Closed BEST Implementation Run: $timing_closed_best"
      set best_run $timing_closed_best
    } else {
      if {$non_timing_closed_best ne ""} {
        set summary "Non Timing Closed BEST Implementation Run: $non_timing_closed_best"
        set best_run $non_timing_closed_best
      } else {
        set summary "BEST Implementation Run: NONE" 
      }
    }
    puts "\n$summary\n"
    # add an summary entry to steps.log
    add_to_steps_log $steps_log "Multi-strategy Flow: $summary" [fileName]:[lineNumber [info frame]]
  }


  ################################################################################
  # write_vpl_tcl_hooks
  # utility function called by config_hw_runs step
  #   Description: write the _vpl_* tcl hooks
  #      
  #   Arguments:
  #     hw_platform_info
  #     config_info
  #     clk_info
  ################################################################################
  proc write_vpl_tcl_hooks {hw_platform_info config_info clk_info} {
    set steps_log        [dict get $config_info steps_log] 

    add_to_steps_log $steps_log "internal step: creating vpl tcl hooks for implementation run" [fileName]:[lineNumber [info frame]]
    write_vpl_pre_init_hook $config_info
    write_vpl_post_init_hook $hw_platform_info $config_info $clk_info 
    write_vpl_pre_opt_hook $config_info $hw_platform_info
    write_vpl_post_opt_hook $config_info $hw_platform_info
    write_vpl_pre_place_hook $hw_platform_info $config_info $clk_info 
    write_vpl_post_place_hook $config_info $hw_platform_info
    write_vpl_post_route_hook $hw_platform_info $config_info $clk_info 
    write_vpl_post_post_route_phys_opt_hook $config_info
    write_vpl_pre_write_bit_pdi_hook $hw_platform_info $config_info $clk_info
    write_vpl_post_write_bit_pdi_hook $hw_platform_info $config_info
  }

  proc write_init_cmds_for_run {outfile local_dir} {
    global vivado_error_file
    global vivado_warn_file

    puts $outfile "if { !\[info exists _is_init_cmds\] } {"
    puts $outfile "  source ../../../.local/vpl_init.tcl"
    # this needs to be done because impl run starts a child vivado process
    # and this new process doesn't know the tcl procs defined in ocl_util.tcl 
    # unless we source the tcl file first
    #
    # puts $outfile "source [ dict get [ info frame 0 ] file ]"
    # to increase the portability, we copy ocl_util to local ($local_dir)
    puts $outfile "  source \$local_dir/ocl_util.tcl"
    puts $outfile "  source \$local_dir/platform.tcl"
    #
    # TODO
    # ipirun.tcl sources vpl_init.tcl, ocl_util.tcl and platform.tcl
    # sourcing ipirun.tcl also makes core tcl dictionaries (e.g. hw_platform_info,
    # config_info) visible to impl run (child vivado process), so that we don't have
    # pass tcl dictionaries by value
    # puts $outfile "  source ../../../ipirun.tcl"
    
    # requried for  update_profile_metadata_postroute
    puts $outfile "  source \$local_dir/debug_profile_hooks.tcl"

    # import ocl_util::* tcl procs so that 'ocl_util::' prefix is not needed
    puts $outfile "  namespace import ocl_util::*"
    # puts $outfile "# get_script_dir returns [get_script_dir]"
    puts $outfile ""
    # this variable is needed for support stepwise run, since v++ can start
    # impl run from any step
    puts $outfile "  set _is_init_cmds true"
    puts $outfile "}"
    puts $outfile ""
    # puts $outfile "source \$local_dir/debug_profile_hooks.tcl"
    puts $outfile ""
  }

  proc write_vpl_pre_init_hook { config_info } {
    set scripts_dir      [dict get $config_info scripts_dir] 
    set local_dir        [dict get $config_info local_dir] 
    set tclhook_prefix   [dict get $config_info tclhook_prefix]
    set strategies       [dict get $config_info strategies_impl]
  
    set vpl_pre_init_tcl "$scripts_dir/${tclhook_prefix}_pre_init.tcl"
    set outfile [open $vpl_pre_init_tcl w]
    # puts $outfile "puts \"sourcing $vpl_pre_init_tcl\""

    puts $outfile "# This file was automatically generated by Vpl"
    write_init_cmds_for_run $outfile $local_dir

    if {[llength $strategies] > 0} {
      # This is for a multi-strategy run. We need to fork dispatch so reports
      # generated by the different runs will be different. Later code will
      # write out the reports to different locations.
      puts $outfile "# Multistrategy run. Fork dispatch for unique data generation."
      puts $outfile "fork_for_multistrategy"
    }

    close $outfile
  }

  # --kernel_frequency support for implementation (i.e. adding clock constraints)
  # for single project flow only
  proc write_vpl_post_init_hook { hw_platform_info config_info clk_info } {
    set ocl_inst_path      [dict get $hw_platform_info ocl_region]
    set steps_log          [dict get $config_info steps_log] 
    set scripts_dir        [dict get $config_info scripts_dir] 
    set vivado_output_dir  [dict get $config_info vivado_output_dir]  
    set tclhook_prefix     [dict get $config_info tclhook_prefix] 
    set kernel_clock_freqs [dict get $clk_info kernel_clock_freqs]  

    set vpl_post_init_tcl "$scripts_dir/${tclhook_prefix}_post_init.tcl"
    set outfile [open $vpl_post_init_tcl w]
    puts $outfile "# This file was automatically generated by Vpl"
    puts $outfile "write_user_impl_clock_constraint \"$ocl_inst_path\" \"$kernel_clock_freqs\" \"\" \$vivado_output_dir" 

    close $outfile
  }

  # create a pre tcl hook for opt_design
  proc write_vpl_pre_opt_hook { config_info hw_platform_info } {
    set ocl_inst_path    [dict get $hw_platform_info ocl_region]
    set scripts_dir      [dict get $config_info scripts_dir] 
    set local_dir        [dict get $config_info local_dir] 
    set tclhook_prefix   [dict get $config_info tclhook_prefix] 
    set nifd_enabled     [dict get $config_info nifd_enabled] 
    
    # failfast_config is only available for unified platform
    set failfast_config ""
    if { [dict exists $config_info failfast_config] } {
      set failfast_config  [dict get $config_info failfast_config]  
    }

    set vpl_pre_opt_tcl "$scripts_dir/${tclhook_prefix}_pre_opt.tcl"
    set outfile [open $vpl_pre_opt_tcl w]

    puts $outfile "# This file was automatically generated by Vpl"
    write_init_cmds_for_run $outfile $local_dir

    write_utilization_drc $config_info $hw_platform_info $outfile

    if { [dict exists $failfast_config pre_opt_design] } {
      set failfast_args [dict get $failfast_config pre_opt_design]
      if { [llength $failfast_args] == 0} {
        set failfast_args ""
      }
      # added on 4/9/2018 - to support macro expansion for reporting
      report_failfast_helper $hw_platform_info $failfast_args $outfile
    }
    # NIFD Support - Generate RAM utilization report post synthesis
    if {$nifd_enabled} {
      puts $outfile "report_ram_utilization -file ram.rpt"
    }

    close $outfile
  }

  ## helper for failfast macro expansion
  proc report_failfast_helper {hw_platform_info failfast_args outfile} {
    # added on 4/9/2018 - to support macro expansion for reporting
    set ocl_inst_path [dict get $hw_platform_info ocl_region]
    if { [string equal $failfast_args "__OCL_TOP__"] } {
      # If the ocl_region is empty (SoC), then drop the -pblock and -cell
      if { [string equal $ocl_inst_path ""] } {
        puts $outfile "if {\[catch {::tclapp::xilinx::designutils::report_failfast -detailed_report full.postopt -file full.postopt.failfast.rpt} _error\]} {"
        puts $outfile "  puts \"The report_failfast command failed with message '\${_error}', the flow will continue but this report will be missing.\""
        puts $outfile "}"
      } else {
        set ocl_inst_escaped [string map {/ _} $ocl_inst_path]
        puts $outfile "set oclPblock \[get_pblocks -quiet -filter {PARENT==ROOT && EXCLUDE_PLACEMENT} -of \[get_cells $ocl_inst_path/*\]\] "
        puts $outfile "if {\[catch {::tclapp::xilinx::designutils::report_failfast -detailed_report $ocl_inst_escaped.postopt -file $ocl_inst_escaped.postopt.failfast.rpt -pblock \$oclPblock -cell $ocl_inst_path} _error\]} {"
        puts $outfile "  puts \"The report_failfast command failed with message '\${_error}', the flow will continue but this report will be missing.\""
        puts $outfile "}"
      }
    } elseif { [string equal $failfast_args "__SLR__"] } {
      puts $outfile "if {\[catch {::tclapp::xilinx::designutils::report_failfast -detailed_report bySLR.postplace -file bySLR.postplace.failfast.rpt -by_slr} _error\]} {"
      puts $outfile "  puts \"The report_failfast command failed with message '\${_error}', the flow will continue but this report will be missing.\""
      puts $outfile "}"
    } elseif { [string equal $failfast_args "__KERNEL_NAMES__"] } {
      puts $outfile "foreach kernel_inst \[::ocl_util::get_kernel_cells \"$ocl_inst_path\"\] {"
      # get the kernel name (for hls kernel, the orig_ref_name seems to be the kernel name) 
      puts $outfile "  set kernel_name \[get_property ORIG_REF_NAME \$kernel_inst\]"
      puts $outfile "  set oclPblock \[get_pblocks -quiet -filter {PARENT==ROOT && EXCLUDE_PLACEMENT} -of \[get_cells \$kernel_inst\]\] "
      puts $outfile "  # Skip if oclPblock is empty, SoC Platforms will match this criteria"
      puts $outfile "  if {!\[string equal \$oclPblock \"\"\]} {"
      puts $outfile "    if {\[catch {::tclapp::xilinx::designutils::report_failfast -show_resource -detailed_report \$kernel_name.postsynth -file \$kernel_name.postsynth.failfast.rpt -cell \$kernel_inst -pblock  \$oclPblock} _error\]} {"
      puts $outfile "      puts \"The report_failfast command failed with message '\${_error}', the flow will continue but this report will be missing.\""
      puts $outfile "    }"
      puts $outfile "  }"
      puts $outfile "}"
    } else {
      puts $outfile "if {\[catch {::tclapp::xilinx::designutils::report_failfast $failfast_args} _error\]} {"
      puts $outfile "  puts \"The report_failfast command failed with message '\${_error}', the flow will continue but this report will be missing.\""
      puts $outfile "}"
    }
  }

  # create a post tcl hook for opt_design
  proc write_vpl_post_opt_hook { config_info hw_platform_info} {
    set ocl_inst_path    [dict get $hw_platform_info ocl_region]
    set scripts_dir      [dict get $config_info scripts_dir] 
    set tclhook_prefix   [dict get $config_info tclhook_prefix] 
    set failfast_config  [dict get $config_info failfast_config]  

    set vpl_post_opt_tcl "$scripts_dir/${tclhook_prefix}_post_opt.tcl"
    set outfile [open $vpl_post_opt_tcl w]
    puts $outfile "# This file was automatically generated by Vpl"

    if { [dict exists $failfast_config post_opt_design] } {
      set failfast_args [dict get $failfast_config post_opt_design]
      if { [llength $failfast_args] == 0} {
        set failfast_args ""
      }
      # added on 4/9/2018 - to support macro expansion for reporting
      report_failfast_helper $hw_platform_info $failfast_args $outfile
    }
    
    close $outfile
  }

  # create a pre tcl hook for place_design
  proc write_vpl_pre_place_hook { hw_platform_info config_info clk_info } {
    set optimize_level  [dict get $config_info optimize_level]
    set scripts_dir          [dict get $config_info scripts_dir] 
    set local_dir            [dict get $config_info local_dir] 
    set tclhook_prefix       [dict get $config_info tclhook_prefix] 

    # write the kernel clock info file for Steven Li
    set vpl_pre_place_tcl "$scripts_dir/${tclhook_prefix}_pre_place.tcl"
    set outfile [open $vpl_pre_place_tcl w]
    # puts $outfile "puts \"sourcing $vpl_pre_place_tcl\""

    puts $outfile "# This file was automatically generated by Vpl"
    write_init_cmds_for_run $outfile $local_dir

    # move post_init tcl hook to here
    # not sure if we can rename this tcl variable, is it used by any other step, e.g. place_design?
    puts $outfile "set xocc_optimize_level $optimize_level"
    puts $outfile "set_property SEVERITY {Warning} \[get_drc_checks HDPR-5\]"
    # CR 955574 - Turn off BUFG insertion during opt_design
    puts $outfile "set_param logicopt.enableBUFGinsertHFN 0"
    puts $outfile ""

    close $outfile
  }

  # create a post tcl hook for place_design
  proc write_vpl_post_place_hook { config_info hw_platform_info } {
    set enable_util_report   [dict get $config_info enable_util_report] 
    set kernels              [dict get $config_info kernels]
    set scripts_dir          [dict get $config_info scripts_dir] 
    set tclhook_prefix       [dict get $config_info tclhook_prefix] 
    set vivado_output_dir    [dict get $config_info vivado_output_dir] 
    # TODO: input_dir is not used
    set input_dir            [dict get $config_info input_dir] 
    set ocl_inst_path        [dict get $hw_platform_info ocl_region]

    set vpl_post_place_tcl "$scripts_dir/${tclhook_prefix}_post_place.tcl"
    set outfile [open $vpl_post_place_tcl w]
    # puts $outfile "puts \"DEBUG: sourcing $vpl_post_place_tcl\""
    puts $outfile "# This file was automatically generated by Vpl"

    # generate the utilization reports after place_design
    puts $outfile "# utilization reports"
    puts $outfile "report_utilization_impl $enable_util_report \"$kernels\" \"placed\" \"$ocl_inst_path\" \$input_dir \$vivado_output_dir"

    close $outfile
  }

  # timing report/frequency scaling operations are done here
  # if post_route_phys_opt_design is not enabled
  proc write_vpl_post_route_hook { hw_platform_info config_info clk_info } {
    set ocl_inst_path        [dict get $hw_platform_info ocl_region]
    set bb_locked_dcp        [dict get $hw_platform_info bb_locked_dcp]
    set pr_shell_dcp         [dict get $hw_platform_info pr_shell_dcp]
    set uses_pr_shell_dcp    [dict get $hw_platform_info uses_pr_shell_dcp]
    set link_output_format   [dict get $hw_platform_info link_output_format]

    set design_name          [dict get $config_info design_name]
    set enable_util_report   [dict get $config_info enable_util_report] 
    set kernels              [dict get $config_info kernels]
    set clbinary_name        [dict get $config_info clbinary_name]
    set encrypt_impl_dcp     [dict get $config_info encrypt_impl_dcp]
    set encrypt_key_file     [dict get $config_info encrypt_key_file]
    set enable_pr_verify     [dict get $config_info enable_pr_verify]
    set local_dir            [dict get $config_info local_dir] 
    set scripts_dir          [dict get $config_info scripts_dir] 
    set vivado_output_dir    [dict get $config_info vivado_output_dir] 
    # TODO: input_dir is not used
    set input_dir            [dict get $config_info input_dir] 
    set failfast_config      [dict get $config_info failfast_config]  
    set tclhook_prefix       [dict get $config_info tclhook_prefix]
    set steps_log            [dict get $config_info steps_log]
    set vpl_output_dir       [dict get $config_info vpl_output_dir]
    set strategies       [dict get $config_info strategies_impl]

    set vpl_post_route_tcl "$scripts_dir/${tclhook_prefix}_post_route.tcl"
    set outfile [open $vpl_post_route_tcl w]
    # puts $outfile "puts \"DEBUG: sourcing $vpl_post_route_tcl\""

    puts $outfile "# This file was automatically generated by Vpl"
    # as of 2020.2, we don't have vpl internal pre tcl hook for route_design
    # so we need to call write_init_cmds_for_run here
    write_init_cmds_for_run $outfile $local_dir

    puts $outfile ""
    if { $encrypt_impl_dcp } {
      set encrypted_dcp "encrypted_routed.dcp"
      puts $outfile "# generate encrypted implemented checkpoint file"
      puts $outfile "if { !\[file exists $encrypted_dcp\] } {"
      puts $outfile "  if { !\[string equal \"$encrypt_key_file\" \"\"\] && \[file exists \"$encrypt_key_file\"\] } {"
      puts $outfile "    write_checkpoint -encrypt $encrypted_dcp -key \"$encrypt_key_file\""
      puts $outfile "  } else {"
      puts $outfile "    write_checkpoint -encrypt $encrypted_dcp" 
      puts $outfile "  }"
      puts $outfile "}"
      puts $outfile ""
    }
    puts $outfile "# generate cookie file for messaging"
    puts $outfile "write_cookie_file_impl \"$clbinary_name\""
    puts $outfile ""
    puts $outfile "# utilization reports"
    puts $outfile "report_utilization_impl $enable_util_report \"$kernels\" \"routed\" \"$ocl_inst_path\" \$input_dir \$vivado_output_dir"
    puts $outfile ""

    puts $outfile "# kernel service update"
    if {[llength $strategies] > 0} {
      # This is for a multi-strategy run. We need output to be local to this run.
      puts $outfile "update_kernel_info \$steps_log \[pwd\] \"$ocl_inst_path\""
    } else {
      puts $outfile "update_kernel_info \$steps_log \$vpl_output_dir \"$ocl_inst_path\""
    }
    puts $outfile ""

    if {$enable_pr_verify} {
      set hw_platform_dcp [expr { $uses_pr_shell_dcp ? $pr_shell_dcp : $bb_locked_dcp} ] 
      if {$hw_platform_dcp ne ""} {
        # to increase the portability, support relative path
        if { [string first $local_dir $hw_platform_dcp] != -1 } {
          set hw_platform_dcp "../../../$hw_platform_dcp"
        }

        puts $outfile "# verify pr with the hw_platform dcp"
        puts $outfile "pr_verify -in_memory -additional $hw_platform_dcp"
        puts $outfile ""
      }
    }

    # aws dcp support
    # ltx files are generated as part of write_bitstream or write_device_image, 
    # since for Faas, we stop at post route_design, we need to run 
    # write_debug_probes commands explicitly to generate them
    # CR 1011484: copy *just* debug_nets.ltx and rename it to <binary>.ltx
    if { [string equal $link_output_format "dcp"] } {
      puts $outfile "# generate ltx files"
      puts $outfile "write_debug_probes -force -quiet -no_partial_ltxfile \[format \"%s/%s\" \".\" debug_nets.ltx\]"
    }

    if { [dict exists $failfast_config post_route_design] } {
      set failfast_args [dict get  $failfast_config post_route_design]
      if { [llength $failfast_args] == 0} {
        set failfast_args ""
      }
      # added on 4/9/2018 - to support macro expansion for reporting
      report_failfast_helper $hw_platform_info $failfast_args $outfile
    }

    # update noc nodes in debug_ip_layout
    puts $outfile "# update noc node information"
    puts $outfile "update_profile_metadata_postroute \$vpl_output_dir"

    if {[llength $strategies] > 0} {
      # This is for a multi-strategy run. We need output to be local to this run.
      puts $outfile "# Multistrategy run. Close associated sessions in dispatch."
      puts $outfile "close_multistrategy_fork"
    }

    close $outfile
  }

  # create a post tcl hook for post_route_phy_opt_design
  proc write_vpl_post_post_route_phys_opt_hook { config_info } {
    set scripts_dir          [dict get $config_info scripts_dir]
    set tclhook_prefix       [dict get $config_info tclhook_prefix] 
    set encrypt_impl_dcp     [dict get $config_info encrypt_impl_dcp]
    set encrypt_key_file     [dict get $config_info encrypt_key_file]

    set outfile [open "$scripts_dir/${tclhook_prefix}_post_post_route_phys_opt.tcl" w]
    puts $outfile "# This file was automatically generated by Vpl"

    if { $encrypt_impl_dcp } {
      set encrypted_dcp "encrypted_postroute_physopt.dcp"
      puts $outfile "# generate encrypted implemented checkpoint file"
      puts $outfile "if { !\[file exists $encrypted_dcp\] } {"
      puts $outfile "  if { !\[string equal \"$encrypt_key_file\" \"\"\] && \[file exists \"$encrypt_key_file\"\] } {"
      puts $outfile "    write_checkpoint -encrypt $encrypted_dcp -key \"$encrypt_key_file\""
      puts $outfile "  } else {"
      puts $outfile "    write_checkpoint -encrypt $encrypted_dcp" 
      puts $outfile "  }"
      puts $outfile "}"
      puts $outfile ""
    }

    close $outfile
  }

  # create a pre tcl hook for write_bitstream or write_device_image 
  proc write_vpl_pre_write_bit_pdi_hook {hw_platform_info config_info clk_info} {
    set scripts_dir          [dict get $config_info scripts_dir]
    set local_dir            [dict get $config_info local_dir] 
    set tclhook_prefix       [dict get $config_info tclhook_prefix] 

    set outfile [open "$scripts_dir/${tclhook_prefix}_pre_write_bit_pdi.tcl" w]
    puts $outfile "# This file was automatically generated by Vpl"
    write_init_cmds_for_run $outfile $local_dir

    close $outfile
  }

  # create a post tcl hook for write_bitstream or write_device_image 
  proc write_vpl_post_write_bit_pdi_hook { hw_platform_info config_info } {
    set scripts_dir          [dict get $config_info scripts_dir]
    set tclhook_prefix       [dict get $config_info tclhook_prefix] 
    set is_hw_export         [dict get $config_info is_hw_export] 
    set gen_fixed_xsa_in_top_prj [dict get $config_info gen_fixed_xsa_in_top_prj] 

    set outfile [open "$scripts_dir/${tclhook_prefix}_post_write_bit_pdi.tcl" w]
    puts $outfile "# This file was automatically generated by Vpl"
    if {!$gen_fixed_xsa_in_top_prj} {
      if {$is_hw_export} {
        puts $outfile "ocl_util::generate_fixed_hw_platform \"$hw_platform_info\" \"$config_info\" false"
        # puts $outfile "ocl_util::generate_fixed_hw_platform \$hw_platform_info \$config_info false"
      }
    }
    close $outfile
  }

  # TODO: input_dir is not used
  # this is part of post tcl hook for place_design and route_design
  proc report_utilization_impl {enable_util_report kernels run_step ocl_inst_path input_dir output_dir } {
    if { $enable_util_report } { 
      set kernel_util_string ""
      foreach kernel_inst [get_kernel_cells $ocl_inst_path] {
        if { ![string equal $kernel_inst ""] } {
          # puts "--- DEBUG: kernel instance is $kernel_inst"
          # report_property $kernel_inst
          # get the kernel name (for hls kernel, the orig_ref_name seems to be the kernel name) 
          set kernel [get_property ORIG_REF_NAME $kernel_inst]

          # xcl_design_i/expanded_region/u_ocl_region/opencldesign_i/mmult_cu1/inst
          set ki_split [split $kernel_inst "/"]
          # assume the second to the last element is the kernel instance name (i.e. "mmult_cu1")
          # this is not reliable, but couldn't figure out a better way
          set kernel_inst_base [lindex $ki_split end-1]

          set kernel_util_string "$kernel_util_string $kernel:$kernel_inst:$kernel_inst_base"
        }
      }

      if {$kernel_util_string ne ""} {
        # report_sdx_utilization is replace by report_accelerator_utilization
        # puts "INFO: \[OCL_UTIL\] report_accelerator_utilization -kernels \"$kernel_util_string\" -file \"kernel_util_${run_step}.rpt\" -name kernel_util_${run_step} -json"
        # note: report_accelerator_utilization generates rpt (text), xutil (pb) and json files
        report_accelerator_utilization -kernels "$kernel_util_string" -file "kernel_util_${run_step}.rpt" -name kernel_util_${run_step} -json
        create_system_diagram_metadata $run_step $output_dir
      }

      # report_utilization -slr is useless for post-synth. After placement it would be
      # worthwhile 
      # if {$run_step eq "routed"} 
      if {$run_step eq "routed" || $run_step eq "placed"} {
        report_utilization -slr -file "slr_util_${run_step}.rpt" -pb "slr_util_${run_step}.pb"
        report_utilization -file "full_util_${run_step}.rpt" -pb "full_util_${run_step}.pb"
      }
    }
  }

  proc write_cookie_file_impl { clbinary_name} { 
    # write the "cookie file" for Dennis' messaging support
    set run_dir [pwd]
    set cookie_file ./.runmsg.txt
    set outfile [open $cookie_file w]
    puts $outfile "Compiling (bitstream) accelerator binary: $clbinary_name"
    puts $outfile "Log file: $run_dir/runme.log"
    close $outfile
  }

  # utility tcl proc
  proc has_output_format {link_output_format format} {
    # note: link_output_format could be "dcp", "bitstream", "pdi", "dcp, bitstream"
    #       "dcp, pdi"
    set stripped [string map {" " ""} $link_output_format]
    set formats [split $stripped ","]
    if {[lsearch $formats $format] != -1} {
      return true
    } else {
      return false
    }
  }

  # runs the report timing and frequency scaling either: 
  #    1. after route_design if post_route_phys_opt_design is not enabled
  # or 2. after post_route_phy_opt_design if enabled
  # or 3. before write_bitstream or write_device image if multi-strategies is enable or link output
  #       format is NOT "dcp".
  # ideally, we want to run timing check and frequency scaling as late as possible so that
  # any tcl hook from platform and user that can potentially solve timing issues would be sourced
  # before
  # proc write_report_timing_and_scale_freq { hw_platform_info config_info clk_info is_physopt_enabled} 
  proc write_report_timing_and_scale_freq { hw_platform_info config_info clk_info } {
    set ocl_inst_path        [dict get $hw_platform_info ocl_region]
    set link_output_format   [dict get $hw_platform_info link_output_format]

    set design_name          [dict get $config_info design_name]
    set vivado_output_dir    [dict get $config_info vivado_output_dir]
    set vpl_output_dir       [dict get $config_info vpl_output_dir]
    set scripts_dir          [dict get $config_info scripts_dir]
    set clbinary_name        [dict get $config_info clbinary_name]
    set tclhook_prefix       [dict get $config_info tclhook_prefix] 
    set strategies_impl      [dict get $config_info strategies_impl] 

    # note: link_output_format could be "dcp", "bitstream", "pdi", "dcp, bitstream" and "dcp, pdi"
    #       except for "dcp", we should do timing check and frequency scaling
    #       in write_bitstream pre tcl hook

    # if link_output_format="dcp"
    #   we write the report_timing and frequency scaling code to both route and post_route_phys_opt
    #   post tcl hook. at the run time (when each impl run is running), we decide which one to be 
    #   executed based on "is_post_route_phys_opt_enabled" set by the vivado impl run driver script
    # else (i.e. link_output_format="bitstream", "pdi", "dcp, bitstream", or "dcp, pdi")
    #   we write report_timing and frequency scaling code to write_bitstream post tcl hook
    if {![string equal $link_output_format "dcp"]} {
      set tcl_hooks "${tclhook_prefix}_pre_write_bit_pdi.tcl"
    } else {
      set tcl_hooks "${tclhook_prefix}_post_post_route_phys_opt.tcl ${tclhook_prefix}_post_route.tcl"
    }

    # insert a proc at the end of a tcl hook
    foreach tcl_hook $tcl_hooks {
      set post_hook [open "$scripts_dir/$tcl_hook" a+]
      puts $post_hook ""
      if { [string first "_post_route.tcl" $tcl_hook] != -1 } {
        # in route_design post tclhook, if is_post_route_phys_opt_enabled is true
        # we should not execute timing check and frequency scaling
        # is_post_route_phys_opt_enabled should be set by vivado impl run driver script
        # unless vitis picks up an older verison of vivado
        # puts $post_hook "  puts \"is post_route_phys_opt enabled: \$is_post_route_phys_opt_enabled\""
        puts $post_hook "if \{ \[info exists is_post_route_phys_opt_enabled\] && !\$is_post_route_phys_opt_enabled \} \{"
      }
      puts $post_hook "# run timing analysis and frequency scaling"
      puts $post_hook "if \{ !\[report_timing_and_scale_freq \"$ocl_inst_path\" \"$design_name\" \$vivado_output_dir \$vpl_output_dir \"$clk_info\" \"$clbinary_name\"\] \} \{"
      puts $post_hook "  return false"
      puts $post_hook "\}"
      if { [string first "_post_route.tcl" $tcl_hook] != -1 } {
        puts $post_hook "\}"
      }
      close $post_hook
    }
  }

  # primary tcl proc for running timing check and frequency scaling task
  # TODO: remove vpl_output_dir
  proc report_timing_and_scale_freq {ocl_inst_path design_name vivado_output_dir vpl_output_dir clk_info clbinary_name {is_in_run true}} {
    set worst_negative_slack    [dict get $clk_info worst_negative_slack]
    set error_on_hold_violation [dict get $clk_info error_on_hold_violation]
    set skip_timing_and_scaling [dict get $clk_info skip_timing_and_scaling]
    set enable_auto_freq_scale  [dict get $clk_info enable_auto_freq_scale]
    set cwd [pwd]

    # for multi-strategy flow, there would be multiple impl runs
    # for each impl run, it would generate its own _new_clk_freq file
    # so, intead of generating the file directly in vpl ouput dir, we will
    # generate this file in the run directory, at the end of vpl, we will
    # copy this file from the qualified impl run to vpl output dir (see copy_impl_run_output_files)
    set new_clk_freq_file "_new_clk_freq" 
    # used for internal developer only
    if {$skip_timing_and_scaling} {
      # puts "INFO: \[OCL_UTIL\] skip_timing_and_scaling is true"
      write_orig_clk_freq $new_clk_freq_file $clk_info
      return true
    }

    # if this tcl proc is executed as part of implementation run, the cwd is vivdo/prj/prj.runs/impl_*
    #    the timing dcp and report files should be generated at the cwd
    # if this tcl proc is executed standalone (e.g. create_bitstreams_without_implementation), the cwd is vivado/
    #    this timing dcp and report files should be generated at vivado/output/
    set timing_output_dir [expr { $is_in_run ? $cwd : $vivado_output_dir} ] 
    set routed_timing_dcp $timing_output_dir/${design_name}_routed_timing.dcp

    # Check hold violation before trying frequency scaling per Steven's request
    set timingHoldPaths [get_timing_paths -hold -quiet]
    if { [llength $timingHoldPaths] > 0 && [get_property SLACK $timingHoldPaths] < 0} {
      # The command above will return the worst hold slack. If it's negative, we error out.
      if { ![file exists $routed_timing_dcp] } {
        write_checkpoint $routed_timing_dcp
      }
      report_timing_summary -hold -file $timing_output_dir/${design_name}_timing_summary_hold.rpt
      # when there is a hold violation, it can be caused by huge failures in setup timing
      # so setup timing report should always be generated as well
      report_timing_summary -slack_lesser_than $worst_negative_slack -file $timing_output_dir/${design_name}_timing_summary.rpt

      if { $error_on_hold_violation } {
        if { $is_in_run } { 
          error "design did not meet timing - hold violation"
        } else {
          error2file $vivado_output_dir "design did not meet timing - hold violation"
        }
      } else {
        puts "WARNING: Hold violation detected, it will be ignored due to user setting."
      }
    }

    set err_str "Design failed to meet timing"
    # 3/27/2020 -part of the fix for 1040786. In guidance report need to link to the
    # timing report. Set the name and pass to down the stack.
    set timing_rpt_fname $timing_output_dir/${design_name}_timing_summary.rpt

    if {$enable_auto_freq_scale} {
      set is_timing_failure [expr [write_new_clk_freq $new_clk_freq_file $vivado_output_dir $ocl_inst_path $clk_info err_str $clbinary_name $timing_rpt_fname] == "0"]
    } else {
      # for soc platforms
      set is_timing_failure [expr [check_timing_and_write_orig_clk_freq $new_clk_freq_file $design_name $clk_info err_str] == "0"] 
    }
    if { $is_timing_failure } {
      if { ![file exists $routed_timing_dcp] } {
        write_checkpoint $routed_timing_dcp
      }
      report_timing_summary -slack_lesser_than $worst_negative_slack -file ${design_name}_timing_summary.rpt

      if { $is_in_run } { 
        error "design did not meet timing - $err_str"
      } else {
        error2file $vivado_output_dir $err_str
      }
    }
    return true
  }

  proc apply_dont_partition { enable_dont_partition steps_log vivado_output_dir} {
    if { $enable_dont_partition } {
      add_to_steps_log $steps_log "internal step: read_xdc $vivado_output_dir/dont_partition.xdc" [fileName]:[lineNumber [info frame]]

      # create the dont partition xdc for kernels
      # 1. Creating a dont_partition.xdc file what will contain a dont_partition constraint for all kernels.
      # 2. Adding the dont_partition.xdc to the project prior to running implementation.
      
      set dontpartition [open "$vivado_output_dir/dont_partition.xdc" w]
      puts $dontpartition "set_property DONT_PARTITION TRUE \[get_cells -hier -filter {SDX_KERNEL==true}\]"
      close $dontpartition

      read_xdc $vivado_output_dir/dont_partition.xdc
    }
  }

  # check for failed timing paths before writing original clock frequencies
  # used by soc platform of the hw flow
  proc check_timing_and_write_orig_clk_freq {new_clk_freq_file design_name clk_info err_str} {
    set worst_negative_slack  [dict get $clk_info worst_negative_slack]
    upvar $err_str _err_str

    set routed_timing_dcp ${design_name}_routed_timing.dcp
    set timing_summary_rpt ${design_name}_timing_summary.rpt
    puts "INFO: \[OCL_UTIL\] clock frequency scaling is disabled for this flow, perform the normal timing check instead"
    puts "INFO: \[OCL_UTIL\] get_timing_paths -quiet -slack_lesser_than $worst_negative_slack"
    set timingFailedPaths [ get_timing_paths -quiet -slack_lesser_than $worst_negative_slack ]
    if { [llength $timingFailedPaths] > 0 } {
      set _err_str "Design failed to meet timing.\n"
      append _err_str "    Failed timing checks (paths):\n\t[ join $timingFailedPaths \n\t ]\n\n"
      append _err_str "    Please check the routed checkpoint ($routed_timing_dcp) and timing summary report ($timing_summary_rpt) for more information."

      return 0;
    }

    # write the original clock frequencies in _new_ocl_freq file
    write_orig_clk_freq $new_clk_freq_file $clk_info
    
    return 1
  }

  # write original clock frequencies without checking for failed timing paths.
  # see a proc "check_timing_and_write_orig_clk_freq" which checks for failed timing paths.
  # used for hw_emu flow or if a param compiler.skipTimingCheckAndFrequencyScaling is set to true.
  proc write_orig_clk_freq {new_clk_freq_file clk_info} {
    set kernel_clock_freqs    [dict get $clk_info kernel_clock_freqs]  
    set system_clock_freqs    [dict get $clk_info system_clock_freqs]  

    # write the original clock frequencies in _new_ocl_freq file
    set outfile [open $new_clk_freq_file w]
    dict for {kernel_clk dict_clock} $kernel_clock_freqs {
      set orig_clk_freq [dict get $dict_clock freq]
      set clk_id [dict get $dict_clock clk_id] 
      puts $outfile "kernel:$clk_id:$kernel_clk:$orig_clk_freq"
    }

    dict for {system_clk dict_clock} $system_clock_freqs {
      set orig_clk_freq [dict get $dict_clock freq]
      set clk_id [dict get $dict_clock clk_id] 
      # note for system clock, the clk_id is an empty string
      puts $outfile "system:$clk_id:$system_clk:$orig_clk_freq"
    }

    close $outfile
  }

  proc get_kernel_cells { ocl_inst_path } {
    # We only want to find kernels that are in the OCL region. Some platforms
    # now use kernels in the static portion of the design, which should
    # be ignored for this method. See CR-1016419.
    set kernel_instances {}
    # We use -quiet below because we don't want the warnings about nothing found.
    # Clients can issue a warning if they expect kernels but none are returned.
    if { $ocl_inst_path ne "" } {
      set kernel_instances [get_cells -quiet $ocl_inst_path/.* -regexp -hier -filter "SDX_KERNEL==true"] 
    } else {
      # No path supplied--revert to old behavior.
      set kernel_instances [get_cells -quiet -hier -filter "SDX_KERNEL==true"] 
    }
    return $kernel_instances
  }

  # ocl_util::get_kernel_counts

  proc get_kernel_counts { ocl_inst_path } {

    set hls_count 0
    set rtl_count 0

    foreach instance [get_kernel_cells $ocl_inst_path] {
      # assumes that the only two valid kernel types are 'hls' and 'rtl'
      if { [get_property SDX_KERNEL_TYPE $instance] eq "hls" } {
        incr hls_count
      } else {
        incr rtl_count
      }
    }
    return [dict create hls $hls_count rtl $rtl_count]
  }

  # ocl_util::check_kernel_count
  #
  #     Assumes that PL 0 is always hls kernel clock and PL 1 is always rtl kernel clock,
  #     regardless of platform.
  #
  # Parameters:
  #     d A dictionary of kernel counts indexed by keys 'hls' or 'rtl'
  #     clk_id A number where 0 is the id for hls kernel clock, 1 is rtl kernel clock
  #
  # Results:
  #     Returns 1 if at least one kernel of the given type is found
  #     Else returns 0

  proc check_kernel_count { d clk_id } {
      set kernel_type hls
      if { $clk_id == 1 } {
          set kernel_type rtl
      }
      if { [dict exists $d $kernel_type] } {
          if { [dict get $d $kernel_type] > 0 } {
              return 1
          }
      }
      return 0
  }

  # ocl_util::kernel_clock_purpose
  #
  #     Format human-readable string that explains the purpose for a given
  #     scalable kernel clock.
  #
  # Parameters:
  #     kernel_clk     A scalable kernel clock 'name' (pin path?)
  #     clk_id         Value 0 is the id for hls kernel clock, 1 is rtl kernel clock
  #     kernel_counts  Dict of kernel counts indexed by keys 'hls' or 'rtl'
  #
  # Results:
  #     A string, which may be empty

  proc kernel_clock_purpose { kernel_clk clk_id kernel_counts } {

    set result ""
    set kernel_type "" 
    if { $clk_id == 0 } {
      set kernel_type hls
    } elseif { $clk_id == 1 } {
      set kernel_type rtl
    } else {
      return $result
    }
    set count 0
    if { [dict exists $kernel_counts $kernel_type] } {
      set count [dict get $kernel_counts $kernel_type]
    }  
    set result "\n"
    append result "Scalable clock $kernel_clk (Id = $clk_id) is used for $kernel_type kernels. "
    append result "This design has $count $kernel_type kernel(s)."
    return $result
  }

  # ocl_util::write_new_clk_freq
  #
  #     Writes frequency data to file, used by runtime to set MMCM control registers.
  #     Output data is for scalable system clocks and kernel clocks.
  #
  # Parameters:
  #
  #     new_clk_freq_file - Path to output file for scalable system and kernel clock results
  #     vivado_output_dir
  #     ocl_inst_path
  #     clk_info          - clock tcl dict
  #     err_str
  #     clbinary_name
  #     timing_rpt_fname - the timing summary report for guidance
  #
  # Results:
  #     Returns 0 indicates frequency scaling failure; return 1 indicate success

  proc write_new_clk_freq {new_clk_freq_file vivado_output_dir ocl_inst_path clk_info err_str clbinary_name timing_rpt_fname} {
    set kernel_clock_freqs    [dict get $clk_info kernel_clock_freqs]  
    set system_clock_freqs    [dict get $clk_info system_clock_freqs]  
    set worst_negative_slack  [dict get $clk_info worst_negative_slack]

    upvar $err_str _err_str
    # set startdir [pwd]

    puts "Starting auto-frequency scaling ..."
    # initialize kernel_pin_freqs
    foreach kernel_clk [dict keys $kernel_clock_freqs] {
      # note $kernel_clk is actually the clock pin name defined in hpfm
      set kernel_pin_path "$ocl_inst_path/$kernel_clk"
      set dict_clock [dict get $kernel_clock_freqs $kernel_clk]
      set orig_clock_freq [dict get $dict_clock freq]
      set orig_clock_freq [format "%.1f" $orig_clock_freq]
      # kernel_pin_clock_map is tcl array, which defines the mapping:
      #   <kernel clock pin path> -> <kernel clock pin name>
      set kernel_pin_clock_map($kernel_pin_path) $kernel_clk

      # kernel_pin_freqs is a tcl array, which defines the mapping:
      #   <kernel clock pin path> -> <clock frequency>
      # get_achievable_kernel_freq will update <clock frequency> with the scaled (new) frequency  
      set kernel_pin_freqs($kernel_pin_path) $orig_clock_freq
      puts "kernel clock '$kernel_clk':"
      puts "   clock pin path     : $kernel_pin_path"
      puts "   original frequency : ${orig_clock_freq} MHz"
    }
    puts ""

    foreach system_clk [dict keys $system_clock_freqs] {
      # note $system_clk is the clock name defined in xsa metadata file (scalable system clocks)
      set system_pin_path [lindex [get_pins -of_objects [get_clocks $system_clk]] 0]
      set dict_clock [dict get $system_clock_freqs $system_clk]
      set orig_clock_freq [dict get $dict_clock freq] 
      set orig_clock_freq [format "%.1f" $orig_clock_freq]
      # system_pin_clock_map is tcl array, which defines the mapping:
      #   <system clock pin path> -> <system clock name>
      set system_pin_clock_map($system_pin_path) $system_clk

      # system_pin_freqs is a tcl array, which defines the mapping:
      #   <system clock pin path> -> <clock frequency>
      # get_achievable_kernel_freq will update <clock frequency> with the scaled (new) frequency  
      set system_pin_freqs($system_pin_path) $orig_clock_freq
      puts "system clock '$system_clk':"
      puts "   clock pin path     : $system_pin_path"
      puts "   original frequency : ${orig_clock_freq} MHz"
    }
    puts ""

    # call steven li's auto frequency scaling tcl proc, kernel_pin_freqs and system_pin_freqs contains the scaled frequencies
    # note: get_achievable_kernel_freq not only tries to scale the scalable clocks, it also reports
    #       any unscalable clock (e.g. system clock) which doesn't meet timing (worse than wns)
    set failing_system_clocks ""
    # Used to message final achieved frequency for all scalable clocks.
    set achieved ""
    set purpose ""
    set ret [get_achievable_kernel_freq $worst_negative_slack kernel_pin_freqs system_pin_freqs failing_system_clocks]
    puts "Auto-frequency scaling completed"

    set kernel_counts [get_kernel_counts $ocl_inst_path]

    # returns 0 if any system clock slack < worst negative slack, in which case, the clock frequency scaling failed
    # note slack is a negative value
    if { $ret  == "0" } {
      set err_freq ""
      # unified platforms, clock names are not hard-coded
      # find the mimimum new_ocl_freq 
      set min_new_ocl_freq 0
      foreach kernel_pin [array names kernel_pin_freqs] {
        validate_new_clk_freq $ocl_util::Kernel $clk_info $kernel_pin kernel_pin_clock_map kernel_pin_freqs _err_str new_ocl_freq $clbinary_name $kernel_counts $timing_rpt_fname
        if { $min_new_ocl_freq == 0 } {
          set min_new_ocl_freq $new_ocl_freq 
        }
        # puts "min_new_ocl_freq is $min_new_ocl_freq; new_ocl_freq is $new_ocl_freq"
        if { $min_new_ocl_freq > $new_ocl_freq } {
          set min_new_ocl_freq $new_ocl_freq 
        }
      }
      set new_ocl_freq $min_new_ocl_freq

      # $new_ocl_freq could have decimal places, so round it down 
      set err_freq [round_down $new_ocl_freq]
      set _err_str "Design did not meet timing. One or more unscalable system clocks did not meet their required target frequency. For all system clocks, this design is using $worst_negative_slack nanoseconds as the threshold worst negative slack (WNS) value. List of system clocks with timing failure:"
      set report_clock_list ""
      foreach _sys_clk [dict keys $failing_system_clocks] {
        set _slack [dict get $failing_system_clocks $_sys_clk]
        append _err_str "\nsystem clock: $_sys_clk; slack: $_slack ns"
        append report_clock_list "\nsystem clock: $_sys_clk; slack: $_slack ns"
      }

      # AUTO-FREQ-SCALING-01
      if {[is_drcv]} { ::drcv::create_violation AUTO-FREQ-SCALING-01 -s $err_freq -s $worst_negative_slack -s $report_clock_list }
      return 0
    }

    # write the new clock frequencies in _new_ocl_freq file
    set outfile [open $new_clk_freq_file w]


    # Handles scalable kernel clocks
    foreach kernel_pin [array names kernel_pin_freqs] {
      if { ![validate_new_clk_freq $ocl_util::Kernel $clk_info $kernel_pin kernel_pin_clock_map kernel_pin_freqs _err_str new_ocl_freq $clbinary_name $kernel_counts $timing_rpt_fname] } {
        close $outfile
        return 0 
      }
   
      set kernel_clk $kernel_pin_clock_map($kernel_pin)
      set dict_clock [dict get $kernel_clock_freqs $kernel_clk]
      set orig_clk_freq [dict get $dict_clock freq]
      set clk_id [dict get $dict_clock clk_id] 

      if { $new_ocl_freq < $orig_clk_freq } {
        warning2file $vivado_output_dir "WARNING: One or more timing paths failed timing targeting $orig_clk_freq MHz for kernel clock '$kernel_clk'. The frequency is being automatically changed to $new_ocl_freq MHz to enable proper functionality"
        # AUTO-FREQ-SCALING-04
        if {[is_drcv]} { 
          # note $kernel_clk is the clock pin name, not a clock name
          set clk_name [get_clock_name $kernel_clk]
          set clk_ref    [::drcv::create_reference OTHER -name $clk_name] 
          # ::drcv::create_violation AUTO-FREQ-SCALING-04 -dynamic_category [list [list xclbin $clbinary_name]] -REF [list type OTHER -name $kernel_clk] -s $orig_clk_freq -s $new_ocl_freq -s $clk_id 
          ::drcv::create_violation AUTO-FREQ-SCALING-04 -dynamic_category [list [list xclbin $clbinary_name]] -REF $clk_ref -s $orig_clk_freq -s $new_ocl_freq -s $clk_id 
        }
      }

      # write the new ocl frequency to the file "_new_clk_freq" regardless the clock has been scaled or not
      # in the case where the clock is not scaled, the new frequency would be same as original frequency
      puts $outfile "kernel:$clk_id:$kernel_clk:$new_ocl_freq"
      append achieved "\nKernel: $kernel_clk = $new_ocl_freq MHz "
      append purpose [kernel_clock_purpose $kernel_clk $clk_id $kernel_counts]
    }

    # Handles scalable system clocks
    foreach system_pin [array names system_pin_freqs] {
      if { ![validate_new_clk_freq $ocl_util::System $clk_info $system_pin system_pin_clock_map system_pin_freqs _err_str new_clk_freq $clbinary_name $kernel_counts $timing_rpt_fname] } {
        close $outfile
        return 0 
      }
   
      set system_clk $system_pin_clock_map($system_pin)
      set dict_clock [dict get $system_clock_freqs $system_clk]
      set orig_clk_freq [dict get $dict_clock freq]
      set clk_id [dict get $dict_clock clk_id] 

      if { $new_clk_freq < $orig_clk_freq } {
        warning2file $vivado_output_dir "WARNING: One or more timing paths failed timing targeting $orig_clk_freq MHz for system clock '$system_clk'. The frequency is being automatically changed to $new_clk_freq MHz to enable proper functionality"
        # AUTO-FREQ-SCALING-07
        if {[is_drcv]} {
          # note $system_clk is the clock name
          ::drcv::create_violation AUTO-FREQ-SCALING-07 -REF [list type OTHER -name $system_clk] -s $orig_clk_freq -s $new_clk_freq 
        }
      }

      # write the new ocl frequency to the file "_new_clk_freq" regardless the clock has been scaled or not
      # in the case where the clock is not scaled, the new frequency would be same as original frequency
      puts $outfile "system:$clk_id:$system_clk:$new_clk_freq"
      append achieved "\nSystem: $system_clk = $new_clk_freq MHz "
    }

    close $outfile
    append achieved $purpose
    # This is the right place to affirm the final achieved frequencies for the scalable clock domains.
    if {[is_drcv]} { ::drcv::create_affirmation PLATFORM-CLOCK-DOMAINS-01 -s $achieved }
    return 1;
  }

  # get the clock name from a clock pin path
  # if we couldn't get clock from the pin, return the
  # pin (input) to keep the current behavior
  proc get_clock_name {clock_pin_path} {
    set pin [get_pins $clock_pin_path]
    if {$pin == ""} {
      return $clock_pin_path
    }

    set clock [get_clocks -of_objects $pin]
    if {$clock == ""} {
      return $clock_pin_path
    }
    # puts "dbg: clock_pin_path is $clock_pin_path"
    # puts "dbg: clock name is $clock"
    return $clock
  }

  # ::ocl_util::validate_new_clk_freq
  #
  # Parameters:
  #     clk_type       One of 'kernel' or 'system'
  #     clk_info       A dict populated using data from the HPFM
  #     clock_pin      A clock pin path
  #     pin_clock_map
  #     clk_pin_freqs
  #     err_str
  #     new_clk_freq   The proposed, computed value to validate
  #     clbinary_name
  #     kernel_counts  A dict that relates kernel type to count
  #     timing_rpt_fname The path to the timing summary report for guidance
  #
  # Results:
  #     Sets a scaled frequency value - return 0 when scaled frequency is below minimum,
  #     return 1 otherwise.

  proc validate_new_clk_freq { clk_type clk_info clock_pin pin_clock_map clk_pin_freqs err_str \
      new_clk_freq clbinary_name kernel_counts timing_rpt_fname} {

    upvar $err_str _err_str
    upvar $new_clk_freq _new_clk_freq
    upvar $clk_pin_freqs _clk_pin_freqs
    upvar $pin_clock_map _pin_clock_map

    set max_frequency        [dict get $clk_info max_frequency]
    set min_frequency        [dict get $clk_info min_frequency]
    set worst_negative_slack [dict get $clk_info worst_negative_slack]

    # clock_freqs can either be kernel_clock_freqs or system_clock_freqs depending on $clk_type 
    set clock_freqs [dict get $clk_info ${clk_type}_clock_freqs]  
    # $clock_pin is the clock pin path
    # for kernel clocks, $clk is the clock pin name defined in hpfm
    # get the original clock frquency
    set clk $_pin_clock_map($clock_pin)
    set dict_clock [dict get $clock_freqs $clk]
    set orig_clk_freq [dict get $dict_clock freq]
    set orig_clk_freq [format "%.1f" $orig_clk_freq]
    set clk_id [dict get $dict_clock clk_id]
    set _new_clk_freq $_clk_pin_freqs($clock_pin)

    puts "$clk_type clock '$clk':"
    puts "   original frequency : ${orig_clk_freq} MHz"
    puts "   scaled frequency   : ${_new_clk_freq} MHz"
    if {[is_drcv]} { 
      # set clk_ref    [::drcv::create_reference OTHER -name $clk] 
      set clk_name [get_clock_name $clock_pin]
      set clk_ref [::drcv::create_reference OTHER -name $clk_name] 
    }

    # CR 964071: We should error out below 60Mhz. Nothing slower than this is supported
    # compiler.minFrequencyLimit
    if { $_new_clk_freq < $min_frequency } {
      set _err_str "auto frequency scaling failed because the auto scaled frequency '$_new_clk_freq MHz' is lower than the minimum frequency limit supported by the runtime ($min_frequency MHz)."
      if {[is_drcv]} {
        if {$clk_type eq $ocl_util::System} {
          # AUTO-FREQ-SCALING-05 is for system clock minimum
          ::drcv::create_violation AUTO-FREQ-SCALING-05 -REF $clk_ref -s $orig_clk_freq -s $_new_clk_freq -s $min_frequency
        } else {
          # AUTO-FREQ-SCALING-02 is for kernel clock minimum
          ::drcv::create_violation AUTO-FREQ-SCALING-02 -dynamic_category [list [list xclbin $clbinary_name]] -REF $clk_ref -s $orig_clk_freq -s $_new_clk_freq -s $min_frequency
        }
      }
      set _new_clk_freq $min_frequency
      return 0 
    }

    # runtime has a hard cap for maximum frequency of 500MHz, it the scaled frequency is larger 
    # than 500, we should cap it to 500.
    # compiler.maxFrequencyLimit
    if { $_new_clk_freq > $max_frequency } {
      puts "INFO: The maximum frequency supported by the runtime is $max_frequency MHz, which this design achieved. The compiler will not select a frequency value higher than the runtime maximum."
      if {[is_drcv]} {
        if {$clk_type eq $ocl_util::System} {
          # AUTO-FREQ-SCALING-06 is for system clock maximum
          ::drcv::create_affirmation AUTO-FREQ-SCALING-06 -s $max_frequency -REF $clk_ref -s $orig_clk_freq -s $_new_clk_freq -actual [list string $_new_clk_freq] -threshold [list string $max_frequency]
        } else {
          if { [check_kernel_count $kernel_counts $clk_id] } {
            # AUTO-FREQ-SCALING-03 is for kernel clock maximum
            ::drcv::create_affirmation AUTO-FREQ-SCALING-03 -s $max_frequency -dynamic_category [list [list xclbin $clbinary_name]] -REF $clk_ref -s $orig_clk_freq -s $_new_clk_freq -actual [list string $_new_clk_freq] -threshold [list string $max_frequency]
          }
        }
      }
      set _new_clk_freq $max_frequency
    }

    # cap the new frequency so that it is not higher than orignal frequency
    if { $_new_clk_freq > $orig_clk_freq } {
      puts "WARNING: The auto scaled frequency '$_new_clk_freq MHz' exceeds the original specified frequency. The compiler will select the original specified frequency of '$orig_clk_freq' MHz."
      if {[is_drcv]} {
        # AUTO-FREQ-SCALING-08
        # for CR 1040786 - the CR only refers to the 08 message. Perhaps all of the freq_scaling 
        # should do this - but not sure - so only address the issue in the CR.
        set abs_timing_file [ file normalize "$timing_rpt_fname" ]
        set timing_file_exists [glob -nocomplain "$abs_timing_file"]
        if { ![file exists $timing_file_exists] } {
          report_timing_summary -slack_lesser_than $worst_negative_slack -file $abs_timing_file
        }
        set clk_name [get_clock_name $clock_pin]
        # set clk_ref_08 [::drcv::create_reference FILE  -name $clk -url "file:$abs_timing_file"]
        set clk_ref_08 [::drcv::create_reference FILE  -name $clk_name -url "file:$abs_timing_file"]
        ::drcv::create_violation AUTO-FREQ-SCALING-08 -dynamic_category [list [list xclbin $clbinary_name]] -REF $clk_ref_08 -s $_new_clk_freq -s $orig_clk_freq
      }
      set _new_clk_freq $orig_clk_freq
    }

    return 1
  }

  proc get_achievable_kernel_freq {sysClkWnsTolerance kernelPinFreqArray sysPinFreqArray failingSysClksDict} {
    upvar $kernelPinFreqArray kernelPinFreqs
    upvar $sysPinFreqArray sysPinFreqs
    upvar $failingSysClksDict failingSysClks

    # initialize combined_pin_freqs
    foreach k_k [array names kernelPinFreqs] {
      set combined_pin_freqs($k_k) $kernelPinFreqs($k_k)
    }
    foreach s_k [array names sysPinFreqs] {
      set combined_pin_freqs($s_k) $sysPinFreqs($s_k)
    }

    #scale clocks
    set ret [get_achievable_kernel_freq_ $sysClkWnsTolerance combined_pin_freqs failingSysClks]
    if { $ret == "0" } {
      return $ret
    }

    #update pin freq arrays
    foreach k_k [array names kernelPinFreqs] {
      set kernelPinFreqs($k_k) $combined_pin_freqs($k_k)
    }
    foreach s_k [array names sysPinFreqs] {
      set sysPinFreqs($s_k) $combined_pin_freqs($s_k)
    }

    return $ret
  }

  # Compute the acheivable kernel frequency
  # Authur: Steven Li 
  # Input: sysClkWnsTolerance: the tolerance in which we consider the system clocks as meeting timing, typical value 0ns or -0.1ns. 
  #        kernelPinFreqArray - array containing the kernel clock pin names and their corresponding the returned scale freq
  #
  # Return: A list of achievable kernel frequencies in MHz unit with 1 decimal point
  #         For each kernel clock pin, compute the achievable kernel frequency, or unchange if the kernel clock pin is not found, or it's not connected to a clock
  #         The computed scaled frequencies are stored in the kernelPinFreqArray
  #         0 if any system clock slack < sysClkWnsTolerance
  #         1 if success

  proc get_achievable_kernel_freq_ {sysClkWnsTolerance kernelPinFreqArray failingSysClksDict} {
    upvar $kernelPinFreqArray kernelPinFreqs
    upvar $failingSysClksDict failingSysClks
    # puts "--- DEBUG: sysClkWnsTolerance is $sysClkWnsTolerance"
    # foreach kernel_pin [array names kernelPinFreqs] {
    #   set new_ocl_freq $kernelPinFreqs($kernel_pin)
    #   puts "--- DEBUG: $kernel_pin : $new_ocl_freq"
    # }

    set kernelClksToScale 0
    set success 1

    foreach kernelClkPin [array names kernelPinFreqs] {
      set pin [get_pins $kernelClkPin]
      if {$pin == ""} {
        # kernel clock pin is unconnected and optimized away
        puts "INFO: Pin $kernelClkPin not found"
        continue
      }

      set clk [get_clocks -of_objects $pin]
      if {$clk == ""} {
        # kernel clock pin is unconnected
        puts "INFO: Pin $pin has no clock"
        continue
      }
      puts "INFO: \[OCL_UTIL\] clock is '$clk' for pin '$pin'"

      # for dynamic platform (due to the dr bd boundary), it is a valid case
      # to NOT have a timing path for the secondary clock (which is used to
      # drive rtl kernel)
      set tps [get_timing_paths -group $clk]
      if {[llength $tps] == 0} {
        # kernel clock does not have timing paths
        puts "INFO: Clock $clk has no timing paths"
        continue
      }
      
      if {[info exists clkToKernelPins($clk)]} {
        lappend clkToKernelPins($clk) $kernelClkPin
      } else {
        set clkToKernelPins($clk) [list $kernelClkPin]
      }

      set kernelPinFreqs($kernelClkPin) 0
      incr kernelClksToScale 1
    }

    # puts "--- DEBUG: kernelClksToScale is $kernelClksToScale"
    # foreach _clk [array names clkToKernelPins] {
    #   set _pins $clkToKernelPins($_clk)
    #   puts "--- DEBUG: kernel clk '$_clk': $_pins"
    # }

    set tps [get_timing_paths -max_paths 1 -sort_by group]

    # tps is already sorted from worst clock to best clock
    # loop through each clock until slack >= sysClkWnsTolerance and the kernel freq is computed
    foreach tp $tps {
      set slk [get_property SLACK $tp]
      set grp [get_property GROUP $tp]
      # puts "--- DEBUG: Path=$tp\n\t Group=$grp Slack=$slk"
      #report_property $tp

      if {$grp == "**async_default**"} {
        continue
      }

      if {$slk < $sysClkWnsTolerance} {
        # slack is worse than the specified wns tolerance 
        # tolerance is specified via parameter compiler.worstNegativeSlack
        # puts "--- DEBUG: \$slk < \$sysClkWnsTolerance"
        if {[info exists clkToKernelPins($grp)]} {
          # puts "--- DEBUG: grp '$grp' exists in clkToKernelPins"
          set period [get_property PERIOD [get_clocks [get_property ENDPOINT_CLOCK $tp]]]
          set freq [expr int(10000.0 / ($period - $slk)) / 10.0]
          # puts "--- DEBUG: freq = $freq"

          foreach kernelPin $clkToKernelPins($grp) {
            # puts "--- DEBUG: set kernelPinFreqs($kernelPin) to $freq"
            set kernelPinFreqs($kernelPin) $freq
            incr kernelClksToScale -1
          }
        } else {
          # negative WNS for system clock, cannot scale frequency
          puts "WARNING: cannot scale kernel clocks: the failing system clock is $grp:$slk, the wns tolerance is $sysClkWnsTolerance"
          dict set failingSysClks $grp $slk
          # continue with other clocks until the scaled freq of all kernel clocks are computed
          set success 0
        }
      } else {
        # slack is better than the specified wns tolerance
        # puts "--- DEBUG: \$slk > \$sysClkWnsTolerance"
        if {$kernelClksToScale == 0} {
          return $success
        } else {
          if {[info exists clkToKernelPins($grp)]} {
            # puts "--- DEBUG: grp '$grp' exists in clkToKernelPins"
            # Kernel slack is within the tolerance.  Treat it as 0 so as to compute the target frequency
            if {$slk < 0} {
              set slk 0
            }
            set period [get_property PERIOD [get_clocks [get_property ENDPOINT_CLOCK $tp]]]
            set freq [expr int(10000.0 / ($period - $slk)) / 10.0]
        
            # puts "freq: $freq"

            foreach kernelPin $clkToKernelPins($grp) {
              # puts "--- DEBUG: set kernelPinFreqs($kernelPin) to $freq"
              set kernelPinFreqs($kernelPin) $freq
              incr kernelClksToScale -1
            }
          }
        }
      }
    }

    # all the clocks in kernelPinFreqs should be scaled at this point
    if { $kernelClksToScale > 0 } {
      puts "WARNING: there are $kernelClksToScale clock(s) that couldn't be scaled, scaling algorithm needs to be checked"
      # set success 0
    }

    # Not all kernel clocks are found
    return $success
}

  # round down any number to an integer
  proc round_down {val} {
    set fl [expr {floor($val)}]
    set retval [format "%.0f" $fl]
    return $retval
  }; # end round_down  

  # convert frequency in MHz to period in ns
  proc convert_freq_to_period {freq} {
    return [expr {1000.000 / $freq}]
  }; # end convert_freq_to_period

  # convert period in ns to frequency in MHz
  proc convert_period_to_freq {period} {
    return [expr {1000 / $period}] 
  }; # end convert_period_to_freq

  # initialize clkwiz debug instance run
  proc initialize_clkwiz_debug {} {
    load librdi_iptasks.so
    set partinfo [get_property PART [current_project]]
    Init_Clkwiz [current_project] test1 $partinfo
  }; # end initialize_clkwiz_debug

  # un-initialize clkwiz debug instance run
  proc uninitialize_clkwiz_debug {} {
    UnInit_Clkwiz [current_project] test1
  }; # end uninitialize_clkwiz_debug

  # get property from clkwiz instance
  proc get_clkwiz_prop {prop} {
    set val [GetClkwizProperty [current_project] test1 $prop]
    return $val
  }; # end get_clkwiz_prop

  # set clkwiz instance properties
  proc set_clkwiz_prop {clock_freq_orig clock_freq} {
    SetClkwizProperty [current_project] test1 UseFinePS true 
    # GetClosestSolution <project_name> <instance_name> <requested output frequencies of clks separated by spaces> <requested phases of clocks separated by spaces> <requested duty cycles of clocks separated by spaces> <primary clock frequency> <secondary clock frequency> <number of output clocks> <minimum output jiter used> <non default phase or duty cycle> <primitive (MMCM or PLL)> <debug mode> <clkout XiPhy Enable> <clkout XiPhy Freq>
    GetClosestSolution [current_project] test1 $clock_freq 0 50 $clock_freq_orig 0 1 false false false false false false
  }; # end set_clkwiz_prop

  # create clock constraint(s) on the output pin of mmcm for implementation, overwriting a default generated clock
  # this only works if user specifies --kernel_freq
  proc write_user_impl_clock_constraint {inst dict_clock_freqs steps_log vivado_output_dir} {
    set uninit_wiz true
    set user_impl_clk_xdc "_user_impl_clk.xdc"
    set fo_xdc_file [open $vivado_output_dir/$user_impl_clk_xdc w]

    # $clock_name is actually the kernel clock pin name
    foreach clock_name [dict keys $dict_clock_freqs] {
      set dict_clock [dict get $dict_clock_freqs $clock_name]
      set is_user_set [dict get $dict_clock is_user_set]
      if { [string equal -nocase $is_user_set "true" ] } {
        set clock_freq [dict get $dict_clock freq]
        #set clock_freq_orig [dict get $dict_clock freq_orig]
        set outpin_mmcm [get_pins [get_property SOURCE_PINS [get_clocks -of_objects [get_pins $inst/$clock_name]]]]
        # CR 1018802: there might be more than one MMCM output pins that connect to the kernel clock pin, it leads to invalid 
        # clock_period value, e.g. "10.000 10.000", to prevent this kind of problem, add the following corrective treatment 
        if { [llength $outpin_mmcm] > 1 } {
          set outpin_mmcm [lindex $outpin_mmcm 0]
          puts "WARNING: there are more than one MMCM output pins that connect to kernel clock input pin '$inst/$clock_name', this is unexpected, using the first one '$outpin_mmcm' as the MMCM output pin"
        }

        set gclock [get_clocks -of_objects [get_pins $outpin_mmcm]]
        set gclock_name [get_property NAME $gclock]
        set inpin_mmcm [get_property SOURCE $gclock]
        set clock_period [get_property PERIOD [get_clocks -of_objects [get_pins $inpin_mmcm]]]  
        # make sure clock_period is all numeric
        if { ![string is double $clock_period] } {
          puts "CRITICAL WARNING: clock period '$clock_period' is not numeric, ignoring this clock"
          continue
        }

        set clock_freq_orig [round_down [convert_period_to_freq $clock_period]]
        if { $uninit_wiz } {
          initialize_clkwiz_debug
          set uninit_wiz false
        }
        set_clkwiz_prop $clock_freq_orig $clock_freq
        set clkout0_divide [round_down [get_clkwiz_prop ChosenDiv0]]
        set divclk_divide [round_down [get_clkwiz_prop ChosenD]]
        set divide_by [expr {$clkout0_divide * $divclk_divide}]
        set multiply_by [round_down [get_clkwiz_prop ChosenM]]
    
        puts $fo_xdc_file "\n# Kernel clock overridden by user"
        puts $fo_xdc_file "create_generated_clock -name $gclock_name -divide_by $divide_by -multiply_by $multiply_by -source $inpin_mmcm $outpin_mmcm"
      }
    }
    close $fo_xdc_file 
    # read_xdc applies the constraints immediately if a design is open
    # read_xdc behaves same as add_files if there is no open design
    if {$steps_log ne ""} {
      add_to_steps_log $steps_log "internal step: read_xdc $vivado_output_dir/$user_impl_clk_xdc" [fileName]:[lineNumber [info frame]]
    }
    read_xdc $vivado_output_dir/$user_impl_clk_xdc
    
    if { !$uninit_wiz } {
      uninitialize_clkwiz_debug 
    }
  }; # end write_user_impl_clock_constraint

  # create clock constraint(s) for synthesis, overwriting the default frequency from hw_platform
  proc write_user_synth_clock_constraint {xdc_file dict_clock_freqs} {
    set fo_xdc_file [open $xdc_file a]
    foreach clock_name [dict keys $dict_clock_freqs] {
      set dict_clock [dict get $dict_clock_freqs $clock_name]
      set is_user_set [dict get $dict_clock is_user_set]
      if { [string equal -nocase $is_user_set "true" ] } {
        set clock_freq [dict get $dict_clock freq]
        set clock_period [convert_freq_to_period $clock_freq]
        puts $fo_xdc_file "\n# Kernel clock overridden by user"
        puts $fo_xdc_file "create_clock -name USER_$clock_name -period $clock_period \[get_ports $clock_name\]"
      }
    }
    close $fo_xdc_file 
  }; # end write_user_synth_clock_constraint 

  # generate a resource demand report per kernel ip instance after OOC synth is done 
  proc generate_resource_report { vivado_output_dir steps_log } {
    set all_kernel_ips [get_ips -quiet -all -filter "SDX_KERNEL==true"]
    # puts "--- DEBUG: get_ips -quiet -all -filter \"SDX_KERNEL==true\": $all_kernel_ips"
    set size_all_ips [llength $all_kernel_ips]

    if { $size_all_ips > 0 } {
      set resource_usage_report [file join $vivado_output_dir "resource.json"]
      add_to_steps_log $steps_log "internal step: generating resource usage report '${resource_usage_report}'" [fileName]:[lineNumber [info frame]]
      set rdata_file [open $resource_usage_report "w"]
      puts $rdata_file "\{"
      puts $rdata_file "    \"Used Resources\": \["
      set index_ip 0

      foreach kernel_ip $all_kernel_ips {
        puts $rdata_file "        \{"
        puts $rdata_file "            \"ip_instance\": \"$kernel_ip\","

        set rdata [get_property dcp_resource_data $kernel_ip]
        # puts "--- DEBUG: get_property dcp_resource_data $kernel_ip: $rdata"
        puts $rdata_file "            \"resources\": \["
        set rdata_list [regexp -all -inline {\S+} $rdata]
        set size_rdata_list [llength $rdata_list]
        if { $size_rdata_list > 0 } {
          set index_rdata 0
          foreach rdata_item $rdata_list {
            incr index_rdata
            set is_odd [expr {($index_rdata % 2) != 0}]
            if { $is_odd } {
              puts $rdata_file "                \{"
              puts -nonewline $rdata_file "                    \"$rdata_item\": "
            } else {
              puts $rdata_file "\"$rdata_item\""
              if { $index_rdata == $size_rdata_list } {
                puts $rdata_file "                \}"
              } else {
                puts $rdata_file "                \},"
              }
            }
          }
        }
        puts $rdata_file "            \]"
        #puts "--- DEBUG: reporting IP properties of $kernel_ip"
        #report_property $kernel_ip

        incr index_ip
        if { $index_ip == $size_all_ips } {
          puts $rdata_file "        \}"
        } else {
          puts $rdata_file "        \},"
        }
      }

      puts $rdata_file "    \]"
      puts $rdata_file "\}"
      close $rdata_file
    }
  }; # end generate_resource_report 

  proc conv_hex_bin { s } {
    binary scan [binary format H* $s] B* x
    return $x
  }

  proc conv_bin_hex { s } {
    binary scan [binary format B4 $s] H1 x
    return $x
  }

  proc getUUIDMemoryElementFilter { cell } {
    set filter "PRIMITIVE_TYPE == CLB.LUTRAM.RAM32X1S && PRIMITIVE_LEVEL == \"MACRO\" && NAME =~  ${cell}*0_0"
    return $filter
  }

  # Read the uuid from the ROM cells
  proc read_uuid_rom { cell vivado_output_dir steps_log } {
    add_to_steps_log $steps_log "internal step: Reading UUID ROM cell '$cell'" [fileName]:[lineNumber [info frame]]

    # get path to base of the UUID memory element
    set filter [getUUIDMemoryElementFilter $cell]
    set uuid_rom_cell_base [string trimright [get_cells -hierarchical -filter ${filter}] 0_]
    if {[is_empty $uuid_rom_cell_base]} {
      error2file $vivado_output_dir "UUID ROM structure not detected.  Please check the CLB.LUTRAM.RAM32X1S memory elements exist in the implemented design"
      return 1
    }

    # read INIT properties from the UUID ROM sub-memories
    set uuid_inits ""
    for {set i 0} {$i < 32} {incr i} {
      set uuid_rom_sub_cell [get_cells ${uuid_rom_cell_base}_${i}_${i}]
      if {${uuid_rom_sub_cell} eq ""} {
        error2file $vivado_output_dir "UUID ROM sub-cell not found.  Please check it exists in the implemented design: ${uuid_rom_cell_base}_${m}_${m}"
        return 1
      }

      set sub_cell_init [get_property INIT ${uuid_rom_sub_cell}]
#      puts "INFO: Read INIT=${sub_cell_init} on cell ${uuid_rom_sub_cell}"
      lappend uuid_inits $sub_cell_init
    }

    # construct the binary representation of each dword
    set dw0 ""
    set dw1 ""
    set dw2 ""
    set dw3 ""
    for {set i 0} {$i < 32} {incr i} {
      set hex_per_bit [string range [lindex $uuid_inits $i] 10 11]
      set bin_per_bit [conv_hex_bin $hex_per_bit]
      lappend dw0 [string index $bin_per_bit 7]
      lappend dw1 [string index $bin_per_bit 6]
      lappend dw2 [string index $bin_per_bit 5]
      lappend dw3 [string index $bin_per_bit 4]
    }

    lappend bin_dwords $dw3 $dw2 $dw1 $dw0

    # construct the hex representation of each dword - bit slice and rotate
    foreach dword $bin_dwords {
      set dw_hex ""
      for {set i 7} {$i >= 0} {incr i -1} {
        set nibble ""
        for {set j 3} {$j >= 0} {incr j -1} {
          append nibble [lindex $dword [expr $i * 4 + $j]]
        }
        append dw_hex [conv_bin_hex $nibble]
      }
      lappend hex_dwords $dw_hex
    }

    # construct the final hex representation of the full UUID
    set uuid ""
    foreach dword $hex_dwords {
      append uuid $dword
    }

    puts "\nINFO: Read UUID ROM value: ${uuid}\n"

    return $uuid
  }

  proc read_logic_uuid_rom { vivado_output_dir vpl_output_dir steps_log } {
    set uuid ""
    set uuid_cell [get_cells -hier -filter {BLP_LOGIC_UUID_ROM == 1}]
    if {![is_empty $uuid_cell]} {
      # read the uuid from the ROM cells
      set uuid [read_uuid_rom $uuid_cell $vivado_output_dir $steps_log]
    } else {
      error2file $vivado_output_dir "BLP_LOGIC_UUID_ROM cell not found in netlist, BLP Logic UUID not populated."
    }
    if {![is_empty $uuid]} {
      puts "\nINFO: Read UUID ROM value: ${uuid}\n"
      # and write the uuid to our int file
      set logic_uuid_file "$vpl_output_dir/logic_uuid.txt"
      set f [open $logic_uuid_file w]
      puts -nonewline $f $uuid
      close $f
    }
  }; # end update_logic_uuid_rom

  # For multi-strategy, this array maps from run names to command IDs.
  array set run_ids {}

  proc log_runs { runs } {
    # First create an entry which will be the parent of all of the parallel runs.
    # Most of the entries, like command line, aren't applicable. This is really
    # to make a hierarchy, as we don't want to put these directly under vivado,
    # but keep them separate from things like synth runs.
    set cmd_name "vivado.impl"
    set cmd_id [::vitis_log::cmd_step $cmd_name -command_line "" -args {} -log_file ""]
    ::vitis_log::status $cmd_id RUNNING
    # We do want to save this, so we can look it up later and log the completion.
    set ocl_util::run_ids($cmd_name) $cmd_id
    # Put an entry into the task log for each run.
    # #TODO: Log the full real command line, args, etc.
    foreach run $runs {
      # Create a command step name that somewhat reflects the hierarchy of run steps.
      # Currently hardcoded assuming impl runs.
      set cmd_name "vivado.impl.$run"
      set run_dir [get_property DIRECTORY $run]
      # The actual command line is set by Vivado an not readily available. Similarly,
      # we don't know the log file name that vivado will set. But it will make a runme.log,
      # so we will put that in for now, and later read it to get more information.
      set log_file [file join $run_dir runme.log]
      # Save the CmdId for each run so we can properly log the run status.
      set cmd_id [::vitis_log::cmd_step $cmd_name -dir $run_dir -log_file $log_file]
      # It would probably be better to put the running status into the actual vivado
      # run, but there are multiple complications with this (it might not get a connection,
      # and getting the cmd_id to there requires some very odd plumbing), so do it now.
      ::vitis_log::status $cmd_id RUNNING
      set ocl_util::run_ids($run) $cmd_id
    }
  }

  proc log_runs_update { runs } {
    # Add a new entry into the summary file with information we can glean from the log file.
    # (The log didn't exist when the above log_runs call was made, and the information isn't otherwise easy to get.)
    foreach run $runs {
      if { [catch {
        set cmd_id $ocl_util::run_ids($run)
        set run_dir [get_property DIRECTORY $run]
        set known_log_file [file join $run_dir runme.log]
        set fh [open $known_log_file r]
        # The log file might be long, and we only need something from about the third line.
        while {[gets $fh line] >= 0} {
          set line [string trim $line]
          # We don't explicitly handle quoted arguments, nor runs of spaces.
          set splits [split $line]
          set length [llength $splits]
          set cmd_line "vivado"
          if {$length > 1 && [lindex $splits 0] eq "with" && [lindex $splits 1] eq "args"} {
            set args {}
            set new_log_file {}
            for {set i 2} {$i < $length} {incr i} {
              set arg [lindex $splits $i]
              lappend args $arg
              if {$arg eq "-log"} {
                set new_log_file [file join $run_dir [lindex $splits [expr $i + 1]]]
              }
              append cmd_line " " $arg
            }
            ::vitis_log::update_cmd_step $cmd_id -log_file $new_log_file -args $args -command_line $cmd_line
            # We found the line we needed, so we're done with the file, and this run.
            close $fh
            break
          }
        }
      } catch_res] } {
        # Failed to open or read the file.
        puts "WARNING: Exception trying to read in log file for run $run: $catch_res"
      }
    }
  }

}; # end namespace
