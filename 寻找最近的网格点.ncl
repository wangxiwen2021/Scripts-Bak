	;-----------------------------------------------------
	; 使用wrf_user_ll_to_xy寻找距离指定经纬度坐标最近的格点，其中返回值loc1(0)为经向，loc1(1)为纬向
	; ------------------read wrfout file-------------------
	a = addfile("target_dir/sigfile.nc","r")

	t_lake3d = wrf_user_getvar(a, "T_LAKE3D",-1)
	xlat = wrf_user_getvar(a, "lat",0)
	xlon = wrf_user_getvar(a, "lon",0)
	z_lake3d = wrf_user_getvar(a, "Z_LAKE3D", 0)
	
	fdaba = addfile("/BIGDATA1/bnu_xfyang_1/Wangxw/Scripts/Data/QDH_T_LAKE_Daba.nc", "r")
	t_lake_obs = fdaba->t_lake
	Depths = fdaba->Depths
;	printVarSummary(t_lake_obs)

	zlist = Depths
	;-------------interpolate to Daba--------------
  	loc1 = wrf_user_ll_to_xy(a, tofloat(t_lake_obs@lon), tofloat(t_lake_obs@lat), True)
	z_lake_dab = z_lake3d(:, loc1(1), loc1(0))
;	lakedepth = wrf_user_getvar(a, "LAKEDEPTH2D", 0)
;	print(lakedepth(loc1(1), loc1(0)))
;	print(z_lake_dab)

	t_lake_dab = t_lake3d(:, :, loc1(1), loc1(0))
	t_lake_dab := linint1_Wrap(z_lake_dab, t_lake_dab, False, zlist, 0)

	fon = "./Data_new/Interp_sigfile.nc"
	system("rm -f "+fon)
	fo = addfile(fon,"c")
	fo->t_lake_dab = t_lake_dab
	delete(t_lake_dab)
