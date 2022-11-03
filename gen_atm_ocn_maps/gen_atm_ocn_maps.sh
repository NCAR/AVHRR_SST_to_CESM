#!/bin/bash
#===============================================================================
# SVN $Id: gen_atm_ocn_maps.sh 37347 2012-05-25 18:12:14Z mlevy@ucar.edu $
# SVN $URL: https://svn-ccsm-models.cgd.ucar.edu/tools/mapping/trunk_tags/mapping_120525/gen_atm_ocn_maps/gen_atm_ocn_maps.sh $
#
# Create needed mapping files for gen_domain and coupler mapping
# Currently only supported on bluefire and jaguarpf - and only in
# interactive mode
# 
#===============================================================================
echo $0
date
SDIR=`dirname $0`

#===============================================================================
# Usage subroutine
#===============================================================================
usage() {
  echo ''
  echo '**********************************************************'
  echo 'usage on bluefire:'
  echo './gen_atm_ocn_maps.sh  '
  echo ' Creates conservative and bilinear mapping files for'
  echo ' ocean grid to atm grid AND atm grid to ocn grid mapping'
  echo ' The resulting conservative ocean mapping file should be used as'
  echo ' input to gen_domain - which must be built first '
  echo ' If the ocean and atm grids are identical - then the mapping file'
  echo ' will simply be unity - and the atm fraction will simply be just ' 
  echo ' one minus the ocean fraction us'
  echo ''
  echo 'gen_atm_ocn_maps.sh '
  echo '  --fileocn|-focn  input ocn_grid_filename (required) '
  echo '  --fileatm|-fatm  input atm_grid_filename (required)'
  echo '  --nameocn|-nocn  output ocn_name in mapping file (required)' 
  echo '  --nameatm|-natm  output atm_name in mapping file (required)'
  echo '  [ --typeocn|tocn ] [regional|global]'
  echo '  [ --typeatm|tatm ] [regional|global]'
  echo '  [ --nogridcheck ]'
  echo '  [ --batch|-b ]'
  echo '  [ --help|-h ]'
  echo '  [ -v ]'
  echo ' '
  echo 'where '
  echo ' --fileocn (or -focn) '
  echo '   SCRIP grid format ocean filename (full pathname)'
  echo ' --fileatm (or -fatm) '
  echo '   SCRIP grid format atmosphere filename (full pathname)'
  echo ' --nameocn (or -nocn) and --nameatm (or -nocn) will result in the '
  echo '   following mapping files'
  echo '     nameocn_TO_nameatm_aave.cdate.nc'
  echo '     nameocn_TO_nameatm_blin.cdate.nc'
  echo '     nameatm_TO_nameocn_aave.cdate.nc'
  echo '     nameatm_TO_nameocn_blin.cdate.nc'
  echo ' --typeocn (or -tocn) '
  echo '   ocean grid type,  valid values are regional or global'
  echo '   default is global'
  echo ' --typeatm (or -tatm) '
  echo '   atm grid type, valid values are regional or global'
  echo '   default is global'
  echo ' --nogridcheck '
  echo '   By default, script will run consistency check on new'
  echo '   maps; this flag disables these checks'
  echo ' --batch (or -b) '
  echo '   Toggles batch mode usage. If you want to run in batch mode'
  echo '   you need to have a separate batch script for a supported machine'
  echo '   that calls this script interactively - you cannot submit this'
  echo '   script directly to the batch system'
  echo ' -rc '
  echo '   Pass the "--recompile" flag to the ESMF tool'
  echo '   (Only necessary if nothing has been built in ../check_maps/)'
  echo ' -d '
  echo '   toggle debug-only '
  echo ' --help or -h  '
  echo '   displays this help message'
  echo ''
  echo 'You can also set the following env variables:'
  echo '  ESMFBIN_PATH - Path to ESMF binaries '
  echo '                 (default is /contrib/esmf-5.2.0r-64-O/bin)'
  echo '  MPIEXEC ------ Name of mpirun executable'
  echo '                 (default is mpirun.lsf)'
  echo '  REGRID_PROC -- Number of MPI processors to use'
  echo '                 (default is 8)'
  echo '**********************************************************'
}

#===============================================================================
# runcmd subroutine
#===============================================================================
runcmd() {
   cmd=$@
   if [ -z "$cmd" ]; then
       echo "No command given to the runcmd function"
       exit 3
   fi
   if [ "$verbose" = "YES" ]; then
       echo "$cmd"
   fi
   if [ "$debug" != "YES" ]; then
       ${cmd}
       rc=$?
   else
       rc=0
   fi
   if [ $rc != 0 ]; then
       echo "Error status returned from gen_atm_ocn_maps script"
       exit 4
undo
   fi
   return 0
}

