library sky;

import 'package:chronosgl/chronosgl.dart';

void RegisterShaderVars() {
  IntroduceNewShaderVar('vRayDirection', ShaderVarDesc(VarTypeVec3, ''));
}

final ShaderObject VertexShader = ShaderObject("SkyV")
  ..AddAttributeVars([aPosition, aTexUV])
  ..AddVaryingVars(['vRayDirection'])
  ..AddUniformVars([uPerspectiveViewMatrix])
  ..SetBody([
    '''
void main() {
    mat3 invcamera = inverse(mat3(uPerspectiveViewMatrix));
    vec3 clippos = vec3(aTexUV * 2.0 - 1.0, 0.9999); 
    vRayDirection = invcamera * clippos;
    gl_Position = vec4(clippos, 1.0);
}
      '''
  ]);

final ShaderObject FragmentShader = ShaderObject("SkyF")
  ..AddVaryingVars(['vRayDirection'])
  ..SetBody([
    '''
void main() {
    oFragColor = vec4(normalize(vRayDirection) * 0.5 + 0.5, 1.0);
}
      '''
  ]);
