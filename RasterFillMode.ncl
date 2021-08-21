;--------------------------------------------------
; RasterFillMode.ncl
;--------------------------------------------------
; Concepts illustrated:
;   - 使用gsn_coordinates绘制所有网格点，missing/non missing区分
；  - 使用gsn_add_text标注网格点的数据
；  - 使用raster fill mode绘制格点数据
;   - 使用函数完成shapefile绘制
;   - 使用gsn_add_polymarker标注观测点
;   - 自动从WRF文件获取lambert投影和地图范围
;   - 自动获取脚本名称对workstation命名
；  - 使用unique_string()、$符号和属性存储annotation
;--------------------------------------------------
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "../shapefile_utils.ncl"

;----------------------------------------------------------------------
; Procedure to add shapefile outlines to the given plot.
;----------------------------------------------------------------------
procedure add_shp_outlines(wks,plot,shp_filename)
local lnres
begin
;---Resources for polyline
  lnres                  = True
  lnres@gsLineColor      = "NavyBlue"
  lnres@gsLineThicknessF = 1.0    ; 1 is the default

  plot@lines = gsn_add_shapefile_polylines(wks, plot, shp_filename, lnres)
end

begin
  dir  = "/BIGDATA1/bnu_xfyang_1/Wangxw/1km_2016/"
  f    = addfile(dir + "wrfinput_d02" + ".nc", "r")
  LakeMask = f->LAKEMASK(0,:,:)
  LakeDepth = f->LAKE_DEPTH(0,:,:)
  xlat = f->XLAT(0,:,:)
  xlon = f->XLONG(0,:,:)

  LakeDepth@_FillValue = -999
  LakeDepth = where(LakeMask .eq. 0, LakeDepth@_FillValue, LakeDepth)
  LakeDepth@lat2d = xlat
  LakeDepth@lon2d = xlon
  printVarSummary(LakeDepth)

  dir          = "../GLWD-level1/"
  shp_filename = dir + "glwd_1.shp"

  wks_type = "x11"
  wks_type@wkWidth = 2500
  wks_type@wkHeight = 2500
  wks = gsn_open_wks(wks_type,get_script_prefix_name())

;---Set up some contour resources.

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

  res                       = True
  res@gsnMaximize           = True
  res@gsnDraw               = False   ; Don't draw plot
  res@gsnFrame              = False   ; Don't advance frame.

  res@gsnAddCyclic          = False
  res@gsnLeftString         = ""
  res@cnFillOn              = True
  res@cnFillMode            = "RasterFill"
  res@cnLinesOn             = False
  res@cnLineLabelsOn        = False
  res@cnInfoLabelOn         = False
  ;res@cnLevelSelectionMode = "ExplicitLevels"
  ;res@cnLevels             = (/0, 10, 25, 50, 75, 125, 200, 350, 500, 750, \
  ;                        1000, 1250, 1500, 1750, 2000, 2250, 3000, 4000, 5000/)
  res@lbLabelBarOn          = False    ; will add later in paneled plots

  res@mpFillOn              = False 
  res@mpGridAndLimbOn       = False
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
  res@mpDataBaseVersion     = "MediumRes"
 

;---Create two map plots so we can attach data grid later
  res@tiMainString           = "Lat/lon locations of original data"
  plot_depth = gsn_csm_contour_map(wks,LakeDepth,res)

;---Add shapefile outlines
  add_shp_outlines(wks,plot_depth,shp_filename)

;---Attach original lat/lon grid over original data.
  gres                 = True
  gres@gsMarkerSizeF   = 1
 ; gres@gsMarkerSizeF   = 3
  gres@gsnFrame        = False
  gres@gsnDraw         = False
  gres@gsnCoordsAttach = True

;
; Attach lat/lon grid over masked data, with missing and non-missing 
; locations colored differently.
;
  gres@gsnCoordsNonMissingColor = "black"
  gres@gsnCoordsMissingColor    = "grey60"
  gsn_coordinates(wks,plot_depth,LakeDepth,gres)

;
; Add indexes
;
  txres = True
  txres@txFontHeightF = 0.001
;  txres@txFontHeightF = 0.004
  txres@txJust = "BottomCenter"
  txres@txFontColor = "black"
  ndim = dimsizes(LakeDepth)	;lat, lon ;gsn_add_text requires x-lon, y-lat

  dum = True
  loc_daba = wrf_user_ll_to_xy(f, 119.21, 29.51, True)
;  do j=0, ndim(1)-1
;    do i=0, ndim(0)-1
  do j = loc_daba(0)-1, loc_daba(0)+1
    do i = loc_daba(1)-1, loc_daba(1)+1
        if (.not.ismissing(LakeDepth(i,j))) then
          dum@$unique_string("dum")$ = gsn_add_text(wks, plot_depth, sprintf("%4.2f", LakeDepth(i,j)), xlon(i,j), xlat(i,j), txres)
	end if
    end do
  end do

;  do j=12, ndim(1)-8, 2
;    do i=6, ndim(0)-10, 2
;        dum@$unique_string("dum")$ = gsn_add_text(wks, plot_depth, "("+j+", "+i+")", xlon(i,j), xlat(i,j), txres)
;	print(i)
;	print(j)
;    end do
;  end do

  ;buoy
  pmres = True
  pmres@tfPolyDrawOrder = "PostDraw"
  pmres@gsMarkerColor = "black"
  pmres@gsMarkerIndex = 16
  pmres@gsMarkerSizeF = 0.003
  dum1 = gsn_add_polymarker(wks,plot_depth,119.02,29.62,pmres)       ;weather station
; pmres@gsMarkerIndex = 16
; pmres@gsMarkerSizeF = 0.1 
; pmres@gsMarkerColor = "blue"
; gsn_polymarker(wks,plot_depth,119.09,29.53,pmres)       ;laoshan
; pmres@gsMarkerColor = "red"
; gsn_polymarker(wks,plot_depth,119.09,29.67,pmres)       ;hukengcun
; pmres@gsMarkerColor = "yellow"
; gsn_polymarker(wks,plot_depth,118.76,29.48,pmres)       ;maotoujian
; pmres@gsMarkerColor = "purple"
;; gsn_polymarker(wks,plot_depth,118.81,29.68,pmres)       ;nanfu
  pmres@gsMarkerColor = "green"
  dum2 = gsn_add_polymarker(wks,plot_depth,118.94,29.65,pmres)       ;Xiaojinshan
  pmres@gsMarkerColor = "purple"
  dum3 = gsn_add_polymarker(wks,plot_depth,118.97,29.54,pmres)       ;Santandao
  pmres@gsMarkerColor = "cyan"
  dum4 = gsn_add_polymarker(wks,plot_depth,119.21,29.51,pmres)       ;Daba
  pmres@gsMarkerColor = "deepskyblue"
  dum5 = gsn_add_polymarker(wks,plot_depth,118.73,29.72,pmres)       ;Jiukengkou

;---Draw both plots in a panel
  pres                  = True
  pres@gsnMaximize      = True
  pres@gsnPanelLabelBar = True  
  gsn_panel(wks,(/plot_depth/),(/1,1/),pres)
end
