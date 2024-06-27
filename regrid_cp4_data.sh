#!/bin/bash

## A file adapted by Fran Morris (francesca.morris@ouce.ox.ac.uk) 25/06/2022
## from a file that was ... 
## Adapted by Fran Morris (f.a.morris@leeds.ac.uk) 10/11/2022
## from a file that was ... 
## Created by Declan Finney (d.l.finney@leeds.ac.uk) 21/05/2018
## with help from Lawrence Jackson.

## This script will 
## - Select the 700hPa pressure level from the u and v files
## - Select only 6-hourly intervals
## - Regrid these files to 1x1 degree resolution
## - Combine the files into a single netCDF4 file (for each month, currently)
## - Merge the files and rename them such that they have the right convention 
##   to be used by the QTrack AEW tracker


YEAR_STR=1999
MODEL=R25

for MODEL in CP4 R25 ;do

    for STASH in f30201 f30202 ;do

        if [ "$STASH" = a04203 ]; then
            STASH_ref=a05216
        else
            STASH_ref=$STASH
        fi

        if [ "$MODEL" = CP4 ]; then
            files=/nfs/a277/IMPALA/data/4km/$STASH/*$YEAR_STR*$YEAR_STR*.nc
        elif [ "$MODEL" = R25 ]; then
            files=/nfs/a277/IMPALA/data/25km/$STASH/*$YEAR_STR*$YEAR_STR*.nc
        else
            echo "No valid model specified. Please select CP4 or R25."
        fi
        
        dir=regrid_${MODEL}_${STASH}
        mkdir -p $dir
        for filen in $files ;do
            echo $filen
            filen_out=$dir/${filen:33:52}_regrid.nc

            # assuming timesteps start at 0300 then go 3-hourly to 0000 the next day
            # note that cdo timesteps use indexing starting at 1 
            # selecting only data at 700 hPa
            cdo -sellonlatbox,335,415,-20,40 -remapcon,r360x180 -seltimestep,2,4,6,8 -sellevel,700 $filen $filen_out
        
        done
        #combine files for all times
        cdo -mergetime $dir/$STASH*$YEAR_STR*.nc $dir/${YEAR_STR}.nc
        #remove files for separate times
        rm -rf $dir/$STASH*$YEAR_STR*.nc
    done

    #merge u (f30201) and v (f30202) files
    cdo merge regrid_${MODEL}_f30201/${YEAR_STR}.nc regrid_${MODEL}_f30202/${YEAR_STR}.nc ${MODEL}_${MONTH_STR}.nc
    #change name of f30201 and f30202 to u and v respectively.
    cdo -chname,f30201,u -chname,f30202,v ${MODEL}_${YEAR_STR}.nc ${MODEL}_${YEAR_STR}_uv.nc
    #remove old file
    rm -f ${MODEL}_${YEAR_STR}.nc
done