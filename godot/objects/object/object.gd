extends Spatial

var image_scale = 4.0

func _ready():
	
	update_sprite()
	
func update_sprite():
	$Sprite3D.offset.y = $Sprite3D.texture.get_size().y/2
	$Sprite3D.scale = Vector3(image_scale, image_scale, image_scale)
