package nme.display3D.shaders.glsl;

import nme.geom.Matrix3D;
import nme.display3D.textures.Texture;
import nme.display3D.Context3D;
import nme.display3D.VertexBuffer3D;
import nme.display3D.Context3DVertexBufferFormat;
import nme.display3D.Context3DProgramType;

@:nativeProperty
class GLSLVertexShader extends GLSLShader{

    public function new(glslSource : String,
    #if (!flash || js)
    ?
    #elseif glsl2agal
    ?
    #end
    agalInfo : String) {
        super(Context3DProgramType.VERTEX, glslSource, agalInfo);
    }

    public function setVertexBufferAt(context3D : Context3D, name : String, vertexBuffer : VertexBuffer3D, bufferOffset : Int, format : Context3DVertexBufferFormat) : Void{
        #if flash
        var registerIndex = getRegisterIndexForVarying(name);
        context3D.setVertexBufferAt(registerIndex, vertexBuffer, bufferOffset, format);
        #elseif (!flash || js)
        context3D.setGLSLVertexBufferAt(name, vertexBuffer, bufferOffset, format);
        #end
    }


    private function getRegisterIndexForVarying(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        return Std.parseInt(registerName.substr(2)); //va
    }

    override private function getRegisterIndexForUniform(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        if(registerName == null){
            registerName = name;
        }
        return Std.parseInt(registerName.substr(2)); //vc
    }

}
