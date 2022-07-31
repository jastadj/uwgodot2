extends Control

var nodes = []

func _ready():
	
	nodes = load_nodes(str(UW.uw1_dir,"/UWDATA/STRINGS.PAK") )
	$input_bytes.connect("text_changed", self, "on_input_text_entered")
	$decompress_button.connect("pressed", self, "on_decompress_pressed")
	

func on_input_text_entered(text):
	if $input_bytes.text.is_valid_hex_number():
		$input_bytes.modulate = Color(1,1,1)
	else:
		$input_bytes.modulate = Color(1,0,0)

func on_decompress_pressed():
	var datastring = $input_bytes.text
	
	var data = PoolByteArray()
	
	for c in range(0, datastring.length()/2):
		var bytestr = str("0x",datastring[c*2], datastring[(c*2)+1])
		var byte = bytestr.hex_to_int()
		data.push_back(byte)
	
	if !datastring.is_valid_hex_number():
		$output.text = "OUTPUT: INVALID INPUT BYTES"
		$output.modulate = Color(1,0,0)
		return
	else:
		$output.text = str("OUTPUT: ", decompress(data) )
		$output.modulate = Color(1,1,1)

func decompress(data:PoolByteArray):
	
	var current_node = nodes.back()
	var string = ""
	var done = false
	
	# check bits for each byte
	for byte in data:
		for b in range(0,8):
			var bit = ( byte >> (7-b) ) & 0x1
			
			if (current_node["left_child"] == 0xff and !bit) or (current_node["right_child"] == 0xff and bit):
				if current_node["char"] != '|':
					string += current_node["char"] 
					current_node = nodes.back()
				else:
					done = true
					break
				
			if bit == 1: current_node = nodes[current_node["right_child"]]
			else : current_node = nodes[current_node["left_child"]]
			
			
		if done: break
	
	print("decompressed string:", string)
	return string
	

func load_nodes(filepath):
	var tfile = File.new()
	var nodecount
	var nodes = []
	
	if tfile.open(filepath, File.READ):
		printerr("Load Huffman Nodes Test: Error opening file ", filepath)
		return null
	
	# get node count
	nodecount = tfile.get_16()
	
	# get huffman nodes
	for _n in range(0, nodecount):
		var node = {}
		node["id"] = _n # debug
		node["ascii"] = tfile.get_8() # debug
		node["char"] = char(node["ascii"])
		node["parent"] = tfile.get_8()
		node["left_child"] = tfile.get_8()
		node["right_child"] = tfile.get_8()
		nodes.push_back(node)
		
	tfile.close()
	return nodes
	
