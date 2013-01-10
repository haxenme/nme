package nme.display3D.shaders.glsl;

import nme.Vector;
import nme.display3D.textures.Texture;
import nme.geom.Matrix3D;
import nme.display3D.Context3D;
import nme.display3D.Context3DProgramType;

class GLSLFragmentShader extends GLSLShader{

    public function new(glslSource : String, agalInfo : String){
        super(Context3DProgramType.FRAGMENT, glslSource, agalInfo);
    }

    public function setTextureAt(context3D : Context3D, name : String , texture : Texture){
        #if flash
        var registerIndex = getRegisterIndexForSampler(name);
        context3D.setTextureAt( registerIndex, texture);
        #elseif cpp
        context3D.setGLSLTextureAt(name, texture);
        #end
    }

    override private function getRegisterIndexForUniform(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        if(registerName == null){
            registerName = name;
        }
        return Std.parseInt(registerName.substr(2)); //fc
    }

    private function getRegisterIndexForSampler(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        return Std.parseInt(registerName.substr(2)); //fs
    }

}
