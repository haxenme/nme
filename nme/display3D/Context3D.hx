package nme.display3D;
#if display


@:final extern class Context3D extends nme.events.EventDispatcher {
	var driverInfo(default,null) : String;
	var enableErrorChecking : Bool;
	function clear(red : Float = 0, green : Float = 0, blue : Float = 0, alpha : Float = 1, depth : Float = 1, stencil : UInt = 0, mask : UInt = 0xFFFFFFFF) : Void;
	function configureBackBuffer(width : Int, height : Int, antiAlias : Int, enableDepthAndStencil : Bool = true) : Void;
	function createCubeTexture(size : Int, format : Context3DTextureFormat, optimizeForRenderToTexture : Bool, streamingLevels : Int = 0) : nme.display3D.textures.CubeTexture;
	function createIndexBuffer(numIndices : Int) : IndexBuffer3D;
	function createProgram() : Program3D;
	function createTexture(width : Int, height : Int, format : Context3DTextureFormat, optimizeForRenderToTexture : Bool, streamingLevels : Int = 0) : nme.display3D.textures.Texture;
	function createVertexBuffer(numVertices : Int, data32PerVertex : Int) : VertexBuffer3D;
	function dispose() : Void;
	function drawToBitmapData(destination : nme.display.BitmapData) : Void;
	function drawTriangles(indexBuffer : IndexBuffer3D, firstIndex : Int = 0, numTriangles : Int = -1) : Void;
	function present() : Void;
	function setBlendFactors(sourceFactor : Context3DBlendFactor, destinationFactor : Context3DBlendFactor) : Void;
	function setColorMask(red : Bool, green : Bool, blue : Bool, alpha : Bool) : Void;
	function setCulling(triangleFaceToCull : Context3DTriangleFace) : Void;
	function setDepthTest(depthMask : Bool, passCompareMode : Context3DCompareMode) : Void;
	function setProgram(program : Program3D) : Void;
	function setRenderToBackBuffer() : Void;
	function setRenderToTexture(texture : nme.display3D.textures.TextureBase, enableDepthAndStencil : Bool = false, antiAlias : Int = 0, surfaceSelector : Int = 0) : Void;
	function setScissorRectangle(rectangle : nme.geom.Rectangle) : Void;
	function setStencilActions(?triangleFace : Context3DTriangleFace, ?compareMode : Context3DCompareMode, ?actionOnBothPass : Context3DStencilAction, ?actionOnDepthFail : Context3DStencilAction, ?actionOnDepthPassStencilFail : Context3DStencilAction) : Void;
	function setStencilReferenceValue(referenceValue : UInt, readMask : UInt = 255, writeMask : UInt = 255) : Void;



	/**
	 * In Cpp, this function is here for compatibility reason but is not recommended to be used except if you plan to automatically convert AGAL shader to GLSL as this function work on a particular GLSL convention to be compatible with stage3d API.
	 * The recommended method for cross platform shader setup is to use GLSL Shader and to setup and refer uniforms, textures and variables by names
	 * the convention being : vc<AgalRegisterIndex>
	 * @see nme.display3D.shader.GLSLShader
	 */
	@:require(flash11_2) function setProgramConstantsFromByteArray(programType : Context3DProgramType, firstRegister : Int, numRegisters : Int, data : nme.utils.ByteArray, byteArrayOffset : UInt) : Void;

	/**
	 * In Cpp, this function is here for compatibility reason but is not recommended to be used except if you plan to automatically convert AGAL shader to GLSL as this function work on a particular GLSL convention to be compatible with stage3d API.
	 * The recommended method for cross platform shader setup is to use GLSL Shader and to setup and refer uniforms, textures and variables by names
	 * the convention being : mat4 vc<AgalRegisterIndex>
	 * The Glsl constant must be mat4
	 * @see nme.display3D.shader.GLSLShader
	 */
	function setProgramConstantsFromMatrix(programType : Context3DProgramType, firstRegister : Int, matrix : nme.geom.Matrix3D, transposedMatrix : Bool = false) : Void;

	/**
	 * In Cpp, this function is here for compatibility reason but is not recommended to be used except if you plan to automatically convert AGAL shader to GLSL as this function work on a particular GLSL convention to be compatible with stage3d API.
	 * The recommended method for cross platform shader setup is to use GLSL Shader and to setup and refer uniforms, textures and variables by names
	 * the convention being : vec4 vc<AgalRegisterIndex>
	 * The Glsl constant need to be vec4
	 * @see nme.display3D.shader.GLSLShader
	 */
	function setProgramConstantsFromVector(programType : Context3DProgramType, firstRegister : Int, data : nme.Vector<Float>, numRegisters : Int = -1) : Void;

	/**
	 * In Cpp, this function is here for compatibility reason but is not recommended to be used except if you plan to automatically convert AGAL shader to GLSL as this function work on a particular GLSL convention to be compatible with stage3d API.
	 * The recommended method for cross platform shader setup is to use GLSL Shader and to setup and refer uniforms, textures and variables by names
	 * the convention being : fs<AgalRegisterIndex>
	 * @see nme.display3D.shader.GLSLShader
	 */
	function setTextureAt(sampler : Int, texture : nme.display3D.textures.TextureBase) : Void;

	/**
	 * In Cpp, this function is here for compatibility reason but is not recommended to be used except if you plan to automatically convert AGAL shader to GLSL as this function work on a particular GLSL convention to be compatible with stage3d API.
	 * The recommended method for cross platform shader setup is to use GLSL Shader and to setup and refer uniforms, textures and variables by names
	 * the convention being : va<AgalRegisterIndex>
	 * @see nme.display3D.shader.GLSLShader
	 */
	function setVertexBufferAt(index : Int, buffer : VertexBuffer3D, bufferOffset : Int = 0, ?format : Context3DVertexBufferFormat) : Void;
}


#elseif (cpp || neko)
typedef Context3D = native.display3D.Context3D;
#elseif js
typedef Context3D = browser.display3D.Context3D;
#elseif flash
typedef Context3D = flash.display3D.Context3D;
#end