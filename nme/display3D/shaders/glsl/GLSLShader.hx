package nme.display3D.shaders.glsl;


import nme.display3D.Program3D;
using nme.Vector;
import nme.display3D.textures.Texture;
import nme.display3D.Context3DVertexBufferFormat;
import nme.display3D.VertexBuffer3D;
import nme.display3D.Context3D;
import nme.geom.Matrix3D;
import nme.display3D.Context3DProgramType;
import nme.display3D.shaders.ShaderUtils;

import haxe.Json;

typedef AgalInfoData = {
    types : Dynamic,
    consts : Dynamic,
    storage : Dynamic,
    varnames : Dynamic,
    info : String,
    agalasm : String
}

typedef Constant = Array<Float>;

class AgalInfo{
    public var types : Hash<String>;
    public var consts : Hash<Constant>;
    public var storage : Hash<String>;
    public var varnames : Hash<String>;
    public var info : String;
    public var agalasm : String;

    public function new(agalInfoData : AgalInfoData) {
        types = populate(agalInfoData.types);
        consts = populate(agalInfoData.consts);
        storage = populate(agalInfoData.storage);
        varnames = populate(agalInfoData.varnames);
        info = agalInfoData.info;
        agalasm = agalInfoData.agalasm;
    }

    private function populate<Type>(data) : Hash<Type>{
        var hash = new Hash();
        for (key in Reflect.fields(data)) {
            hash.set(key, Reflect.field(data, key));
        }
        return hash;
    }
}

class GLSLShader {

    //#if flash
    private var agalInfo : AgalInfo;
    //#end
    public var type : Context3DProgramType;
    public var nativeShader : nme.display3D.shaders.Shader;


    // TODO make agalInfo optional for cpp or when glsl2agal is enabled (TODO in subclass as well)
    public function new(type : Context3DProgramType, glslSource : String, agalInfoJson : String) {

        this.type = type;
        #if cpp
            nativeShader = ShaderUtils.createShader(type,glslSource);
        #elseif flash
            #if glsl2agal
                var glsl2agal = new nme.display3D.shaders.GlslToAgal(glslSource, cast(type));
                agalInfoJson = glsl2agal.compile();
            #end

            var agalInfoData : AgalInfoData = Json.parse(agalInfoJson);
            agalInfo = new AgalInfo(agalInfoData);
            var agalSource = agalInfo.agalasm;


            nativeShader = ShaderUtils.createShader(type,agalSource);
        #end

    }

    public function setUniformFromMatrix(context3D : Context3D, name : String , matrix : Matrix3D,transposedMatrix : Bool = false) : Void{
        #if flash
        var registerIndex = getRegisterIndexForUniform(name);
        context3D.setProgramConstantsFromMatrix(type, registerIndex, matrix, transposedMatrix);
        #elseif cpp
        context3D.setGLSLProgramConstantsFromMatrix(name, matrix, transposedMatrix);
        #end
    }

    //TODO add setUniformFromByteArray

    // TODO do not use vector but use 4 float arguments ?
    // for now it only use the first 4 float in the vector
    public function setUniformFromVector(context3D : Context3D, name : String , vector : Vector<Float>) : Void{
        #if flash
        var registerIndex = getRegisterIndexForUniform(name);
        context3D.setProgramConstantsFromVector(type, registerIndex, vector, 1);
        #elseif cpp
        context3D.setGLSLProgramConstantsFromVector4(name, vector);
        #end
    }

    private function getRegisterIndexForUniform(name : String) : Int{
        //SUBCLASS NEED TO IMPLEMENT
        return -1;
    }

    public function setup(context3D : Context3D) : Void{
        #if flash
        for (constantName in agalInfo.consts.keys()){
            setUniformFromVector(context3D, constantName, Vector.ofArray(agalInfo.consts.get(constantName)));
        }
        #end
    }



}
