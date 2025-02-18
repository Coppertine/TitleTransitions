#version 150

#define M_PI 3.1415926535897932384626433832795

#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

uniform vec2 ScreenSize;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec4 vshColor;

const vec2 HALF = vec2(0.5);

vec2 rotate(vec2 points, float angle) {
	float sinA = sin(angle);
	float cosA = cos(angle);
	float aspect = ScreenSize.x / ScreenSize.y;
	mat2 rotMat   	 = mat2(cosA, -sinA, sinA, cosA);
	mat2 scaleMat 	 = mat2(aspect, 0.0, 0.0, 1.0);
	mat2 scaleMatInv = mat2(1.0 / aspect, 0.0, 0.0, 1.0);
	
	points -= HALF.xy;
	points = scaleMatInv * rotMat * scaleMat * points;
	points += HALF.xy;

	return points;
	// return rotMat * points;
}

float degToRad(float deg) {
	return deg * (M_PI / 180);
}

void main() {
	gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

	vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
	vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
	texCoord0 = UV0;

	vshColor = vec4(0.0);

	// Remove numbers from scoreboard.
	if(gl_Position.z == 0.0 && gl_Position.x >= 0.94 && gl_Position.y >= -0.35 && // Position of sidebar.
		vertexColor == vec4(1.0, 85.0 / 255.0, 85.0 / 255.0, 1.0) && // Colour of numbers on sidebar.
		gl_VertexID <= 3 // First character only (should be mostly irrelevant though).
	) {
		gl_Position = vec4(0.0);
	}

	// title @s title {"text":"a","color":"#002301","font":"pvphub:font"}
	// Isolate color code #XX2301
	if(round(vertexColor.g * 255) == 35 && round(vertexColor.b * 255) == 1 && round(Position.z * 255) == 8) {
		float scaleX = 1 / ScreenSize.x;
		float scaleY = 1 / ScreenSize.y;

		float red = round(vertexColor.r * 255);
		if(red == 0) {
			// 00 => Left to right slide
			if(gl_Position.y < 0) {
				gl_Position.y = -1.0;
			} else {
				gl_Position.y = 1.0;
			}

			if(gl_Position.x > 0) {
				gl_Position.x = -1.0 + vertexColor.a * 2;
			} else {
				gl_Position.x = -1.0;
			}
		} else if(red == 1) {
			// 01 => Right to left slide
			if(gl_Position.y < 0) {
				gl_Position.y = -1.0;
			} else {
				gl_Position.y = 1.0;
			}

			if(gl_Position.x < 0) {
				gl_Position.x = 1.0 - vertexColor.a * 2;
			} else {
				gl_Position.x = 1.0;
			}
		} else if(red == 2) {
			// 02 => Top to Bottom slide
			if(gl_Position.x < 0) {
				gl_Position.x = -1.0;
			} else {
				gl_Position.x = 1.0;
			}

			if(gl_Position.y < 0) {
				gl_Position.y = 1.0 - vertexColor.a * 2;
			} else {
				gl_Position.y = 1.0;
			}
		} else if(red == 3) {
			// 03 => Bottom to Top slide
			if(gl_Position.x < 0) {
				gl_Position.x = -1.0;
			} else {
				gl_Position.x = 1.0;
			}

			if(gl_Position.y > 0) {
				gl_Position.y = -1.0 + vertexColor.a * 2;
			} else {
				gl_Position.y = -1.0;
			}
		} else if(red == 4) {
			// 04 => Fade in
			if(gl_Position.x < 0) {
				gl_Position.x = -1.0;
			} else {
				gl_Position.x = 1.0;
			}

			if(gl_Position.y < 0) {
				gl_Position.y = -1.0;
			} else {
				gl_Position.y = 1.0;
			}
			vertexColor = vec4(0.0, 0.0, 0.0, vertexColor.a);
			return;
		} else if(red == 5) {
			// 05 => Zip left to right

			if(gl_Position.x > 0 && gl_Position.y > 0) {
				// Top right
				gl_Position.x = 1.0;
				gl_Position.y = -1.5;
			} else if(gl_Position.x > 0 && gl_Position.y < 0) {
				// Left 
				gl_Position.x = -100.0;
				gl_Position.y = 0.0;
			} else if(gl_Position.x < 0 && gl_Position.y < 0) {
				// Bottom right
				gl_Position.x = 1.0;
				gl_Position.y = 1.5;
			} else if(gl_Position.x < 0 && gl_Position.y > 0) {
				// Middle
				gl_Position.x = -10.0 + vertexColor.a * 10.0 * 2.0;
				gl_Position.y = 0.0;
			}
		} else if(red == 6) {
			// 06 => Zip right to left
			// Some need swapping around
			if(gl_Position.x > 0 && gl_Position.y > 0) {
				// Top right
				gl_Position.x = 100.0;
				gl_Position.y = 0.0;
			} else if(gl_Position.x > 0 && gl_Position.y < 0) {
				// Left 
				gl_Position.x = -1.0;
				gl_Position.y = -1.5;
			} else if(gl_Position.x < 0 && gl_Position.y < 0) {
				// Bottom right
				gl_Position.x = 10.0 - vertexColor.a * 10.0 * 2.0;
				gl_Position.y = 0.0;
			} else if(gl_Position.x < 0 && gl_Position.y > 0) {
				// Middle
				gl_Position.x = -1.0;
				gl_Position.y = 1.5;
			}
		} else if(red == 7) {
			// 07 => Spin in clockwise
			float rotation = 45.0;
			vec2 rotated = rotate(vec2(gl_Position.x, gl_Position.y), degToRad(rotation));

			gl_Position.x = rotated.x * 10.0;
			// gl_Position.y = rotated.y;
			vertexColor = vec4(rotated.x, 1.0, 1.0, 1.0);
			return;
		}

		// gl_Position.z = 100.0;
		// Set color to black
		vertexColor = vec4(0.0, 0.0, 0.0, 1.0);
	} else if(round(vertexColor.g * 255) == 8 && round(vertexColor.b * 255) == 0) {
		// remove the shadow
		gl_Position = vec4(0.0);
	}
}