#===============================================================================
# Main program
#===============================================================================

#-------------------------------------------------------------------------------
# Process input arguments
#-------------------------------------------------------------------------------

interactive="YES"
debug="no"
verbose="no"
type_atm="global"
type_ocn="global"
CheckMapsFlag=""


while [ $# -gt 0 ]; do
   case $1 in
       -v)
	   verbose="YES"
	   ;;
       -b|--batch)
	   interactive="NO"
	   ;;
       -focn|--fileocn )
	   focn=$2
	   shift
	   ;;
       -fatm|--fileatm )
	   fatm=$2
	   shift
	   ;;
       -nocn|--nameocn )
	   nocn=$2
	   shift
	   ;;
       -natm|--nameatm )
	   natm=$2
	   shift
	   ;;
       -tocn|--typeocn )
	   type_ocn=$2
	   echo "type_ocn is $type_ocn"
	   shift
	   ;;
       --recompile|-rc )
	   CheckMapsFlag=-rc
	   echo "Will recompile ESMF gridcheck tool"
	   ;;
       --nogridcheck )
	   SkipGridCheck=TRUE
	   echo "Will not check quality of maps!"
	   ;;
       -tatm|--typeatm )
	   type_atm=$2
	   echo "type_atm is $type_atm"
	   shift
	   ;;
       -h|--help )
	   usage
	   exit 0
	   ;;
       * )
	   echo "****************************"
	   echo "ERROR:: invalid argument $1"
	   echo "****************************"
	   usage
	   exit 1
	   ;;
   esac
   shift 
done

# check for required arguments
echo "fatm is $fatm"
echo "focn is $focn"
if [ -z "$focn" ]; then
    echo "Must specfiy -focn or --fileocn argument "
    echo "Invoke gen_maps.sh -h for usage"
    exit 1
fi
if [ -z "$fatm" ]; then
    echo "Must specfiy -fatm or --fileatm argument "
    echo "Invoke gen_maps.sh -h for usage"
    exit 2
fi
if [ -z "$natm" ]; then
    echo "Must specfiy -natm or --nameatm argument "
    echo "Invoke gen_maps.sh -h for usage"
    exit 2
fi
if [ -z "$nocn" ]; then
    echo "Must specfiy -nocn or --nameocn argument "
    echo "Invoke gen_maps.sh -h for usage"
    exit 2
fi


# check for existence of files
if [ ! -f "${focn}" ]; then
   echo "Input grid file does NOT exist: $focn}"
   exit 2
fi
if [ ! -f "${fatm}" ]; then
   echo "Output grid file does NOT exist: $fatm"
   exit 3
fi

# set some defaults
if [ -z "$REGRID_PROC" ]; then
   REGRID_PROC=8
fi

#-------------------------------------------------------------------------------
# Machine specific env stuff
#-------------------------------------------------------------------------------
 
hostname=`hostname`
case $hostname in
  ##bluefire
  be* )
	if [ -z "$ESMFBIN_PATH" ]; then
	    ESMFBIN_PATH=/contrib/esmf-5.2.0r-64-O/bin
	fi
	if [ -z "$MPIEXEC" ]; then
	    MPIEXEC="mpirun.lsf"
	fi
	
	if [ ! -z "$MP_EUIDEVICE" ]; then
		# Disable MP_EUIDEVICE to avoid warning message
		MP_EUIDEVICE_tmp=$MP_EUIDEVICE
		unset MP_EUIDEVICE
	fi

	if [ ! -z "$MP_INSTANCES" ]; then
		# Disable MP_INSTANCES to avoid warning message
		MP_INSTANCES_tmp=$MP_INSTANCES
		unset MP_INSTANCES
	fi

	if [ "$interactive" = "YES" ]; then
            # specific commands to prepare to run interactively
            # on bluefire
	    export MP_PROCS=$REGRID_PROC
	    export MP_EUILIB=ip
	    
	    hostname > hostfile
	    declare -i p=2
	    until ((p>$MP_PROCS)); do
		hostname >> hostfile
		p=p+1
	    done
	    export MP_HOSTFILE=hostfile
	fi
	;;
	
    ##jaguarpf
    ## NOTE that for jaguarpf there is no batch script for now
    jaguarpf* )
	if [ -z "$ESMFBIN_PATH" ]; then
	    module load esmf/5.2.0-p1_with-netcdf_g
	    ESMFBIN_PATH=$ESMF_BINDIR
	fi
	if [ -z "$MPIEXEC" ]; then
	    MPIEXEC="aprun -n $REGRID_PROC"
	fi
	;;
    
    *)
	echo "Machine $hostname NOT recognized"
	;;
    
