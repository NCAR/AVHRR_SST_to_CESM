#!/bin/csh 

#PBS  -N fill_sst_forcing
#PBS  -A P86850054
#PBS  -q share
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
#PBS  -o fill_v2.1_201912.eo
#PBS  -j oe 
#--------------------------------------------
# Fills in the land areas using a Poisson scheme.
# This solves problems created when there are grid boxes where CAM
# expects to find an SST value but there isn't one in the Reynold's SST (there is land).

# If not in my environment already:
module swap gnu/10.1.0 gnu/8.3.0
module load ncl
module list
which ncl
if ($status != 0) exit 17

set echo verbose

# set years = ( 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 \
#                                        2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 \
#                                        2010 2011 2012 2013 )
set years = ( 2021 2022 )
# set years = ( 201912 )
set product = avhrr_v2.1
# set product = avhrr
set dir_out = /glade/scratch/raeder/SST/${product}

cd ${dir_out}
foreach year ($years)
   setenv CYEAR $year
   setenv PRODUCT $product
#    ncl /gpfs/fs1/work/raeder/Models/CAM_init/SST/Make_yearly_from_daily/fill_sst_forcing.ncl |& tee ncl_${year}.eo
   ncl /gpfs/fs1/work/raeder/Models/CAM_init/SST/Make_yearly_from_daily/fill_version_forcing.ncl |& tee ncl_${year}.eo

#    ncl fill_sst_forcing.ncl
end

exit
