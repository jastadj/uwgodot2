extends Node

# used for RLE decoding
var _bits = []
var _bitptr = 0

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
	var skipped_offsets = 0
	for _i in range(0, header["image_count"]):
		var newoffset = tfile.get_32()
		# some records have duplicate offset entries, ignore
		# also ignore offsets that are at or beyond file size
		if newoffset < filesize:
			if header["offsets"].empty():
				header["offsets"].push_back(newoffset)
			elif newoffset != header["offsets"].back():
				header["offsets"].push_back(newoffset)
		else: skipped_offsets += 1
	
	print("Found and skipped ", skipped_offsets, " null offset records.")
	
	return header

# load textures from file (walls, floors)
func load_textures(var filepath: String, var flip_y  : bool = false):
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
				if flip_y: image.set_pixel(x,header["resolution"]-1-y,UW.palettes[0][tfile.get_8()])
				else: image.set_pixel(x,y,UW.palettes[0][tfile.get_8()])
		image.unlock()
		
		# create texture
		var newtexture = ImageTexture.new()
		newtexture.create_from_image(image, 0)
		textures.push_back(newtexture)
	
	if textures.size() != header["image_count"]:
		printerr("Expected ", header["image_count"], " images, loaded ", textures.size())
	
	# cleanup
	tfile.close()
	return textures

func load_images(var filepath: String, palette):
	var images = []	
	var tfile = File.new()
	
	if tfile.open(filepath, File.READ):
		printerr("Load Images: Error opening file ", filepath)
		return null
	
	# get image file header
	var header = _get_image_header(tfile)
	
	# create texture at each offset
	for i in header["offsets"]:
		var image = Image.new()
		tfile.seek(i)
		
		# get image header info
		var format = tfile.get_8()
		var width = tfile.get_8()
		var height = tfile.get_8()
		var aux_pal = null
		var image_size
		var pixels = []
				
		# if a 4-bit format, get aux_pal
		if format == 0x08 or format == 0x0a:
			aux_pal = tfile.get_8()
		
		# get image size
		image_size = tfile.get_16()
		
		# FORMAT 4: uncompressed 8-bit format
		if format == 0x04:
			for _p in range(0, width*height):
				pixels.push_back(tfile.get_8())
		
		# FORMAT 10: uncompressed 4-bit format
		elif format == 0x0a:
			for _p in range(0, width*height):
				var byte = tfile.get_8()
				var upper = byte >> 4
				var lower = byte & 0x0f
				pixels.push_back(upper)
				pixels.push_back(lower)
		
		# FORMAT 8: compressed 4-bit format
		# FORMAT 6: compressed 5-bit format
		elif format == 0x08 or format == 0x06:
			
			# wordsize (4 or 5 bits)
			var wordsize = 4
			if format == 0x06: wordsize = 5
			
			# if 4-bit format, image_size = nibble count
			# image size expressed in nibbles
			var byte_count = image_size
			# possible data loss when converting to byte count?  are we losing
			# a nibble?  need to look into this
			if format == 0x08: byte_count = ceil(image_size/2)+1
			
			# read bytes into a bit stream
			var bytes = PoolByteArray()
			for _n in range(0, byte_count):
				bytes.push_back(tfile.get_8())
				
			# decode RLE into pixels
			pixels = _rle_to_pixels(wordsize, bytes, aux_pal)
			
			# is pixel count correct?
			if pixels.size() < width*height:
				printerr("RLE pixel count - not enough pixels, expected ", width*height,", received:", pixels.size())
			
		else:
			printerr("Unable to load image, unrecognized format: ", format)
			break
		
		
		# create image
		image.create(width, height, false, Image.FORMAT_RGBA8)
		
		# testing
		if i == 2293: print(pixels)
		
		# write pixel data to image
		image.lock()
		for y in range(0, height):
			for x in range(0, width):
				if aux_pal != null:
					var pindex = x + y*width
					# the RLE decoder can write more words than is needed
					if pindex >= width*height: continue
					image.set_pixel(x,y,palette[ UW.aux_palettes[aux_pal][pixels[pindex]] ])
				else:
					image.set_pixel(x,y,palette[pixels[x + y*width]])
		image.unlock()
		
		# create texture
		var newtexture = ImageTexture.new()
		newtexture.create_from_image(image, 0)
		images.push_back(newtexture)
	
	if images.size() != header["image_count"]:
		printerr("Expected ", header["image_count"], " images, loaded ", images.size())
	
	# cleanup
	tfile.close()
	return images

func _rle_to_pixels(wordsize, bytes, aux_pal):
	
	var repeat_record = false # starts with a repeat record when toggled
	var count
	var pixels = []
	
	# convert byte pool into a bit stream
	_bits = []
	_bitptr = 0
	
	# create bit stream starting with MSB
	for byte in bytes:
		for bit in range(0, 8):
			_bits.push_back(byte >> (8-bit-1) & 0x1)
	
	# decode RLE into pixels
	while _bitptr < _bits.size():
	
		# get the count
		count = _rle_get_count()
		
		# toggle record type
		repeat_record = !repeat_record
		
		# HANDLE SPECIAL REPEAT COUNTS (when count is 1 or 2)
		# skip record and do a run record if count is 1
		if count == 1 and repeat_record:
			continue
		# multiple repeats if count is 2, multiply count by repeat record
		elif count == 2 and repeat_record:
			var repeats = _rle_get_count()
			while repeats > 0:
				count = _rle_get_count()
				var value = _rle_get_word(wordsize)
				while count > 0:
					pixels.push_back(value)
					count -= 1
				repeats -= 1
		# do a repeat or a run if valid count
		elif count > 0:
			if repeat_record:
				var value = _rle_get_word(wordsize)
				while count > 0:
					pixels.push_back(value)
					count -= 1
			else:
				while count > 0:
					pixels.push_back(_rle_get_word(wordsize))
					count -= 1
		# not a valid count?
		#else: printerr("RLE invalid count:", count)
	
	return pixels
	

func _rle_get_count():
	
	# get count 1
	var count = _rle_get_word(4)

	# if count == 0, get count 2
	if count == 0:
		count = (_rle_get_word(4) << 4) | _rle_get_word(4)
		# if count is still 0, get count 3
		if count == 0:
			count = (_rle_get_word(4) << 4 | _rle_get_word(4)) << 4 | _rle_get_word(4)
	return count
	
func _rle_get_word(bits):
	var word = 0
	for n in range(0, bits):
		if _bitptr >= _bits.size(): break
		word = word << 1 | _bits[_bitptr]
		_bitptr += 1
	return word

