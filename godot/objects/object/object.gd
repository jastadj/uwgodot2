extends Spatial

func _ready():
	
	update_sprite()
	
func update_sprite():
	$Sprite3D.offset.y = $Sprite3D.texture.get_size().y/2
	$Sprite3D.scale = Vector3(UW.image_scale, UW.image_scale, UW.image_scale)
