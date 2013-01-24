package browser.display3D;
#if js


import nme.gl.GL;
import nme.gl.GLBuffer;
import nme.utils.Float32Array;
import nme.utils.Float32Array;
import nme.utils.ByteArray;
import nme.Vector;


class VertexBuffer3D {
	
	
	public var data32PerVertex:Int;
	public var glBuffer:GLBuffer;
	public var numVertices:Int;
	
	
	public function new(glBuffer:GLBuffer, numVertices:Int, data32PerVertex:Int) {
		
		this.glBuffer = glBuffer;
		this.numVertices = numVertices;
		this.data32PerVertex = data32PerVertex;
		
	}

	public function dispose ():Void {
		GL.deleteBuffer(glBuffer);
	}
	
	
	public function uploadFromByteArray (byteArray:ByteArray, byteArrayOffset:Int, startOffset:Int, count:Int):Void {
		var bytesPerVertex = data32PerVertex * 4;
        GL.bindBuffer (GL.ARRAY_BUFFER, glBuffer);
        GL.bufferData (GL.ARRAY_BUFFER, new Float32Array(byteArray,byteArrayOffset + startOffset * bytesPerVertex, count * bytesPerVertex), GL.STATIC_DRAW);
	}
	
	
	public function uploadFromVector (data:Vector<Float>, startVertex:Int, numVertices:Int):Void {
        GL.bindBuffer (GL.ARRAY_BUFFER, glBuffer);
        GL.bufferData (GL.ARRAY_BUFFER, new Float32Array(data, startVertex, numVertices * data32PerVertex), GL.STATIC_DRAW);
	}
	
	
}


#end