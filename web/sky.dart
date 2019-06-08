library sky;

import 'package:chronosgl/chronosgl.dart';

void RegisterShaderVars() {
  IntroduceNewShaderVar('vScreenPosition', ShaderVarDesc(VarTypeVec2, ''));
}

final ShaderObject VertexShader = ShaderObject("SkyV")
    ..AddAttributeVars([aPosition, aTexUV])
    ..AddVaryingVars(['vScreenPosition'])
    ..SetBody([
      '''
 void main() {
     vScreenPosition = ${aTexUV};
     gl_Position = vec4(${aTexUV} * 2.0 - 1.0, 0.9999, 1.0);
 }
      '''
    ]);

final ShaderObject FragmentShader = ShaderObject("SkyF")
    ..AddVaryingVars(['vScreenPosition'])
    ..SetBody([
      '''
void main() {
    oFragColor = vec4(vScreenPosition, 0.0, 1.0);
}
      '''
    ]);
