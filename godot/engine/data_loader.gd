extends Node

enum TYPE{
	PALETTE,
	AUX_PALETTE,
	GRAPHIC,
	TEXTURE,
	FONT,
	MAP,
	BITMAP,
	STRING
	}
	
enum FLAGS{
	FLIP_Y=1,
	REPEAT=2
	}
	
# used for RLE decoding
var _bits = []
var _bitptr = 0

# load data type from file, supply some metadata in a dict
func load_data(dtype, filepath, ddict = {}):
	
	# load palettes
	if dtype == TYPE.PALETTE:
		var palettes
		print("Loading palette file:", filepath)
		palettes = load_palettes(filepath)
		if palettes: print(palettes.size(), " palettes loaded.")
		return palettes
	elif dtype == TYPE.AUX_PALETTE:
		var palettes
		print("Loading aux palette file:", filepath)
		palettes = load_aux_palettes(filepath)
		if palettes: print(palettes.size(), " aux palettes loaded.")
		return palettes
	# elif texture (metadata flags and palette)
	elif dtype == TYPE.TEXTURE:
		var textures
		print("Loading textures from file:", filepath)
		textures = load_textures(filepath, ddict)
		if textures: print(textures.size(), " textures loaded.")
		return textures
	elif dtype == TYPE.GRAPHIC:
		var images
		print("Loading images from file:", filepath)
		images = load_images(filepath, ddict["palette"], ddict["aux_palette"])
		if images: print(images.size(), " images loaded.")
		return images
	elif dtype == TYPE.FONT:
		var font
		print("Loading font from file:", filepath)
		font = load_font(filepath)
		if font: print(font["chars"].size(), " font chars loaded.")
		return font
	elif dtype == TYPE.MAP:
		var map
		print("Loading map from file:", filepath)
		map = load_map(filepath)
		if map: print(map["levels"].size(), " levels loaded.")
		return map
	elif dtype == TYPE.BITMAP:
		var bitmap
		print("Loading bitmap from file:", filepath)
		bitmap = load_bitmap(filepath, ddict["palette"])
		if bitmap: print("Loaded bitmap.")
		return bitmap
	elif dtype == TYPE.STRING:
		var strings
		print("Loading strings from file:", filepath)
		strings = load_strings(filepath)
		return strings

