#!/bin/bash

make prj_name=rendering512      report -j4
make prj_name=digit_reg512      report -j4
make prj_name=bnn512            report -j4
make prj_name=face_detection512 report -j4
make prj_name=spam_filter512    report -j4
make prj_name=optical_flow512   report -j4





