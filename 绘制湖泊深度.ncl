;--------------------------------------------------------------------------------------
; 绘制WRF初始场的湖泊深度，并添加shapefile
;--------------------------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "./shapefile_utils.ncl"
;--------------------------------------------------------------------------------------

;-------------------------------
; Main code
;-------------------------------
begin

  dir  = "/BIGDATA1/bnu_xfyang_1/Wangxw/2km_2016/"

  f    = addfile(dir + "wrfout_d02_2016-06-01_00:00:00" + ".nc", "r")
;  f    = addfile(dir + "wrfinput_d02" + ".nc", "r")

  xlat = f->XLAT(0,:,:)
  xlon = f->XLONG(0,:,:)
  LakeMask = f->LAKEMASK(0,:,:)
  LakeDepth = f->LAKEDEPTH2D(0,:,:)
  LakeDepth@_FillValue = -999
  LakeDepth = where(LakeMask .eq. 0, LakeDepth@_FillValue, LakeDepth)
  printMinMax(LakeDepth, -1)
  printMinMax(LakeMask, -1)
  print(num(.not.ismissing(LakeDepth)))

;--------------------------------------------
; Start to plot:
;--------------------------------------------
    if ( f@MAP_PROJ .eq. 1 ) then
         mapproj = "LambertConformal"
         truelat1 = f@TRUELAT1
         truelat2 = f@TRUELAT2
         clon     = f@STAND_LON
    end if
    if ( f@MAP_PROJ .eq. 2 ) then
         mapproj = "Stereographic"
         truelat1 = f@TRUELAT1
         truelat2 = f@TRUELAT2
         clon     = f@CEN_LON
         clat     = f@CEN_LAT
    end if
    if ( f@MAP_PROJ .eq. 3 ) then
         mapproj = "Mercator"
    end if
    
    ;retrieve named dimensions'size in f
    dsizes = getfiledimsizes(f) 
    nx = dsizes(2)  ;"lat" dimension size
    ny = dsizes(3)  ;"lon" dimension size 


    start_x   = 0
    end_x     = nx-1
    start_y   = 0
    end_y     = ny-1

    lat_ll  = xlat(start_y,start_x) ;low left
    lat_ur  = xlat(end_y,end_x)     ;upper right 
    lon_ll  = xlon(start_y,start_x)
    lon_ur  = xlon(end_y,end_x)

;---------------------------------------
;	Define some resources
;---------------------------------------
	wks_type = "x11"
	wks_type@wkWidth = 2500
	wks_type@wkHeight = 2500
	wks = gsn_open_wks(wks_type,"./Figure/LakeDepth_wrfinput_d02")
	
	res = True
;	res@tiMainString = ""
	res@gsnSpreadColors = True
	res@gsnDraw = False
	res@gsnFrame = False
	res@gsnAddCyclic = False
	res@gsnMaximize = True
	res@gsnLeftString = ""
	res@gsnRightString = ""

	res@mpProjection            = mapproj          ; choose projection
	    if ( mapproj .eq. "LambertConformal" ) then
	       res@mpLambertParallel1F     = truelat1      ; two parallels
	       res@mpLambertParallel2F     = truelat2
	       res@mpLambertMeridianF      = clon          ; central meridian
	    end if
	    if ( mapproj .eq. "Stereographic" ) then
	       res@mpCenterLatF         = clat
	       res@mpCenterLonF         = clon
	    end if

	res@mpLimitMode             = "Corners"
	res@mpLeftCornerLatF        = lat_ll
	res@mpLeftCornerLonF        = lon_ll
	res@mpRightCornerLatF       = lat_ur
	res@mpRightCornerLonF       = lon_ur

	;res@mpOutlineDrawOrder       = "Draw"         ; continent outline last
	res@mpGeophysicalLineColor   = "Black"
	res@mpNationalLineColor      = "Black"
	res@mpGridAndLimbOn          = False
	res@mpDataSetName            = "Earth..4"      ; divisions for other countries.
	res@mpDataBaseVersion        = "MediumRes"     ; Medium res_slpolution database
	res@mpOutlineBoundarySets    = "NoBoundaries"

	res@pmTickMarkDisplayMode    = "Always"
	res@mpFillOn                 =  False             ; turn off map fill
	res@tfDoNDCOverlay           = True               ; don't transform
  
	res@tmYROn		              = True
	res@tmYLOn                  = True
	res@tmXBOn                  = True
	res@tmXTOn                  = True
	
	res@cnFillOn				= True
	res@cnLinesOn				= False
	;res@cnFillDrawOrder	= "Draw"
	
	res@pmLabelBarHeightF = 0.1
	res@pmLabelBarOrthogonalPosF = 0.015
	res@lbTitleString = LakeDepth@description+"("+LakeDepth@units+")"
	res@lbTitleFontHeightF = 0.015
	plot = gsn_csm_contour_map(wks,smth9_Wrap(LakeDepth, 0.5, 0.25, False),res)

  ;--------------------------------------------
  ;       show Lake outline
  ;--------------------------------------------
  Lake_shp              = "./GLWD-level1/glwd_1.shp"
  lnres                  = True
  lnres@gsLineColor      = "Black"
  lnres@gsLineThicknessF = 6

  Lake_id = gsn_add_shapefile_polylines(wks,plot,Lake_shp,lnres)

  ;---------marks---------------
  pmres = True
	pmres@tfPolyDrawOrder = "PostDraw"
  pmres@gsMarkerColor = "black"
  pmres@gsMarkerIndex = 16
  pmres@gsMarkerSizeF = 0.008
  dum1 = gsn_add_polymarker(wks,plot,119.02,29.62,pmres)       ;weather station

  ;buoy
  pmres@gsMarkerColor = "green"
  dum2 = gsn_add_polymarker(wks,plot,118.94,29.65,pmres)       ;Xiaojinshan
  pmres@gsMarkerColor = "purple"
  dum3 = gsn_add_polymarker(wks,plot,118.97,29.54,pmres)       ;Santandao
  pmres@gsMarkerColor = "cyan"
  dum4 = gsn_add_polymarker(wks,plot,119.21,29.51,pmres)       ;Daba
  pmres@gsMarkerColor = "deepskyblue"
  dum5 = gsn_add_polymarker(wks,plot,118.73,29.72,pmres)       ;Jiukengkou
;
	draw(plot)
	frame(wks)
end
