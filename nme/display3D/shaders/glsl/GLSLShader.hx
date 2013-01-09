package nme.display3D.shaders.glsl;

import nme.display3D.Context3DProgramType;
import nme.display3D.shaders.ShaderUtils;

import haxe.Json;

typedef AgalInfo = {
    types : Dynamic,
    consts : Dynamic,
    storage : Dynamic,
    varnames : Dynamic,
    info : Dynamic,
    agalasm : Dynamic
}

class GLSLShader {

    public var nativeShader : nme.display3D.shaders.Shader;

    // TODO make agalInfo optional for cpp or when glsl2agal is enabled (TODO in subclass as well)
    public function new(type : Context3DProgramType, glslSource : String, agalInfo : String) {


        #if cpp
            nativeShader = ShaderUtils.createShader(type,glslSource);
        #elseif flash
            #if glsl2agal
                var glsl2agal = new GLSL2AGAL(glslSource);
                agalInfo = glsl2agal.convert();
            #end

            var agalInfoData : AgalInfo = Json.parse(agalInfo);


            //for (key in Reflect.fields(objectData.offices)) {
	        //var office:Office = Reflect.field(objectData.offices, key);
	        //trace(office);
            //}

            trace(agalInfoData);
            trace(agalInfoData.agalasm);
            var agalSource = agalInfoData.agalasm;


            nativeShader = ShaderUtils.createShader(type,agalSource);
        #end



    }
}
