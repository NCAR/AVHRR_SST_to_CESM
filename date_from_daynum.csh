#!/bin/tcsh

# Calculate the date, given the day numbers that appear in the avhrr files,
# which are from 1978-01-01, WHICH IS DAY 0.

set day78 = $1

set days_in_mo = (31 28 31 30 31 30 31 31 30 31 30 31)

# Account for the 0-based numbering in the files.
@ rem_days = $day78 + 1
set year = 1978
set days_this_year = 365
# Subtract out and count the whole years, including leap years.
while ($rem_days > $days_this_year) 
   @ rem_days = $rem_days - 365
   if (($year % 4) == 0) then
      @ rem_days--
      set days_this_year = 365
   endif

   if ($rem_days > 0) @ year++
   if (($year % 4) == 0) set days_this_year = 366

end

# If the last, partial year is a leap year, update Feb days_in_mo.
if (($year % 4) == 0) set days_in_mo[2] = 29

# Subtract off the whole months to identify the month 
# and be left with the day of the month.
set mo = 1
while ($rem_days > $days_in_mo[$mo] )
   @ rem_days = $rem_days - $days_in_mo[$mo]  
   @ mo++
end

set day = $rem_days

echo "$year-$mo-$day"

exit

Tests
> ./date_from_daynum.csh 30
  1978-1-31
> ./date_from_daynum.csh 364
  1978-12-31
> ./date_from_daynum.csh 365
  1979-1-1
> ./date_from_daynum.csh 730
  1980-1-1
> ./date_from_daynum.csh 779
  1980-2-19
> ./date_from_daynum.csh 789
  1980-2-29
> ./date_from_daynum.csh 1154
  1981-2-28
> ./date_from_daynum.csh 1155
  1981-3-1
