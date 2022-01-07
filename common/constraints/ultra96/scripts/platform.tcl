
# Library provides Tcl commnds to access the new platform APIs
# puts "LD_LIBRARY_PATH is $env(LD_LIBRARY_PATH)"
load librdi_platformtcl[info sharedlibextension]

# Tcl commands implemented in C++ are:
# ::platform::keys - to report on all the JSON keys
# ::platform::query - to query data
# ::platform::xpfm_paths - to find platform files

# Additional Tcl commands to be provided in Tcl, based on feedback.
# For now, we have the following.

namespace eval platform {

  # The following will likely change, so just define it here once
  set hw_ext_path hardwarePlatform.extensions
  # if file passed in is an xsa/dsa, the prefix is just "extensions"
  # as JSON tree corresponds to hardwarePlatform object
  set hw_ext_path_for_xsa extensions

  package require json

  # Returns the hardware platform extension metadata in JSON format for the supplied
  # key. The key is the root of the JSON when it is added to the hardware platform using
  # write_hw_platform -ext_metadata. Does no checking that the key is valid. If data
  # for the key doesn't exist, returns empty string.
  # pfm_path could be a .xpfm file or .xsa/.dsa file
  proc get_hw_ext_json { pfm_path key } {
    set full_key $::platform::hw_ext_path.$key
    # puts "pfm_path is $pfm_path; full_key is $full_key"

    set file_extension [file extension $pfm_path]
    if {[string equal $file_extension ".xsa"] || [string equal $file_extension ".dsa"]} {
        set full_key $::platform::hw_ext_path_for_xsa.$key
    }

    # Even though the switch name is -xpfm, switch takes xpfm, xsa and dsa as input
    # change switch name to pfm? check with emenchen.
    set ext_json [::platform::query -xpfm $pfm_path -key $full_key]
    # puts "ext_json is $ext_json"
    return $ext_json
  }

  # Returns a Tcl dictionary of the hardward platform extension data for the
  # supplied key. The key is the root of the JSON data when it is added to the
  # hardware platform using write_hw_platform -ext_metadata.
  proc get_hw_ext_dict { pfm_path key } {
    set ext_json [::platform::get_hw_ext_json $pfm_path $key]
    set ext_dict [::json::json2dict $ext_json]
    return $ext_dict
  }
}