esac

#-------------------------------------------------------------------------------
# run ESMF_RegridWeightGen
#-------------------------------------------------------------------------------

# Resolve interactive or batch mode command
# NOTE - if you want to run in batch mode - you need to have a separate
# batch file that calls this script interactively - you cannot submit
# this script to the batch system

if [ "$interactive" = "YES" ]; then
    mpirun=""
    echo "Running interactively"
else
    if [ -z "$MPIEXEC" ]; then
	echo "Name of MPI exec to use was NOT set"
	echo "Set the environment variable: MPIEXEC"
	exit 1
    fi
    mpirun=$MPIEXEC
    echo "Running in batch mode"
fi

if [ ! -d "$ESMFBIN_PATH" ]; then
    echo "Path to ESMF binary directory does NOT exist: $ESMFBIN_PATH"
    echo "Set the environment variable: ESMFBIN_PATH"
    exit 1
fi

ESMF_REGRID="$ESMFBIN_PATH/ESMF_RegridWeightGen"

if [ ! -x "$ESMF_REGRID" ]; then
    echo "ESMF_RegridWeightGen does NOT exist in ESMF binary directory: $ESMFBIN_PATH\n"
    echo "Upgrade to a newer version of ESMF with this utility included"
    echo "Set the environment variable: ESMFBIN_PATH"
    exit 1
fi

# Remove previous log files
rm -f PET*.Log

# Set output map name and create it
#date="c"`date +%y%m%d`    omit extraneous "c" character in date stamp
cdate=`date +%y%m%d`

mapname=${nocn}_TO_${natm}
fmap_o2a_aave=map_${mapname}_aave.${cdate}.nc
fmap_o2a_blin=map_${mapname}_blin.${cdate}.nc

mapname=${natm}_TO_${nocn}
fmap_a2o_aave=map_${mapname}_aave.${cdate}.nc
fmap_a2o_blin=map_${mapname}_blin.${cdate}.nc
fmap_a2o_patc=map_${mapname}_patc.${cdate}.nc

echo ""
echo "Ocn  grid file type is $type_ocn"
echo "Atm  grid file type is $type_atm"
echo ""

#--- ocn to atm conservative (area avg?) ---------------------------------------
echo "----------------------------------------------------------"
fmap=$fmap_o2a_aave

echo "Creating $fmap"
echo "From ocn  grid: $focn"
echo "To   atm  grid: $fatm"
echo ""

cmd="$mpirun $ESMF_REGRID --ignore_unmapped -m conserve -w $fmap -s $focn -d $fatm"

if [ $type_ocn == "regional" ]; then
    cmd="$cmd --src_regional"
    echo "regional ocean"
fi
if [ $type_atm == "regional" ]; then
    cmd="$cmd --dst_regional"
    echo "regional atm "
fi
echo "cmd is $cmd"
runcmd $cmd
if [ "$debug" != "YES" ] && [ ! -f "$fmap" ]; then
   echo "Output mapping file $fmap was NOT created: $fmap"
   exit 4
fi
HOST=`hostname`
history="$ESMF_REGRID"
runcmd "ncatted -a history,global,a,c,$history -a hostname,global,a,c,$HOST -a logname,global,a,c,$LOGNAME $fmap"

echo "Successfully created mapping file $fmap "

#--- ocn to atm bilinear (non-conservative) ------------------------------------
echo "----------------------------------------------------------"
fmap=$fmap_o2a_blin

echo "Creating $fmap"
echo "From ocn  grid: $focn"
echo "To   atm  grid: $fatm"
echo ""

cmd="$mpirun $ESMF_REGRID --ignore_unmapped -m bilinear -w $fmap -s $focn -d $fatm"

if [ $type_ocn == "regional" ]; then
    cmd="$cmd --src_regional"
    echo "regional ocn"
fi
if [ $type_atm == "regional" ]; then
    cmd="$cmd --dst_regional"
    echo "regional atm "
fi
echo "cmd is $cmd"
runcmd $cmd
if [ "$debug" != "YES" ] && [ ! -f "$fmap" ]; then
   echo "Output mapping file $fmap was NOT created: $fmap"
   exit 4
fi
HOST=`hostname`
history="$ESMF_REGRID"
runcmd "ncatted -a history,global,a,c,$history -a hostname,global,a,c,$HOST -a logname,global,a,c,$LOGNAME $fmap"

echo "Successfully created mapping file $fmap "

