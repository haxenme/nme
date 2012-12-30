package native.display3D;

import nme.errors.Error;
import nme.display3D.Context3DVertexBufferFormat;
import native.display3D.Program3D;
import native.geom.Rectangle;
import nme.display3D.IndexBuffer3D;
import nme.display3D.VertexBuffer3D;
import nme.display3D.textures.Texture;
import native.display3D.Context3DTextureFormat;
import nme.display3D.Program3D;

import native.gl.GL;

class Context3D {

    private var currentProgram : Program3D;

	private var ogl : native.display.OpenGLView;


    // to mimic stage3d behavior of keeping blendign accross frame:
    private var blendEnabled : Bool = false;
    private var blendSourceFactor : Int;
    private var blendDestinationFactor : Int;

    // to mimc stage3d behavior of not allowing to call drawTriangles between present and clear
    private var drawing : Bool;

    public function new() {
	    var stage = nme.Lib.current.stage;

	    ogl = new native.display.OpenGLView();

	    ogl.scrollRect = new nme.geom.Rectangle(0,0,stage.stageWidth,stage.stageHeight);
	    ogl.width = stage.stageWidth;
	    ogl.height = stage.stageHeight;
	    stage.addChildAt(ogl, 0);
    }

	public function setRenderMethod(func : Rectangle -> Void) : Void{
	    ogl.render = func;
	}

	public function clear(red : Float = 0, green : Float = 0, blue : Float = 0, alpha : Float = 1, depth : Float = 1, stencil : Int = 0, mask : Int = Context3DClearMask.ALL) : Void{

        if(drawing == false){
            updateBlendStatus();
            drawing = true;
        }

		// TODO do not set clear color if not necessary ?
		GL.clearColor(red,green,blue,alpha);
        GL.clearDepth(depth);
        GL.clearStencil(stencil);

		GL.clear(mask);
	}

	public function configureBackBuffer(width : Int, height : Int, antiAlias : Int, enableDepthAndStencil : Bool = true) : Void{
		ogl.scrollRect = new nme.geom.Rectangle(0,0,width,height);   // TODO use other arguments
	}

	public function createIndexBuffer(numIndices : Int) : IndexBuffer3D{
		return new IndexBuffer3D(GL.createBuffer(), numIndices);  // TODO use arguments ?
	}


	public function createTexture(width : Int, height : Int, format : Context3DTextureFormat, optimizeForRenderToTexture : Bool, streamingLevels : Int = 0) : Texture{
		return new native.display3D.textures.Texture(GL.createTexture());     // TODO use arguments ?
	}

	public function createVertexBuffer(numVertices : Int, data32PerVertex : Int) : VertexBuffer3D{
		return new VertexBuffer3D(GL.createBuffer(), numVertices, data32PerVertex);      // TODO use arguments ?
	}

	public function dispose() : Void{
		// TODO
	}


	public function drawTriangles(indexBuffer : IndexBuffer3D, firstIndex : Int = 0, numTriangles : Int = -1) : Void{
        if(!drawing){
            throw new Error("Need To Clear Before Draw: If the buffer has not been cleared since the last present() call.");
        }
        var numIndices;
        if(numTriangles == -1){
            numIndices = indexBuffer.numIndices;
        }else{
            numIndices = numTriangles * 3;
        }
		GL.drawElements(GL.TRIANGLES, numIndices, GL.UNSIGNED_SHORT, firstIndex);
	}

	public function present() : Void{
        drawing = false;
		GL.useProgram(null);
	}

	public function setColorMask(red : Bool, green : Bool, blue : Bool, alpha : Bool) : Void{
		GL.colorMask(red, green, blue, alpha);
	}

	public function setBlendFactors(sourceFactor :Int, destinationFactor : Int) : Void{
		blendEnabled = true;
        blendSourceFactor = sourceFactor;
        blendDestinationFactor = destinationFactor;
        updateBlendStatus();
	}

