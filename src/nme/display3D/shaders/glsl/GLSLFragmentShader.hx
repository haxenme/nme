package nme.display3D.shaders.glsl;

import nme.Vector;
import nme.display3D.textures.Texture;
import nme.geom.Matrix3D;
import nme.display3D.Context3D;
import nme.display3D.Context3DProgramType;

@:nativeProperty
class GLSLFragmentShader extends GLSLShader{

    #if (!flash || js)
    private var textureCounter : Int;
    #end


    public function new(glslSource : String,
        #if (!flash || js)
        ?
        #elseif glsl2agal
        ?
        #end
        agalInfo : String){
        super(Context3DProgramType.FRAGMENT, glslSource, agalInfo);
    }

    #if (!flash || js)
    override public function setup(context3D : Context3D) : Void{
        super.setup(context3D);
        textureCounter = 0;
    }
    #end


    public function setTextureAt(context3D : Context3D, name : String , texture : Texture){
        #if flash
        var registerIndex = getRegisterIndexForSampler(name);
        context3D.setTextureAt( registerIndex, texture);
        #elseif (!flash || js)
        context3D.setGLSLTextureAt(name, texture, textureCounter);
        textureCounter ++;
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
