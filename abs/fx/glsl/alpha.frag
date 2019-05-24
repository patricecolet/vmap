// Cyrille Henry 2007

//#extension GL_ARB_texture_rectangle : enable
//uniform sampler2DRect MyTex;
uniform sampler2D MyTex;
//uniform float B,C;
uniform float A, O;
uniform vec3 LT, HT;
void main (void)
{
// vec4 col = texture2DRect(MyTex, (gl_TextureMatrix[0] * gl_TexCoord[0]).st);
 vec4 col = texture2D(MyTex, (gl_TextureMatrix[0] * gl_TexCoord[0]).st);

// col *= B+1.; // brightness
// vec4 gray = vec4(dot(col.rgb,vec3(0.2125,  0.7154, 0.0721)));
// col = mix(gray, col, C+1.); // contrast
    
      if ( (col.r >= LT.r &&  col.r <= HT.r )
	   &&
	   (col.g >= LT.g &&  col.g <= HT.g )
	   &&
	   (col.b >= LT.b &&  col.b <= HT.b ) ) {
	col.a = A;
      }
      else col.a = O;


 gl_FragColor = col;

}
