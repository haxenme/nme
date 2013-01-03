package native.display3D;


import native.display3D.textures.CubeTexture;
import native.display3D.textures.Texture;
import native.display3D.textures.TextureBase;
import native.display.BitmapData;
import native.display.OpenGLView;
import native.errors.Error;
import native.geom.Matrix3D;
import native.geom.Rectangle;
import native.gl.GL;
import native.utils.ByteArray;
import native.Lib;
import nme.Vector;


class Context3D {
	
	
	public var driverInfo (default, null):String; // TODO
	public var enableErrorChecking:Bool; // TODO
	
	private var currentProgram : Program3D;
	private var ogl:OpenGLView;
	
	// to mimic Stage3d behavior of keeping blending across frames:
	private var blendDestinationFactor:Int;
	private var blendEnabled:Bool;
	private var blendSourceFactor:Int;
	
	// to mimic Stage3d behavior of not allowing calls to drawTriangles between present and clear
	private var drawing:Bool;
	
	
	public function new () {
		
		var stage = Lib.current.stage;
		
		ogl = new OpenGLView ();
		ogl.scrollRect = new Rectangle (0, 0, stage.stageWidth, stage.stageHeight);
		ogl.width = stage.stageWidth;
		ogl.height = stage.stageHeight;
		
		stage.addChildAt (ogl, 0);
		
	}
	
	
	public function clear (red:Float = 0, green:Float = 0, blue:Float = 0, alpha:Float = 1, depth:Float = 1, stencil:Int = 0, mask:Int = Context3DClearMask.ALL):Void {
		
		if (!drawing) {
			
			updateBlendStatus ();
			drawing = true;
			
		}
		
		// TODO do not set clear color if not necessary ?
		
		GL.clearColor (red, green, blue, alpha);
		GL.clearDepth (depth);
		GL.clearStencil (stencil);
		
		GL.clear (mask);
		
	}
	
	
	public function configureBackBuffer (width:Int, height:Int, antiAlias:Int, enableDepthAndStencil:Bool = true):Void {
		
		ogl.scrollRect = new Rectangle (0, 0, width, height);   // TODO use other arguments
		
	}
	
	
	public function createCubeTexture (size:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):CubeTexture {
		
		// TODO
		
		return null;
		
	}
	
	
	public function createIndexBuffer (numIndices:Int):IndexBuffer3D {
		
		return new IndexBuffer3D (GL.createBuffer (), numIndices);  // TODO use arguments ?
		
	}
	
	
	public function createProgram ():Program3D {
		
		return new Program3D (GL.createProgram ());
		
	}
	
	
	public function createTexture (width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):native.display3D.textures.Texture {
		
		return new native.display3D.textures.Texture (GL.createTexture ());     // TODO use arguments ?
		
	}
	
	
	public function createVertexBuffer (numVertices:Int, data32PerVertex:Int):VertexBuffer3D {
		
		return new VertexBuffer3D (GL.createBuffer (), numVertices, data32PerVertex);      // TODO use arguments ?
		
	}
	
	
	public function dispose ():Void {
		
		// TODO
		
	}
	
	
	public function drawToBitmapData (destination:BitmapData):Void {
		
		// TODO
		
	}
	
	
	public function drawTriangles (indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1):Void {
		
		if (!drawing) {
			
			throw new Error("Need to clear before drawing if the buffer has not been cleared since the last present() call.");
			
		}
		
		var numIndices;
		
		if (numTriangles == -1) {
			
			numIndices = indexBuffer.numIndices;
			
		} else {
			
			numIndices = numTriangles * 3;
			
		}
		
		GL.drawElements (GL.TRIANGLES, numIndices, GL.UNSIGNED_SHORT, firstIndex);
		
	}
	
	
	public function present ():Void {
		
		drawing = false;
		GL.useProgram (null);
		
	}
	
	
	// TODO: Type as Context3DBlendFactor instead of Int?
	
	public function setBlendFactors (sourceFactor:Int, destinationFactor:Int):Void {
		
		blendEnabled = true;
		blendSourceFactor = sourceFactor;
		blendDestinationFactor = destinationFactor;
		
		updateBlendStatus ();
		
	}
	
	
	public function setColorMask (red:Bool, green:Bool, blue:Bool, alpha:Bool):Void {
		
		GL.colorMask (red, green, blue, alpha);
		
	}
	
	
	// TODO: Type as Context3DTriangleFace instead of Int?
	
	public function setCulling (triangleFaceToCull:Int):Void {
		
		GL.cullFace (triangleFaceToCull);
		GL.enable (GL.CULL_FACE);
		
	}
	
	
	// TODO: Type as Context3DCompareMode insteaad of Int?
	