func load_uw1_data():
	
	if UW.uw1_dir == null: return null
	
	var data_dir = str(UW.uw1_dir, "/UWDATA")
	var data = {}
	
	data["type"] = UW.GAME_TYPE.UW1
	
	# load palettes
	data["palettes"] = load_data(TYPE.PALETTE, str(data_dir, "/PALS.DAT"))
	data["aux_palettes"] = load_data(TYPE.AUX_PALETTE, str(data_dir, "/ALLPALS.DAT"))
	
	# generate rotating palette material
	print("Generating rotating palette shader...")
	var mats = generate_rotating_palette_material(UW.GAME_TYPE.UW1, data["palettes"][0])
	data["rotating_palette_spatial"] = mats[0]
	data["rotating_palette_shader"] = mats[1]
	
	# load fonts
	data["fonts"] = []
	data["fonts"].push_back(load_data(TYPE.FONT, str(data_dir,"/FONT4X5P.SYS")))
	data["fonts"].push_back(load_data(TYPE.FONT, str(data_dir,"/FONT5X6I.SYS")))
	data["fonts"].push_back(load_data(TYPE.FONT, str(data_dir,"/FONT5X6P.SYS")))
	data["fonts"].push_back(load_data(TYPE.FONT, str(data_dir,"/FONTBIG.SYS")))
	
	# load textures (walls/floors)
	data["images"] = {}
	data["images"]["floors"] = load_data(TYPE.TEXTURE, str(data_dir, "/F32.TR"), {"flags":FLAGS.FLIP_Y, "palette":data["palettes"][0]} )
	data["images"]["walls"] = load_data(TYPE.TEXTURE, str(data_dir, "/W64.TR"), {"flags":FLAGS.REPEAT, "palette":data["palettes"][0]} )
	
	#print("Generating materials...")
	#data["materials"] = {}
	#data["materials"]["floors"] = create_materials_from_textures(data["images"]["floors"], data["rotating_palette_spatial"])
	#print("Generated ", data["materials"]["floors"].size(), " floor materials.")
	#data["materials"]["walls"] = create_materials_from_textures(data["images"]["walls"], data["rotating_palette"])
	#print("Generated ", data["materials"]["walls"].size(), " wall materials.")
	
	# load player graphics
	data["images"]["player_heads"] = load_data(TYPE.GRAPHIC, str(data_dir, "/HEADS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["player_armor_male"] = load_data(TYPE.GRAPHIC, str(data_dir, "/ARMOR_M.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["player_armor_female"] = load_data(TYPE.GRAPHIC, str(data_dir, "/ARMOR_F.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["player_bodies"] = load_data(TYPE.GRAPHIC, str(data_dir, "/BODIES.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})

	# heads - conversation
	#data["images"]["generic_heads"] = load_data(TYPE.GRAPHIC, str(data_dir, "/GENHEADS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["conversation"] = load_data(TYPE.BITMAP, str(data_dir, "/CONV.BYT"), {"palette":data["palettes"][0]})
	data["images"]["converse"] = load_data(TYPE.GRAPHIC, str(data_dir, "/CONVERSE.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})

	# load objects
	data["images"]["objects"] = load_data(TYPE.GRAPHIC, str(data_dir, "/OBJECTS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})	
	data["images"]["doors"] = load_data(TYPE.GRAPHIC, str(data_dir, "/DOORS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})	

	# load small animations
	data["images"]["small_animations"] = load_data(TYPE.GRAPHIC, str(data_dir, "/ANIMO.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})

	# mouse cursors
	data["images"]["cursors"] = load_data(TYPE.GRAPHIC, str(data_dir, "/CURSORS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})

	# intro/end
	data["images"]["opening"] = load_data(TYPE.BITMAP, str(data_dir, "/OPSCR.BYT"), {"palette":data["palettes"][2]})
	data["images"]["origin"] = load_data(TYPE.BITMAP, str(data_dir, "/PRES1.BYT"), {"palette":data["palettes"][5]})
	data["images"]["bluesky"] = load_data(TYPE.BITMAP, str(data_dir, "/PRES2.BYT"), {"palette":data["palettes"][5]})
	data["images"]["win"] = load_data(TYPE.BITMAP, str(data_dir, "/WIN1.BYT"), {"palette":data["palettes"][7]})
	data["images"]["win_blank"] = load_data(TYPE.BITMAP, str(data_dir, "/WIN2.BYT"), {"palette":data["palettes"][7]})

	# main menu
	data["images"]["main_buttons"] = load_data(TYPE.GRAPHIC, str(data_dir, "/OPBTN.GR"), {"palette":data["palettes"][2], "aux_palette":data["aux_palettes"]})
	
	# char gen
	data["images"]["heads"] = load_data(TYPE.GRAPHIC, str(data_dir, "/CHARHEAD.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["chargen"] = load_data(TYPE.BITMAP, str(data_dir, "/CHARGEN.BYT"), {"palette":data["palettes"][3]})
	data["images"]["chargen_buttons"] = load_data(TYPE.GRAPHIC, str(data_dir, "/CHRBTNS.GR"), {"palette":data["palettes"][3], "aux_palette":data["aux_palettes"]})

	# main UI grahics
	data["images"]["main"] = load_data(TYPE.BITMAP, str(data_dir, "/MAIN.BYT"), {"palette":data["palettes"][0]})
	data["images"]["3dwin"] = load_data(TYPE.GRAPHIC, str(data_dir, "/3DWIN.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["chains"] = load_data(TYPE.GRAPHIC, str(data_dir, "/CHAINS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["compass"] = load_data(TYPE.GRAPHIC, str(data_dir, "/COMPASS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["dragons"] = load_data(TYPE.GRAPHIC, str(data_dir, "/DRAGONS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["flasks"] = load_data(TYPE.GRAPHIC, str(data_dir, "/FLASKS.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["eyes"] = load_data(TYPE.GRAPHIC, str(data_dir, "/EYES.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["left_buttons"] = load_data(TYPE.GRAPHIC, str(data_dir, "/LFTI.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	data["images"]["scroll"] = load_data(TYPE.GRAPHIC, str(data_dir, "/SCRLEDGE.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	
	
	# map image
	data["images"]["map"] = load_data(TYPE.BITMAP, str(data_dir, "/BLNKMAP.BYT"), {"palette":data["palettes"][1]})
	
	# inventory?
	data["images"]["inventory"] = load_data(TYPE.GRAPHIC, str(data_dir, "/INV.GR"), {"palette":data["palettes"][0], "aux_palette":data["aux_palettes"]})
	
	# load strings
	data["strings"] = load_data(TYPE.STRING, str(data_dir, "/STRINGS.PAK"))
	
	# generate objects
	data["objects"] = create_objects(data)
	
	# load game map / levels
	data["map"] = load_data(TYPE.MAP, str(data_dir, "/LEV.ARK"))
	
	return data

# load palettes from file
func load_palettes(var filepath: String):
	
	var pals = []	
	var tfile = File.new()
	#var c = 1.0/64.0
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
			# and reduce floating point resolution to the hundredths
			# tfile.get_8()*c too much resolution
			var r = tfile.get_8()*4
			var g = tfile.get_8()*4
			var b = tfile.get_8()*4
			
			var color_bytes = PoolByteArray([r,g,b])
			var color_string = str("#ff") + color_bytes.hex_encode()
			var newcolor = Color(color_string)
			
			# testing palette 0, color index 48
			if pals.empty() and i == 48:
				print(newcolor)
			
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

# load textures from file (walls, floors)
func load_textures(var filepath: String, sourcedata):
	var textures = []	
	var tfile = File.new()
	var flip_y = false
	var repeat = false
	var palette = sourcedata["palette"]
	var has_rotating_palette = false
	
	if tfile.open(filepath, File.READ):
		printerr("Load Textures: Error opening file ", filepath)
		return null
	
	# get image file header
	var header = _get_image_header(tfile)
	
	# handle source data
	if sourcedata.keys().has("flags"):
		if sourcedata["flags"] & FLAGS.FLIP_Y: flip_y = true
		if sourcedata["flags"] & FLAGS.REPEAT: repeat = true
	
	# create texture at each offset
	for i in header["offsets"]:
		var image = Image.new()
		tfile.seek(i)
		#tfile.get_8() # format value
		image.create(header["resolution"], header["resolution"], false, Image.FORMAT_RGBA8)
		image.lock()
		for y in range(0, header["resolution"]):
			for x in range(0, header["resolution"]):
				if flip_y: image.set_pixel(x,header["resolution"]-1-y,palette[tfile.get_8()])
				else: image.set_pixel(x,y,palette[tfile.get_8()])
		image.unlock()
		
		# create texture
		var newtexture = ImageTexture.new()
		var textureflags = 0
		if repeat: textureflags |= Texture.FLAG_REPEAT
		newtexture.create_from_image(image, textureflags)
		textures.push_back(newtexture)
	
	if textures.size() != header["image_count"]:
		printerr("Expected ", header["image_count"], " images, loaded ", textures.size())
	
	# cleanup
	tfile.close()
	return textures

func load_images(var filepath: String, palette, aux_palette ):
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
		var aux_pal_index = null
		var image_size
		var pixels = []
				
		# if a 4-bit format, get aux_pal
		if format == 0x08 or format == 0x0a:
			aux_pal_index = tfile.get_8()
		
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
			pixels = _rle_to_pixels(wordsize, bytes, aux_pal_index)
			
			# is pixel count correct?
			if pixels.size() < width*height:
				printerr("RLE pixel count - not enough pixels, expected ", width*height,", received:", pixels.size())
			
		else:
			printerr("Unable to load image, unrecognized format: ", format)
			break
		
		
		# create image
		image.create(width, height, false, Image.FORMAT_RGBA8)
		
		# write pixel data to image
		image.lock()
		for y in range(0, height):
			for x in range(0, width):
				if aux_pal_index != null:
					var pindex = x + y*width
					# the RLE decoder can write more words than is needed
					if pindex >= width*height: continue
					image.set_pixel(x,y,palette[ aux_palette[aux_pal_index][pixels[pindex]] ])
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

func load_font(filepath):
	
	var tfile = File.new()
	var filesize
	var font = {}
	var count = 0
	var width
	var height
	
	if tfile.open(filepath, File.READ):
		printerr("Load Font: Error opening file ", filepath)
		return null
	
	filesize = tfile.get_len()
	
	# unknown byte, junk?
	tfile.get_16()
	# size of single character, in bytes
	font["charsize"] = tfile.get_16()
	# width of a blank space in pixels
	font["blank_width"] = tfile.get_16()
	# font height in pixels
	font["height"] = tfile.get_16()
	# width of a character row
	font["row_width"] = tfile.get_16()
	# max width of a character
	font["max_width"] = tfile.get_16()

	font["chars"] = []

	width = font["max_width"]
	height = font["height"]

	count = (filesize - 12) / font["charsize"] # file size minus header bytes div by char size
	
	# read and create each font character
	for _i in range(0, count):
		
		var char_image = Image.new()
		var char_bytes = PoolByteArray()
		var current_width
		
		# read in char bytes
		for _b in range(0, font["charsize"]):
			char_bytes.push_back(tfile.get_8())
		
		# get current characters width
		current_width = tfile.get_8()
		
		# if the width is 0, create a junk entry
		if current_width == 0:
			char_image.create(font["max_width"], height, false, Image.FORMAT_RGBA8)
			char_image.lock()
			char_image.fill(Color(1,1,1))
			char_image.unlock()
		
		# otherwise, create character image
		else:
			# create image object
			char_image.create(current_width, height, false, Image.FORMAT_RGBA8)
			char_image.lock()
			
			# map bit pattern to image row each row, most sig bit
			for y in range(0, font["height"]):
				for x in range(0, current_width):
					var byte_num = y*font["row_width"] + (x/8)
					var bit = ((char_bytes[byte_num]) >> 7-(x%8)) & 0x1
					if bit: char_image.set_pixel(x,y, Color(1,1,1))
			char_image.unlock()
			
		# create image texture
		var newtexture = ImageTexture.new()
		newtexture.create_from_image(char_image, 0)
		
		# add new character image to the list
		font["chars"].push_back(newtexture)
		
	# done
	tfile.close()
	return font

func load_map(filepath):
	var tfile = File.new()
	var filesize
	var map = {"levels":[]}
	var block_count
	var offsets = []
	# texture mapping is only used during level loading
	var wall_maps = []
	var floor_maps = []
	var door_maps = []
	var levels
	
	if tfile.open(filepath, File.READ):
		printerr("Load Map: Error opening file ", filepath)
		return null
	
	# get size of file
	filesize = tfile.get_len()
	
	# get number of blocks
	block_count = tfile.get_16()
	
	# get number of levels (blocks / 15)
	levels = block_count/15
	
	# get offsets of the blocks
	for _i in range(0, block_count):
		offsets.push_back(tfile.get_32())
	
	# read texture mapping
	for o in range(18, 18 + levels):
		var offset = offsets[o]
		var walls = []
		var floors = []
		var doors = []
		
		# move to offset
		tfile.seek(offset)
		
		# read wall texture map indices
		for _i in range(0, 48):
			walls.push_back(tfile.get_16())
		# read floor texture map indices
		for _i in range(0, 10):
			floors.push_back(tfile.get_16())
		# read door texture map indices
		for _i in range(0, 6):
			doors.push_back(tfile.get_8())
		
		# add texture maps to map
		wall_maps.push_back(walls)
		floor_maps.push_back(floors)
		door_maps.push_back(doors)
		#map["levels"][o-18]["texture_maps"] = {"walls":walls, "floors":floors, "doors":doors}
	
	# read tilemap / object list blocks
	for o in range(0, levels):
		var offset = offsets[o]
		var level = {"cells":[]}
		if offset == 0: continue # ignore 0 offsets
		
		# move to offset
		tfile.seek(offset)
		
		for y in range(0,64):
			level["cells"].push_back([])
		
		# set ceiling (last floor texture mapping)
		var ceil_texture = floor_maps[o].back()
		
		# read tilemap bytes (4 bytes) * 64 * 64		
		for y in range(0, 64):
			for x in range(0, 64):
				var info1 = tfile.get_16()
				var info2 = tfile.get_16()
				
				var cell = {}
				# info byte 1
				cell["type"] = info1 & 0xf
				# cell types
				#00      Solid (wall tile)
				#01      Open (square tile of empty space)
				#02      Diagonal, open SE
				#03      Diagonal, open SW
				#04      Diagonal, open NE
				#05      Diagonal, open NW
				#06      Sloping up to the north
				#07      Sloping up to the south
				#08      Sloping up to the east
				#09      Sloping up to the west
				cell["floor_height"] = (info1 & 0xf0) >> 4 # floor height (0-15 max)
				# instead of keeping the texture mapping values around
				# just cut out the middle man and save the direct image index
				cell["floor_texture"] = floor_maps[o][(info1 & 0x3c00) >> 10] # floor texture index
				cell["allow_magic"] = (info1 >> 14) & 0x1 # allow magic to be cast in this cell
				cell["door"] = door_maps[o][(info1 >> 15) & 0x1] # used for what?
				# info byte 2
				cell["wall_texture"] = wall_maps[o][info2 & 0x3f]
				cell["ceil_texture"] = ceil_texture
				cell["object_index"] = (info2 >> 6) & 0x3ff
				
				# add cell to level map
				var converted_y = 64-1-y
				cell["position"] = Vector2(x, converted_y)
				level["cells"][converted_y].push_back(cell)
		
		# read object data
		level["objects"] = []
		for _i in range(0, 1024):
			var new_object = {}
			var obj_id_flags_byte = tfile.get_16()
			var obj_pos = tfile.get_16()
			var obj_quality_chain = tfile.get_16()
			var obj_link_special = tfile.get_16()
			
			# if index is 0-255, then it's a mob and has extra data
			if _i < 256:
				var mob_hp = tfile.get_8()
				var unk1 = tfile.get_8()
				var unk2 = tfile.get_8()
				var mob_goal_targ = tfile.get_16()
				var mob_info = tfile.get_16()
				var mob_height = tfile.get_16()
				var unk3 = tfile.get_8()
				var unk4 = tfile.get_8()
				var unk5 = tfile.get_8()
				var unk6 = tfile.get_8()
				var unk7 = tfile.get_8()
				var mob_home_info = tfile.get_16()
				var mob_angle = tfile.get_8()
				var mob_hunger = tfile.get_8()
				var mob_whoami = tfile.get_8()
			
			
			# object ID and flags
			new_object["id"] = obj_id_flags_byte & 0x1ff # object id
			new_object["flags"] = (obj_id_flags_byte >> 9) & 0x7 # ?
			new_object["enchanted"] = (obj_id_flags_byte >> 12) & 0x1 # is enchanted?
			new_object["door_dir"] = (obj_id_flags_byte >> 13) & 0x1 # door direction
			new_object["invisible"] = (obj_id_flags_byte >> 14) & 0x1 # don't draw?
			new_object["is_quantity"] = (obj_id_flags_byte >> 15) & 0x1 # use link field for quantiy/special info
			
			# object position
			new_object["height"] = obj_pos & 0x7f # z pos 0-127
			new_object["angle"] = (obj_pos >> 7) & 0x7 # per 45 degrees
			new_object["tile_y"] = (obj_pos >> 10) & 0x7 # y position within tile
			new_object["tile_x"] = (obj_pos >> 13) & 0x7 # x position within tile
			
			# object quality/chain
			new_object["quality"] = obj_quality_chain & 0x3f
			new_object["next"] = (obj_quality_chain >> 6) & 0x3ff
			
			# object link/special
			new_object["owner_special"] = obj_link_special & 0x3f
			new_object["special_link"] = (obj_link_special >> 6) & 0x3ff
			
			level["objects"].push_back(new_object)
			
		# add level to the list
		map["levels"].push_back(level)
		
	# done
	tfile.close()
	return map

func load_bitmap(filepath, pal):
	var tfile = File.new()
	var width = 320
	var height = 200
	var bitmap = []
	
	if tfile.open(filepath, File.READ):
		printerr("Load Bitmap: Error opening file ", filepath)
		return null
	
	var newimage = Image.new()
	var newtexture = ImageTexture.new()
	newimage.create(width, height, false, Image.FORMAT_RGBA8)
	newimage.lock()
	for y in range(0, 200):
		for x in range(0, 320):
			#var byte = tfile.get_8()
			newimage.set_pixel(x,y, pal[tfile.get_8()])
	newimage.unlock()
	newtexture.create_from_image(newimage, 0)
	
	bitmap.push_back(newtexture)
	
	return bitmap
			

func create_materials_from_textures(textures, shader = null):
	var mats = []
	for texture in textures:
		var mat = SpatialMaterial.new()
		mat.albedo_texture = texture
		#mat.set_shader(shader)
		mats.push_back(mat)
	return mats
	
func generate_rotating_palette_material(gametype, pal):
	
	var mats = []
	
	if pal == null:
		printerr("Error generating rotating palette, palette is null")
		return null
	
	for m in range(0, 2):
		# generate material / shader for rotating palettes for UW1
		if gametype == UW.GAME_TYPE.UW1:
			var colors = []
			if mats.empty():
				mats.push_back(load("res://materials/spatialshader_palette_rotation_uw1.tres"))
			elif mats.size() == 1:
				mats.push_back(load("res://materials/shader_palette_rotation_uw1.tres"))
			
			# set speed
			mats.back().set_shader_param("speed_ms", 250)
			
			# water colors
			for i in range(48, 64):
				colors.push_back(pal[i])
				var index = i-48
				var paramstr = str("color",index)
				mats.back().set_shader_param(paramstr, colors[index])

			# fire colors group 1 , 5 pixels
			colors = []
			for i in range(16,21):
				colors.push_back(pal[i])
				var index = i - 16
				var paramstr = str("color",index+16)
				mats.back().set_shader_param(paramstr, colors[index])

			# fire colors group 2 , 3 pixels
			colors = []
			for i in range(21,24):
				colors.push_back(pal[i])
				var index = i - 21
				var paramstr = str("color",index+21)
				mats.back().set_shader_param(paramstr, colors[index])
		# not a valid game type
		else:
			printerr("Error generating rotating palette, game type unknown = ", gametype)
	
	if mats.size() == 2:
		return mats
	
	return null

func load_strings(filepath):
	var tfile = File.new()
	var strings = []
	var nodecount
	var blockcount
	var nodes = []
	var blocks = []
	
	if tfile.open(filepath, File.READ):
		printerr("Load Strings: Error opening file ", filepath)
		return null
	
	# get node count
	nodecount = tfile.get_16()
	
	# get huffman nodes
	var debugfile = File.new()
	debugfile.open("nodes.txt", File.WRITE)
	for _n in range(0, nodecount):
		var node = {}
		node["id"] = _n # debug
		node["ascii"] = tfile.get_8() # debug
		node["char"] = char(node["ascii"])
		node["parent"] = tfile.get_8()
		node["left_child"] = tfile.get_8()
		node["right_child"] = tfile.get_8()
		debugfile.store_line(str(node))
		nodes.push_back(node)
	debugfile.close()
	
	# get block offsets
	blockcount = tfile.get_16()
	for _b in range(0, blockcount):
		var blockinfo = {}
		blockinfo["id"] = tfile.get_16()
		blockinfo["offset"] = tfile.get_32()
		blockinfo["string_offsets"] = []
		blocks.push_back(blockinfo)
	
	# get data from blocks to generate strings from huffman nodes
	for b in blocks:
		
		var string_entry = {"block_id":b["id"], "strings":[]}
		
		tfile.seek(b["offset"])
		b["string_count"] = tfile.get_16()
		
		# get string offsets (relative from end of block header)
		for n in range(0, b["string_count"]):
			b["string_offsets"].push_back(tfile.get_16())
			
		# get string data
		for offset in b["string_offsets"]:
			var string = ""
			var current_node = nodes.back() # start at the head (the last node in list)
			var character = null
			var string_pos
			var byte
			# string offset relative to end of header
			# block offset + string count + strings offsets list + string offset
			string_pos = b["offset"] + 2 + (b["string_count"]*2) + offset
			tfile.seek(string_pos)
			
			byte = tfile.get_8()
			
			# generate string
			while character != '|':
				
				
				# decode bits (big-endian)
				for j in range(0, 8):
					var bit = (byte >> (7 - j)) & 0x1
					
					# check current node for end of leaf (-1)
					# if reaching end, return the character in that node
					if (current_node["left_child"] == 0xff and !bit) or (current_node["right_child"] == 0xff and bit):
						character = current_node["char"]
						current_node = nodes.back()
						if character == '|':
							break
						else: string += character
					
					# navigate nodes
					if bit == 1: # take the right branch
						current_node = nodes[current_node["right_child"]]
					else: # else take the left branch
						current_node = nodes[current_node["left_child"]]
				
				byte = tfile.get_8()
				
				if character == '|':
					break
			# done getting string
			string_entry["strings"].push_back(string)
		
		# done getting strings for this block
		strings.push_back(string_entry)
		
	# done
	tfile.close()
	return strings

func create_objects(data):
	
	var objects = []
	var objscene = preload("res://objects/object/object.tscn")
	
	# create objects from data (textures, strings, etc)
	if !data.keys().has("images"):
		printerr("Error creating objects, no images found in data.")
		return null
	if !data["images"].keys().has("objects"):
		printerr("Error creating objects, no object images found in data.")
		return null
	
	for obj in data["images"]["objects"]:
		var newobj = objscene.instance()
		newobj.get_node("Sprite3D").texture = obj
		objects.push_back(newobj)
	
	print("Created ", objects.size(), " objects.")
	
	return objects
	
func _get_image_header(var tfile):
	
	var filesize = tfile.get_len()
	
	# read in header datad
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
		"""
		if newoffset < filesize:
			if header["offsets"].empty():
				header["offsets"].push_back(newoffset)
			elif newoffset != header["offsets"].back():
				header["offsets"].push_back(newoffset)
		else: skipped_offsets += 1
		"""
		header["offsets"].push_back(newoffset)
	if skipped_offsets: print("Found and skipped ", skipped_offsets, " null offset records.")
	
	return header

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
	for _n in range(0, bits):
		if _bitptr >= _bits.size(): break
		word = word << 1 | _bits[_bitptr]
		_bitptr += 1
	return word


