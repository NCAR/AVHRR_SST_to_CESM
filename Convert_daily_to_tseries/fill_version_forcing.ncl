; script reads avhrr forcing file and fills in the land points 
; 
; 31 August 10
; BT
;--------------------------------------------------------------------------------------------------
;
;--------------------------------------------------------------------------------------------------
begin
;  CYEAR is set in the calling script (fill_sst_forcing.csh, or avhrr_sst_to_cesm.csh in the old days)
   cyear = getenv("CYEAR")
   avhrr_version = getenv("PRODUCT")

   dir_in = "/glade/scratch/raeder/SST/" + avhrr_version + "/"
   dir_out = dir_in

   date_ymd = systemfunc("date +%y%m%d")

;   if( (cyear .eq. "201912") ) then
;;     avhrr_v2.1-only-v2.201912.nc 
;      file_in  = "avhrr_v2.1-only-v2." + cyear + ".nc"
;      file_out = "avhrr_v2.1-only-v2." + cyear + "_filled_c" + date_ymd + ".nc"

; Won't be entered when YYYYMM is passed as CYEAR
   if( (cyear .eq. "2021") ) then
;     avhrr_v2.1-only-v2.20200101-20200607.nc
;     2021 has data from only v2.1, so product can be explicitly named
      file_in  = "avhrr_v2.1-only-v2." + cyear + ".nc"
      file_out = "avhrr_v2.1-only-v2." + cyear + "0101-0930_filled_c" + date_ymd + ".nc"
   else if ( (cyear .eq. "1981") ) then
      file_in  = avhrr_version + "-only-v2." + cyear + "0901_cat_" + cyear + "1231_gregorian.nc"
      file_out = avhrr_version + "-only-v2." + cyear + "0901_cat_" + cyear + "1231_filled_c" + date_ymd + ".nc"
   else
;     Old files (00Z) or new files (12Z)
;     avhrr-only-v2.202001.nc
      file_in  = avhrr_version + "-only-v2." + cyear + ".nc"
      file_out = avhrr_version + "-only-v2." + cyear + "_filled_c" + date_ymd + ".nc"
   end if
   end if
; NCL requires a separate 'end if' for each 'if' and 'else if'

;--------------------------------------------------------------------------------------------------
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   pwd = systemfunc("pwd")
;==================================================================================================
; copy input file to output file to save time
; 
   print("copying file to make file template...")
   time_date = systemfunc("date")
   print(cyear + "   " + time_date)
   print("")

   system("cp " + dir_in + file_in + " " + dir_out + "tmp_" + file_out )

   f_in = addfile(dir_in +  file_in, "r")
   f_out = addfile(dir_out + "tmp_" + file_out, "w")

;--------------------------------------------------------------------------------------------------
   SST_cpl = f_in->SST_cpl
;--------------------------------------------------------------------------------------------------
   guess     = 1                ; use zonal means
   is_cyclic = True             ; cyclic [global]
   nscan     = 2000             ; usually much less than 1500 - BT using 2000
   eps       = 1.e-4            ; variable dependent
   relc      = 0.6              ; relaxation coefficient
   opt       = 0                ; not used

   print("calling Poisson filler...")
   time_date = systemfunc("date")
   print(cyear + "   " + time_date)
   print("")

   poisson_grid_fill( SST_cpl, is_cyclic, guess, nscan, eps, relc, opt)
;--------------------------------------------------------------------------------------------------
   print("Writing file...")
   time_date = systemfunc("date")
   print(cyear + "   " + time_date)
   print("")

   f_out->SST_cpl=SST_cpl
   system("mv " + dir_out +"tmp_" + file_out + " " + dir_out + file_out )
   print("-----------------------------------------------------------------------------------------")
;--------------------------------------------------------------------------------------------------
;================================================================================================
end