	public function setDepthTest (depthMask:Bool, passCompareMode:Int):Void {
		
		// TODO but currently Context3DCompare has wrong value for Depth Test (see native.gl.GL)
		//passCompareMode should be enum  Context3DCompareMode
		
		//GL.depthFunc(passCompareMode);
		//GL.enable(GL.DEPTH_TEST);
		//GL.enable(GL.STENCIL_TEST);
		//GL.depthMask(depthMask);
		
	}
	
	
	public function setProgram (program3D:Program3D):Void {
		
		var glProgram:Program = null;
		
		if (program3D != null) {
			
			glProgram = program3D.glProgram;
			
		}
		
		GL.useProgram (glProgram);
		currentProgram = program3D;
		
	}
	
	
	public function setProgramConstantsFromByteArray (programType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray, byteArrayOffset:Int):Void {
		
		// TODO
		
	}
	
	
	// TODO: Use Context3DProgramType instead of Int?
	
	public function setProgramConstantsFromMatrix (programType:Int, firstRegister:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void {
		
		var uniformPrefix = switch (programType) {
			
			case Context3DProgramType.VERTEX: "vc";
			case Context3DProgramType.FRAGMENT: "fc";
			default: throw "Program Type " + programType + " not supported";
			
		};
		
		var location = GL.getUniformLocation (currentProgram.glProgram, uniformPrefix + firstRegister);
		GL.uniformMatrix3D (location, !transposedMatrix, matrix);
		
	}
	
	
	public function setProgramConstantsFromVector (programType:Context3DProgramType, firstRegister:Int, data:Vector<Float>, numRegisters:Int = -1):Void {
		
		// TODO
		
	}
	
	
	// TODO: Conform to API?
	
	public function setRenderMethod (func:Rectangle -> Void):Void {
		
		ogl.render = func;
		
	}
	
	
	public function setRenderToBackBuffer ():Void {
		
		// TODO
		
	}
	
	
	public function setRenderToTexture (texture:TextureBase, enableDepthAndStencil:Bool = false, antiAlias:Int = 0, surfaceSelector:Int = 0):Void {
		
		// TODO
		
	}
	
	
	public function setScissorRectangle (rectangle:Rectangle):Void {
		
		// TODO
		
	}
	
	
	public function setStencilActions (?triangleFace:Context3DTriangleFace, ?compareMode:Context3DCompareMode, ?actionOnBothPass:Context3DStencilAction, ?actionOnDepthFail:Context3DStencilAction, ?actionOnDepthPassStencilFail:Context3DStencilAction):Void {
		
		// TODO
		
	}
	
	
	public function setStencilReferenceValue (referenceValue:Int, readMask:Int = 0xFF, writeMask:Int = 0xFF):Void {
		
		// TODO
		
	}
	
	
	public function setTextureAt (sampler:Int, texture:TextureBase):Void {
		
		if (Std.is (texture, native.display3D.textures.Texture)) {
			
			var location = GL.getUniformLocation (currentProgram.glProgram, "fs" + sampler);
			
			// TODO multiple active textures (get an id from the Texture Wrapper (native.display3D.textures.Texture) ? )
			GL.activeTexture (GL.TEXTURE0);
			
			GL.bindTexture (GL.TEXTURE_2D, cast (texture, native.display3D.textures.Texture).glTexture);
			GL.uniform1i (location, 0);
			
			// TODO : should this be defined in the shader ? in some way?
			GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
			GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
			GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
			GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
			/////////////////////////////////////////////////////////////////
			
		}
		
	}
	
	
	public function setVertexBufferAt (index:Int, buffer:VertexBuffer3D, bufferOffset:Int = 0, ?format:Context3DVertexBufferFormat):Void {
		
		var location = GL.getAttribLocation (currentProgram.glProgram, "va" + index);
		GL.bindBuffer (GL.ARRAY_BUFFER, buffer.glBuffer);
		
		var dimension = 4;
		var type = GL.FLOAT;
		var numBytes = 4;
		
		if (format == Context3DVertexBufferFormat.BYTES_4) {
			
			dimension = 4;
			type = GL.FLOAT;
			numBytes = 4;
			
		} else if (format == Context3DVertexBufferFormat.FLOAT_1) {
			
			dimension = 1;
			type = GL.FLOAT;
			numBytes = 4;
			
		} else if (format == Context3DVertexBufferFormat.FLOAT_2) {
			
			dimension = 2;
			type = GL.FLOAT;
			numBytes = 4;
			
		} else if (format == Context3DVertexBufferFormat.FLOAT_3) {
			
			dimension = 3;
			type = GL.FLOAT;
			numBytes = 4;
			
		} else if (format == Context3DVertexBufferFormat.FLOAT_4) {
			
			dimension = 4;
			type = GL.FLOAT;
			numBytes = 4;
			
		} else {
			
			throw "Buffer format " + format + " is not supported";
			
		}
		
		GL.vertexAttribPointer (location, dimension, type, false, buffer.data32PerVertex * numBytes, bufferOffset * numBytes);
		GL.enableVertexAttribArray (location);
		
	}
	
	
	private function updateBlendStatus ():Void {
		
		if (blendEnabled) {
			
			GL.enable (GL.BLEND);
			GL.blendEquation (GL.FUNC_ADD);
			GL.blendFunc (blendSourceFactor, blendDestinationFactor);
			
		} else {
			
			GL.disable (GL.BLEND);
			
		}
		
	}
	
	
}