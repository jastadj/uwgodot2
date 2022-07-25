extends Spatial

func _ready():
	
	if true:
		var mat = UW.data["uw1"]["rotating_palette_spatial"]
		$plane.set_surface_material(0, mat)	
		mat.set_shader_param("img", UW.data["uw1"]["images"]["walls"][34])
		mat = mat.duplicate()
		$floor.set_surface_material(0, mat)
		mat.set_shader_param("img", UW.data["uw1"]["images"]["floors"][16])
	else:
		var mat = $plane.get_surface_material(0)
		#mat.set_shader_param("TextureUniform", UW.data["uw1"]["images"]["walls"][34])
	
	#$Sprite3D.material_override = UW.data["uw1"]["rotating_palette_shader"]
	
	print(UW.data["uw1"]["palettes"][0][48])
