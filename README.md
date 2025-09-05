# AVHRR_SST_to_CESM
Convert files from RDA d277007 into SST+sea ice files usable as a data ocean by CESM

### References ###
2024: NSF NCAR's Research Data Archive has implemented 
a new dataset naming convention ds277.7 -> d277007.
There should be forwarding links from old names to new, but it's best not to rely on those.
Both names are used below, to help distinguish old versus new versions of the data.
This is only for convenience; the new name is not because there was a new version of the data.

I originally converted this data set for use in the CAM6+DART Reanalysis. 
It used the AVHRR+in\_situ obs data set, not the one that includes AMSR.
The file(s) containing data from from the start through 2019 
came from RDA ds277.7 before 2021.  That source data is described by
https://journals.ametsoc.org/view/journals/clim/20/22/2007jcli1824.1.xml,
but is no longer available.  It also had an error in the metadata;
the reference date+time was Jan. 1 1978 00 UTC, the data was "valid at 12 UTC", 
but the times were whole numbers.
It has been replaced by data described in
https://journals.ametsoc.org/view/journals/clim/34/18/JCLI-D-21-0001.1.xml
This updated data set was used for the 2020 Reanalysis (a continuation 
of the CAM6+DART Reanalysis) and for the new whole-time-span file (1981-2025).
The metadata and time variable are consistent in the new dataset.
