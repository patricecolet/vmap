//PatCo 2013
#extension GL_ARB_texture_rectangle : enable

uniform float blurAmnt;
uniform sampler2DRect myTex;

void main( void )
{
    vec2 st = gl_TexCoord[0].st;

    vec4 color = texture2DRect(myTex, (gl_TextureMatrix[0] * gl_TexCoord[0]).st);

    color += 1.0 * texture2DRect(myTex, st + vec2(blurAmnt * -4.0, 0));
    color += 2.0 * texture2DRect(myTex, st + vec2(blurAmnt * -3.0, 0));
    color += 3.0 * texture2DRect(myTex, st + vec2(blurAmnt * -2.0, 0));
    color += 4.0 * texture2DRect(myTex, st + vec2(blurAmnt * -1.0, 0));

    color += 5.0 * texture2DRect(myTex, st + vec2(blurAmnt , 0));

    color += 4.0 * texture2DRect(myTex, st + vec2(blurAmnt * 1.0, 0));
    color += 3.0 * texture2DRect(myTex, st + vec2(blurAmnt * 2.0, 0));
    color += 2.0 * texture2DRect(myTex, st + vec2(blurAmnt * 3.0, 0));
    color += 1.0 * texture2DRect(myTex, st + vec2(blurAmnt * 4.0, 0));

    color /= 5.0;
    gl_FragColor = color;
}
