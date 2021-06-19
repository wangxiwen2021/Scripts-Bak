        ;----------------start bash shell--------------------
        ;使用nco提取变量，使用cdo进行插值，使用ncl进行读取
        ;#!/usr/bin/bash
        ;now=$(pwd)
        ;dir="../"
        ;file=("wrfout_d03_2016-03-21_00:00:00")

        ;for sigfile in ${file[@]}
        ;do
        ;ncks -v XLAT,XLONG,XTIME,TSK,Z_LAKE3D,DZ_LAKE3D,T_LAKE3D,LAKEDEPTH2D,Z3D,DZ3D,ZI3D,WATSAT3D,CSOL3D,TKMG3D,TKDRY3D,TKSATU3D,T_
        ;cdo remapbil,lon=119.2113_lat=29.5072 ${now}/${sigfile} ${now}/cdo_${sigfile}
        ;done
        ;----------------end bash shell--------------------


        f = addfile("cdo_wrfout_d03_2016-03-21_00:00:00", "r")

        varnames = getfilevarnames(f)
        print(varnames)
        do i=6, dimsizes(varnames)-1
          print(f->$varnames(i)$)
        end do