    private function updateBlendStatus() : Void{
        if(blendEnabled){
            GL.enable(GL.BLEND);
            GL.blendEquation(GL.FUNC_ADD);
            GL.blendFunc(blendSourceFactor, blendDestinationFactor);
        }else{
            GL.disable(GL.BLEND);
        }
    }

    public function createProgram() : Program3D{
        return new Program3D(GL.createProgram());
    }

    public function setProgram(program3D : Program3D) : Void{
        var glProgram : Program = null;
        if (program3D != null){
            glProgram = program3D.glProgram;
        }
        GL.useProgram(glProgram);
        currentProgram = program3D;
    }

    public function setProgramConstantsFromMatrix(programType : Int, firstRegister : Int, matrix : nme.geom.Matrix3D, transposedMatrix : Bool = false) : Void{
        var uniformPrefix =
        switch(programType){
            case Context3DProgramType.VERTEX: "vc";
            case Context3DProgramType.FRAGMENT: "fc";
            default : throw "program Type " + programType + " not supported";
        };
        var location = GL.getUniformLocation(currentProgram.glProgram, uniformPrefix + firstRegister);
        GL.uniformMatrix3D(location, !transposedMatrix, matrix);
    }

    // TODO use TextureBase
    public function setTextureAt(sampler : Int, texture : nme.display3D.textures.Texture) : Void{
        var location =  GL.getUniformLocation(currentProgram.glProgram, "fs" + sampler);

        // TODO multiple active textures (get an id from the Texture Wrapper (native.display3D.textures.Texture) ? )
        GL.activeTexture(GL.TEXTURE0);

        GL.bindTexture(GL.TEXTURE_2D, texture.glTexture);
        GL.uniform1i(location, 0);

        // TODO : should this be defined in the shader ? in some way?
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE );
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE );
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        /////////////////////////////////////////////////////////////////
    }

    public function setVertexBufferAt(index : Int, buffer : VertexBuffer3D, bufferOffset : Int = 0, ?format : Context3DVertexBufferFormat) : Void{
        var location = GL.getAttribLocation(currentProgram.glProgram, "va" + index);
        GL.bindBuffer(GL.ARRAY_BUFFER, buffer.glBuffer);
        var dimension : Int = 4;
        var type : Int = GL.FLOAT;
        var numBytes : Int =4;
        switch(format){
            case  Context3DVertexBufferFormat.BYTES_4:
                dimension = 4;
                type = GL.FLOAT;
                numBytes = 4;
            case Context3DVertexBufferFormat.FLOAT_1 :
                dimension = 1;
                type = GL.FLOAT;
                numBytes = 4;
            case Context3DVertexBufferFormat.FLOAT_2 :
                dimension = 2;
                type = GL.FLOAT;
                numBytes = 4;
            case Context3DVertexBufferFormat.FLOAT_3 :
                dimension = 3;
                type = GL.FLOAT;
                numBytes = 4;

            case Context3DVertexBufferFormat.FLOAT_4 :
                dimension = 4;
                type = GL.FLOAT;
                numBytes = 4;
            default : throw "Buffer format " + format + " not supported";
        }
        GL.vertexAttribPointer(location, dimension, type, false, buffer.data32PerVertex * numBytes, bufferOffset * numBytes);
        GL.enableVertexAttribArray(location);
    }

    // should be enum Context3DTriangleFace
    public function setCulling(triangleFaceToCull : Int) : Void{
        GL.cullFace(triangleFaceToCull);
        GL.enable(GL.CULL_FACE);
    }

// TODO but currently Context3DCompare has wrong value for Depth Test (see native.gl.GL)
    //passCompareMode should be enum  Context3DCompareMode
//    public function setDepthTest(depthMask : Bool, passCompareMode : Int) : Void{
//        GL.depthFunc(passCompareMode);
//        GL.enable(GL.DEPTH_TEST);
//        GL.enable(GL.STENCIL_TEST);
//        GL.depthMask(depthMask);
//    }

}
