#!/bin/csh -x

#PBS  -N avhrr_sst_to_cesm
#PBS  -A P86850054
#PBS  -q casper
# Resources I want:
#    select=#nodes
#    ncpus=#CPUs/node
#    mpiprocs=#MPI_tasks/node
#PBS  -l select=1:ncpus=1:mpiprocs=1
#PBS  -l walltime=03:00:00
# Send email after a(bort) or e(nd)
#PBS  -m ae
#PBS  -M raeder@ucar.edu
# Send standard output and error to this file.
# It's helpful to use the $casename here.
#PBS  -o avhrr_v2.1_202110-202209.eo
#PBS  -j oe 
#--------------------------------------------

# It may be possible to submit this as an interactive job using
# > /glade/u/home/raeder/Scripts/qcmd_share_1cpu.csh ./avhrr_sst_to_cesm.csh 

# User set variables.

# This script only deals with the avhrr files that were reprocessed in 2020,
# which have times valid at 12Z and have time labels (whole numbers) 
# that are consistent with the "days since" metadata, which has 12Z in its definition.
set product = avhrr_v2.1

# These files have sst and sea ice in them.
set dir_in  = /gpfs/fs1/collections/rda/data/ds277.7/${product}/
set dir_out = /glade/scratch/raeder/SST/${product}

set dom_dir  = /gpfs/fs1/work/raeder/Models/CAM_init/SST
set dom_file = domain.ocn.d025.120821.nc

if ($#argv == 1) then
   # Interactive job
   set years = ($1)
else
   set years = ( 2021 2022 )
endif

cd $PBS_O_WORKDIR

echo "Starting at `date`"

# If not in my environment already:
# 2022-10-31; gnu is needed for nco, and is not loaded in my environment by default
#    This load causes replacing "intel/19.1.1" with "gnu/10.1.0".
#    Due to MODULEPATH changes, the following have been reloaded:
#      1) ncarcompilers/0.5.0     2) netcdf/4.8.1     3) openmpi/4.1.1
module load gnu
# Also, on casper nco is not loaded by default, but is on cheyenne
module load nco
module list
which ncwa
if ($status != 0) exit 17
echo "Done loading modules"
echo "----------------------------------------------------"

#----------------------------------------------------------------------------------------------------------------
if (! -d ${dir_out} ) then
   mkdir ${dir_out}
endif
cd ${dir_out}
#----------------------------------------------------------------------------------------------------------------
#untar
foreach yr ( $years )
#----------------------------------------------------------------------------------------------------------------
#    set tar_files = `ls -1 ${dir_in}/${product}_nc_v2_${yr}??.tar`
#    foreach tar_file ( ${tar_files} )
#       tar -xvf ${tar_file} 
   if (! -d $yr) then
      mkdir $yr
      cd $yr
      if ($yr == 2021) then
         # Get months 10...12
         cp ${dir_in}/${yr}/*avhrr*.${yr}1* .
      else if ($yr == 2022) then
         # Get months 1...9
         cp ${dir_in}/${yr}/*avhrr*.${yr}0* .
#          cp ${dir_in}/${yr}/*avhrr*.${yr}* .
      endif
      echo "post cp from $dir_in : "
      ls
   else
      cd $yr
   endif
#----------------------------------------------------------------------------------------------------------------
#  Output file for this first stage (next stage is the ncl program).
   set file_out = ${product}-only-v2.${yr}.nc
   echo ${file_out}

# Want to use ncrcat.

# Change 'time' to a record (unlimited) dimension.
# (which it should have been to start with).
# -v sst,ice  = subset the variables
   foreach f (`ls -1 *avhrr*.nc`)
      if (! -f temp_$f) then
         # Do first, to make zlev(zlev) a scalar var 
         # which will be removed by ncks.
         ncwa -O -a zlev -o nozlev.nc $f
         ncks --mk_rec_dmn time  -v sst,ice nozlev.nc temp_$f
      endif
   end
   ls temp*
   rm nozlev.nc

#  Concatenate all of the daily files into a yearly file.
#  -O = overwrite existing output file
#  -h = don't propagate the history (I may want to)
#  Make time the record dimension in the ncecat call; -u time?
#    No, that caused an error.
#    Let ncecat make the file with the default record dimension 'record',
#    then fix it all.
   if (! -f ../temp_${file_out}) then
      ncrcat -O temp_* ../temp_${file_out} 
   else
      echo "`pwd`/../temp_${file_out} exists. Exiting"
      exit 5
   endif 

   cd ..

# Add vars from 1/4 degree domain file
# 	nj = 720 ;
# 	ni = 1440 ;
# 	int mask(nj, ni) ;
# 	double area(nj, ni) ;
   if (! -f ${dom_file}) then
      ncrename -d ni,lon -d nj,lat ${dom_dir}/${dom_file} ${dom_file} 
   endif
# -C; don't copy over the ancillary variables of mask, area (xc,xv,yc,yv)
# -A; append onto temp_${file_out}
   ncks -A -C -v mask,area ${dom_file} temp_${file_out}   
   
# Change variable precision from short to float
   ncap2 -s 'sst=float(sst);ice=float(ice);area=float(area)' temp_${file_out} ${file_out} 
# Debug; don't delete   if ($status == 0) rm temp_${file_out}

# rename variables: sst -> SST_cpl, ice -> ice_cov
   ncrename -v sst,SST_cpl -v ice,ice_cov ${file_out} 

# Add 'calendar=gregorian attribute' to the time variable
   ncatted -a calendar,time,c,c,gregorian ${file_out} 

   echo "Finished $yr at `date`"

end # next year
