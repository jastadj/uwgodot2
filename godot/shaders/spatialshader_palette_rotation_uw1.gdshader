shader_type spatial;
render_mode specular_schlick_ggx;
//render_mode unshaded;


uniform sampler2D img:hint_albedo;
// 4 color palette rotator
uniform float speed_ms = 250.0;
uniform vec2 scale = vec2(1.0,1.0);
// water effect (4 sets of 4 colors, rotating down)
uniform vec4 color0;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform vec4 color4;
uniform vec4 color5;
uniform vec4 color6;
uniform vec4 color7;
uniform vec4 color8;
uniform vec4 color9;
uniform vec4 color10;
uniform vec4 color11;
uniform vec4 color12;
uniform vec4 color13;
uniform vec4 color14;
uniform vec4 color15;
// fire effect group 1 (5 colors, rotating up)
uniform vec4 color16;
uniform vec4 color17;
uniform vec4 color18;
uniform vec4 color19;
uniform vec4 color20;
// fire effect group 2 (3 colors, rotating up)
uniform vec4 color21;
uniform vec4 color22;
uniform vec4 color23;

bool colors_match(vec4 c1, vec4 c2)
{
	float tolerance = 0.001;
	
	// red
	if ( !(c1.r >= (c2.r - tolerance) && c1.r <= (c2.r + tolerance)) ) return false;
	// green
	if ( !(c1.g >= (c2.g - tolerance) && c1.g <= (c2.g + tolerance)) ) return false;
	// blue
	if ( !(c1.b >= (c2.b - tolerance) && c1.b <= (c2.b + tolerance)) ) return false;
	
	return true;
}

void fragment() {
	vec4 current_color = texture(img, UV.xy * scale); // get pixel color
	vec3 rgb_color;
	int cycle1 = int(TIME/(speed_ms*0.001))%4;
	int cycle2 = int(TIME/(speed_ms*0.001))%5;
	int cycle3 = int(TIME/(speed_ms*0.001))%3;
	
	// water effect
	if (cycle1 == 0)
	{
		// colors 0-3
		if (colors_match(current_color,color0)) current_color = color1;
		else if (colors_match(current_color,color1)) current_color = color2;
		else if (colors_match(current_color,color2)) current_color = color3;
		else if (colors_match(current_color,color3)) current_color = color4;
		
		// color 4-7
		else if (colors_match(current_color,color4)) current_color = color5;
		else if (colors_match(current_color,color5)) current_color = color6;
		else if (colors_match(current_color,color6)) current_color = color7;
		else if (colors_match(current_color,color7)) current_color = color4;
		
		// color 8-11
		else if (colors_match(current_color,color8)) current_color = color9;
		else if (colors_match(current_color,color9)) current_color = color10;
		else if (colors_match(current_color,color10)) current_color = color11;
		else if (colors_match(current_color,color11)) current_color = color8;
		
		// color 12-15
		else if (colors_match(current_color,color12)) current_color = color13;
		else if (colors_match(current_color,color13)) current_color = color14;
		else if (colors_match(current_color,color14)) current_color = color15;
		else if (colors_match(current_color,color15)) current_color = color12;
	}
	else if (cycle1 == 1)
	{
		// colors 0-3
		if (colors_match(current_color,color0)) current_color = color2;
		else if (colors_match(current_color,color1)) current_color = color3;
		else if (colors_match(current_color,color2)) current_color = color0;
		else if (colors_match(current_color,color3)) current_color = color1;
		
		// color 4-7
		else if (colors_match(current_color,color4)) current_color = color6;
		else if (colors_match(current_color,color5)) current_color = color7;
		else if (colors_match(current_color,color6)) current_color = color4;
		else if (colors_match(current_color,color7)) current_color = color5;
		
		// color 8-11
		else if (colors_match(current_color,color8)) current_color = color10;
		else if (colors_match(current_color,color9)) current_color = color11;
		else if (colors_match(current_color,color10)) current_color = color8;
		else if (colors_match(current_color,color11)) current_color = color9;
		
		// color 12-15
		else if (colors_match(current_color,color12)) current_color = color14;
		else if (colors_match(current_color,color13)) current_color = color15;
		else if (colors_match(current_color,color14)) current_color = color12;
		else if (colors_match(current_color,color15)) current_color = color13;
	}
	else if (cycle1 == 2)
	{
		// colors 0-3
		if (colors_match(current_color,color0)) current_color = color3;
		else if (colors_match(current_color,color1)) current_color = color0;
		else if (colors_match(current_color,color2)) current_color = color1;
		else if (colors_match(current_color,color3)) current_color = color2;
		
		// color 4-7
		else if (colors_match(current_color,color4)) current_color = color7;
		else if (colors_match(current_color,color5)) current_color = color4;
		else if (colors_match(current_color,color6)) current_color = color5;
		else if (colors_match(current_color,color7)) current_color = color6;
		
		// color 8-11
		else if (colors_match(current_color,color8)) current_color = color11;
		else if (colors_match(current_color,color9)) current_color = color8;
		else if (colors_match(current_color,color10)) current_color = color9;
		else if (colors_match(current_color,color11)) current_color = color10;
		
		// color 12-15
		else if (colors_match(current_color,color12)) current_color = color15;
		else if (colors_match(current_color,color13)) current_color = color12;
		else if (colors_match(current_color,color14)) current_color = color13;
		else if (colors_match(current_color,color15)) current_color = color14;
	}
	
	// fire effect group 1
	if (cycle2 == 0)
	{
		// colors 16-20
		if (colors_match(current_color,color16)) current_color = color20;
		else if (colors_match(current_color,color17)) current_color = color16;
		else if (colors_match(current_color,color18)) current_color = color17;
		else if (colors_match(current_color,color19)) current_color = color18;
		else if (colors_match(current_color,color20)) current_color = color19;
	}
	else if (cycle2 == 1)
	{
		// colors 16-20
		if (colors_match(current_color,color16)) current_color = color19;
		else if (colors_match(current_color,color17)) current_color = color20;
		else if (colors_match(current_color,color18)) current_color = color16;
		else if (colors_match(current_color,color19)) current_color = color17;
		else if (colors_match(current_color,color20)) current_color = color18;
	}
	else if (cycle2 == 2)
	{
		// colors 16-20
		if (colors_match(current_color,color16)) current_color = color18;
		else if (colors_match(current_color,color17)) current_color = color19;
		else if (colors_match(current_color,color18)) current_color = color20;
		else if (colors_match(current_color,color19)) current_color = color16;
		else if (colors_match(current_color,color20)) current_color = color17;
	}
	else if (cycle2 == 3)
	{
		// colors 16-20
		if (colors_match(current_color,color16)) current_color = color17;
		else if (colors_match(current_color,color17)) current_color = color18;
		else if (colors_match(current_color,color18)) current_color = color19;
		else if (colors_match(current_color,color19)) current_color = color20;
		else if (colors_match(current_color,color20)) current_color = color16;
	}
	
	// fire effect group 2
	// fire effect group 1
	if (cycle3 == 0)
	{
		// colors 21-23
		if (colors_match(current_color,color21)) current_color = color23;
		else if (colors_match(current_color,color22)) current_color = color21;
		else if (colors_match(current_color,color23)) current_color = color22;
	}
	if (cycle3 == 1)
	{
		// colors 21-23
		if (colors_match(current_color,color21)) current_color = color22;
		else if (colors_match(current_color,color22)) current_color = color23;
		else if (colors_match(current_color,color23)) current_color = color21;
	}
	
	rgb_color = vec3(current_color.r, current_color.g, current_color.b);
	
	ALBEDO = rgb_color;
}
