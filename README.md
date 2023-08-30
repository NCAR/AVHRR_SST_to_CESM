# AVHRR_SST_to_CESM
Convert files from RDA ds277.7 into SST+sea ice files usable as a data ocean by CESM

### References ###
Files containing data from from the start through 2019 came from NCAR's RDA ds277-7 before 2021.
The CAM6+DART Reanalysis used the AVHRR+in\_situ obs data set, not the one that includes AMSR.
That source data is described by
https://journals.ametsoc.org/view/journals/clim/20/22/2007jcli1824.1.xml,
but is no longer available.
It has been replaced by data described in
https://journals.ametsoc.org/view/journals/clim/34/18/JCLI-D-21-0001.1.xml
This updated data set was used for the 2020 Reanalysis.
avhrr....nc files that do not contain data for 2011-2018 used this updated ds277-7 dataset.
