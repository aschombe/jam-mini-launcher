shader_type canvas_item;

uniform float xpos = 0.0;
uniform float num = -0.025;
uniform float offset = 0.5;

float fun(float x,float y){
	return ((num)*x*x - (num)*x) + offset;
}

void fragment() {
	// Called for every pixel the material is visible on.
	float uvx = xpos + UV.x;
	vec2 defuv = vec2(UV.x,UV.y - fun(UV.x+xpos,UV.y));
	vec4 col = texture(TEXTURE,defuv);
	//
	if(
		defuv.x > 1.0
		|| defuv.y > 1.0
		|| defuv.x < 0.0
		|| defuv.y < 0.0
	){
		col = vec4(0.0,0.0,0.0,0.0);
	}
	COLOR = col;
}

/*
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    float distortionarc = -0.09;
    float yOffset = -0.13;
    float pinch = 1.1;

    // Time varying pixel color
    //uv.y/(uv.x*uv.x*-0.3 + 0.3*uv.x+0.2)
    vec2 defuv = vec2(uv.x*(distortionarc * 75.0)+iTime,(uv.y*pinch)/(uv.x*uv.x*-distortionarc + distortionarc*uv.x-yOffset*2.0));
    vec4 col = texture(iChannel0,defuv);

    if(defuv.y < 2.0 || defuv.y > 4.0){
        col = vec4(1.0,1.0,1.0,1.0);
    }
    if(mod(defuv.x,1.0) < 0.05,mod(defuv.x,1.0) > 0.95){
        col = vec4(1.0,1.0,1.0,1.0);
    }
    if(mod(defuv.y,1.0) < 0.05,mod(defuv.y,1.0) > 0.95){
        col = vec4(1.0,1.0,1.0,1.0);
    }

    // Output to screen
    fragColor = col;
}*/