#!/bin/bash
#
#
# Batch script to submit to create atm-ocn maps
#
# Set up for bluefire
# 
# Bluefire specific batch commands:
#BSUB -P 00000000         # project number
#BSUB -n 32               # number of processors
#BSUB -R "span[ptile=32]" 
#BSUB -W 6:00             # wall-clock limit
#BSUB -q regular          # queue
#BSUB -o regrid.%J.out    # ouput filename
#BSUB -e regrid.%J.err    # error filename
#BSUB -J gen_atm_ocn_maps # job name
#BSUB -N                  # send email upon job completion

#----------------------------------------------------------------------

#----------------------------------------------------------------------
# Set user-defined parameters here
#----------------------------------------------------------------------

fileocn='/glade/proj3/cseg/mapping/grids/tx0.1v2_090127.nc'
fileatm='/glade/proj3/cseg/mapping/grids/fv0.9x1.25_070727.nc'
nameocn='tx0.1v2'
nameatm='fv0.9x1.25'

typeocn='global'
typeatm='global'

#----------------------------------------------------------------------
# Done setting user-defined parameters
#----------------------------------------------------------------------

#----------------------------------------------------------------------
# Stuff done in a machine-specific way
#----------------------------------------------------------------------

# Determine number of processors we're running on
host_array=($LSB_HOSTS)
REGRID_PROC=${#host_array[@]}

#----------------------------------------------------------------------
# Begin general script
#----------------------------------------------------------------------

cmdargs="--fileocn $fileocn --fileatm $fileatm --nameocn $nameocn --nameatm $nameatm --typeocn $typeocn --typeatm $typeatm"
cmdargs="$cmdargs --batch --nogridcheck"
env REGRID_PROC=$REGRID_PROC gen_atm_ocn_maps.sh $cmdargs
