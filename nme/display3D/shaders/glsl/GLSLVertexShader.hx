package nme.display3D.shaders.glsl;

import nme.display3D.Context3DProgramType;
class GLSLVertexShader extends GLSLShader{

    public function new(glslSource : String, agalInfo : String) {
        super(Context3DProgramType.VERTEX, glslSource, agalInfo);
    }
}
