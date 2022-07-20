extends Node

# load palettes from file
func load_palettes(var filepath: String):
	
	var pals = []	
	var tfile = File.new()
	var c = 1.0/64.0
	var filesize
	
	
	if tfile.open(filepath, File.READ):
		printerr("Load Palettes: Error opening file ", filepath)
		return null
	
	# get file size
	filesize = tfile.get_len()
	
	# read in all the palettes from file
	while !tfile.eof_reached():
		
		# if there's 256 colors of 3 bytes each (256*3) available to read, read in palette
		if filesize < tfile.get_position() + 256*3: break
		
		var pal = []
		
		for i in range(0, 256):
			
			# read in RGB value
			var r = tfile.get_8()
			var g = tfile.get_8()
			var b = tfile.get_8()
			
			var newcolor = Color(r*c, g*c, b*c)
			
			# if the palette #0 and index #0, always transparent
			if pals.empty() and i == 0: newcolor = Color(1,1,1,0)
			pal.push_back(newcolor)
		
		pals.push_back(pal)
		
		if tfile.get_position() == filesize: break
		
	# cleanup
	tfile.close()
	return pals

# load aux palettes from file
func load_aux_palettes(var filepath: String):
	
	var pals = []	
	var tfile = File.new()
	var filesize
	
	if tfile.open(filepath, File.READ):
		printerr("Load Aux Palettes: Error opening file ", filepath)
		return null
	
	# get file size
	filesize = tfile.get_len()
	
	# read in all the palettes from file
	while !tfile.eof_reached():
		
		# if there's 16 indices available to read, read in aux palette
		if filesize < tfile.get_position() + 16: break
		
		var pal = []
		
		for _i in range(0, 16):
			
			# read index byte
			var pindex = tfile.get_8()
			pal.push_back(pindex)
		
		pals.push_back(pal)
		
		if tfile.get_position() == filesize: break
		
	# cleanup
	tfile.close()
	return pals

func _get_image_header(var tfile):
	
	var filesize = tfile.get_len()
	
	# read in header data
	var header = {}
	
	header["format"] = tfile.get_8()
	
	# if format is 2, the next byte is a height/width size for texture
	if header["format"] == 2:
		header["resolution"] = tfile.get_8()
	header["image_count"] = tfile.get_16()
	header["offsets"] = []
		
	# read in offsets
	for _i in range(0, header["image_count"]):
		var newoffset = tfile.get_32()
		# some records have duplicate offset entries, ignore
		# also ignore offsets that are at or beyond file size
		if newoffset < filesize:
			if header["offsets"].empty():
				header["offsets"].push_back(newoffset)
			elif newoffset != header["offsets"].back():
				header["offsets"].push_back(newoffset)
	
	return header

# load textures from file (walls, floors)
func load_textures(var filepath: String):
	var textures = []	
	var tfile = File.new()
	
	if tfile.open(filepath, File.READ):
		printerr("Load Textures: Error opening file ", filepath)
		return null
	
	# get image file header
	var header = _get_image_header(tfile)
	
	# create texture at each offset
	for i in header["offsets"]:
		var image = Image.new()
		tfile.seek(i)
		tfile.get_8() # format value
		image.create(header["resolution"], header["resolution"], false, Image.FORMAT_RGBA8)
		image.lock()
		for y in range(0, header["resolution"]):
			for x in range(0, header["resolution"]):
				image.set_pixel(x,y,UW.palettes[0][tfile.get_8()])
		image.unlock()
		
		# create texture
		var newtexture = ImageTexture.new()
		newtexture.create_from_image(image)
		textures.push_back(newtexture)
	
	if textures.size() != header["image_count"]:
		printerr("Expected ", header["image_count"], " images, loaded ", textures.size())
	
	# cleanup
	tfile.close()
	return textures
