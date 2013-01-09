package nme.display3D.shaders.glsl;


import nme.display3D.Context3DProgramType;

class GLSLFragmentShader extends GLSLShader{

    public function new(glslSource : String, agalInfo : String){
        super(Context3DProgramType.FRAGMENT, glslSource, agalInfo);
    }


}
