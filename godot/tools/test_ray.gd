extends RayCast

var start_time
var timeout = 3500

func _ready():
	start_time = OS.get_ticks_msec()

func _process(delta):
	
	var current_time = OS.get_ticks_msec()
	if current_time >= start_time + timeout: queue_free()