#--- ocn to atm conservative (area avg?) ---------------------------------------
echo "----------------------------------------------------------"
fmap=$fmap_a2o_aave

echo "Creating $fmap"
echo "From atm  grid: $fatm"
echo "To   ocn  grid: $focn"
echo ""

cmd="$mpirun $ESMF_REGRID --ignore_unmapped -m conserve -w $fmap -s $fatm -d $focn"

if [ $type_ocn == "regional" ]; then
    cmd="$cmd --src_regional"
    echo "regional atm"
fi
if [ $type_atm == "regional" ]; then
    cmd="$cmd --dst_regional"
    echo "regional ocn "
fi
echo "cmd is $cmd"
runcmd $cmd
if [ "$debug" != "YES" ] && [ ! -f "$fmap" ]; then
   echo "Output mapping file $fmap was NOT created: $fmap"
   exit 4
fi
HOST=`hostname`
history="$ESMF_REGRID"
runcmd "ncatted -a history,global,a,c,$history -a hostname,global,a,c,$HOST -a logname,global,a,c,$LOGNAME $fmap"

echo "Successfully created mapping file $fmap "

#--- atm to ocn bilinear (non-conservative) ------------------------------------
echo "----------------------------------------------------------"
fmap=$fmap_a2o_blin

echo "Creating $fmap"
echo "From atm  grid: $fatm"
echo "To   ocn  grid: $focn"
echo ""

cmd="$mpirun $ESMF_REGRID --ignore_unmapped -m bilinear -w $fmap -s $fatm -d $focn"

if [ $type_atm == "regional" ]; then
    cmd="$cmd --src_regional"
    echo "regional atm"
fi
if [ $type_ocn == "regional" ]; then
    cmd="$cmd --dst_regional"
    echo "regional ocn "
fi
echo "cmd is $cmd"
runcmd $cmd
if [ "$debug" != "YES" ] && [ ! -f "$fmap" ]; then
   echo "Output mapping file $fmap was NOT created: $fmap"
   exit 4
fi
HOST=`hostname`
history="$ESMF_REGRID"
runcmd "ncatted -a history,global,a,c,$history -a hostname,global,a,c,$HOST -a logname,global,a,c,$LOGNAME $fmap"

echo "Successfully created mapping file $fmap "

#--- atm to ocn patch mapping (non-conservative) -------------------------------
echo "----------------------------------------------------------"
fmap=$fmap_a2o_patc

echo "Creating $fmap_a2o_patc"
echo "From atm  grid: $fatm"
echo "To   ocn  grid: $focn"
echo ""

cmd="$mpirun $ESMF_REGRID --ignore_unmapped -m patch -p all -w $fmap -s $fatm -d $focn"

if [ $type_atm == "regional" ]; then
    cmd="$cmd --src_regional"
    echo "regional atm"
fi
if [ $type_ocn == "regional" ]; then
    cmd="$cmd --dst_regional"
    echo "regional ocn "
fi
echo "cmd is $cmd"
runcmd $cmd
if [ "$debug" != "YES" ] && [ ! -f "$fmap" ]; then
   echo "Output mapping file $fmap was NOT created: $fmap"
   exit 4
fi
HOST=`hostname`
history="$ESMF_REGRID"
runcmd "ncatted -a history,global,a,c,$history -a hostname,global,a,c,$HOST -a logname,global,a,c,$LOGNAME -a map_method,global,o,c,patch $fmap"

echo "Successfully created mapping file $fmap "

# Run ESMF Regrid Weight Check tool
if [ ! -z "$SkipGridCheck" ]; then
	echo "Skipping the consistency check"
	rm -f hostfile
	exit 0
fi
echo "----------------------------------------------------------"

CHECK_MAP="$SDIR/../check_maps/check_map.sh ${CheckMapsFlag}"

echo "Running ESMF Regrid Weight Check tool for each generated map"
runcmd "${CHECK_MAP} ${fmap_o2a_aave} \
                     ${fmap_o2a_blin} \
                     ${fmap_a2o_aave} \
                     ${fmap_a2o_blin} \
                     ${fmap_a2o_patc}"

rm -f hostfile

if [ ! -z "$MP_EUIDEVICE_tmp" ]; then
	# Re-enable MP_EUIDEVICE (if previously defined)
	export MP_EUIDEVICE=$MP_EUIDEVICE_tmp
fi

if [ ! -z "$MP_INSTANCES_tmp" ]; then
	# Re-enable MP_EUIDEVICE (if previously defined)
	export MP_INSTANCES=$MP_INSTANCES_tmp
fi

exit 0

#===============================================================================
