library fractal;

import 'package:chronosgl/chronosgl.dart';

const String uIter = "uIter";

void RegisterShaderVars() {
  IntroduceNewShaderVar(uIter, ShaderVarDesc(VarTypeInt, ""));
}

final ShaderObject VertexShader = ShaderObject("Textured")
  ..AddAttributeVars([aPosition, aTexUV])
  ..AddVaryingVars([vTexUV])
  ..SetBodyWithMain([
    "gl_Position = vec4(${aPosition}.xy, 0, 1.0);",
    "${vTexUV} = ${aTexUV};",
  ]);

final ShaderObject FragmentShader = ShaderObject("GOL-Fragment")
  ..AddVaryingVars([vTexUV])
  ..SetBody([
    """
    
float getr(int n) {
   if (n == 0) return 0.0;
    else if (n < 32) return (float(n) - 1.0) / (32.0 - 1.0) * 0.8;
    else if (n < 64) return (float(n) - 32.0) / (64.0 - 32.0) * 0.2 + 0.8;
    else if (n < 192) return 1.0;
    else if (n < 254) return 1.0 - (float(n) - 192.0) / (254.0 - 192.0);
    else return 0.0;
}

float getg(int n) {
    if (n < 32) return 0.0;
    else if (n < 65) return (float(n) - 32.0) / (65.0 - 32.0) * 0.8;
    else if (n < 96) return (float(n) - 65.0) / (96.0 - 65.0) * 0.2 + 0.8;
    else if (n < 144) return 1.0;
    else if (n < 192) return 1.0 - (float(n) - 144.0) / (192.0 - 144.0);
    else return 0.0;
}

 float getb(int n) {
    if (n <= 63) return 0.0;
    else if (n < 96) return (float(n) - 64.0) / (96.0 - 64.0);
    else if (n == 96) return 1.0;
    else if (n < 144) return 1.0 - (float(n) - 97.0) / (144.0 - 97.0);
    else return 0.0;
}
        
void main() {
    int ${uIter} = 256;
    vec2 c = 3.0 * (${vTexUV} - 0.5);
    vec2 z = c;

    int i;
    for(i=0; i < ${uIter}; i++) {
        float x = (z.x * z.x - z.y * z.y) + c.x;
        float y = (z.y * z.x + z.x * z.y) + c.y;

        if ((x * x + y * y) > 4.0) break;
        z.x = x;
        z.y = y;
    }

    int n = 255 * i / ${uIter};
    ${oFragColor}.r  = getr(n);
    ${oFragColor}.g  = getg(n);
    ${oFragColor}.b  = getb(n);
    ${oFragColor}.a  = 1.0;
}   

			
"""
  ]);
