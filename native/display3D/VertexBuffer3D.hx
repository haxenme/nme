package native.display3D;


import native.gl.GL;
import native.utils.ByteArray;
import nme.Vector;


class VertexBuffer3D {
	
	
	public var data32PerVertex:Int;
	public var glBuffer:Buffer;
	public var numVertices:Int;
	
	
	public function new (glBuffer:Buffer, numVertices:Int, data32PerVertex:Int) {
		
		this.glBuffer = glBuffer;
		this.numVertices = numVertices;
		this.data32PerVertex = data32PerVertex;
		
	}
	
	
	public function dispose ():Void {
		
		// TODO
		
	}
	
	
	public function uploadFromByteArray (byteArray:ByteArray, byteArrayOffset:Int, startOffset:Int, count:Int):Void {
		
        // TODO deal with other arguments   ?
		
        GL.bindBuffer (GL.ARRAY_BUFFER, glBuffer);
        GL.bufferData (GL.ARRAY_BUFFER, byteArray, GL.STATIC_DRAW);
		
	}
	
	
	public function uploadFromVector (data:Vector<Float>, startVertex:Int, numVertices:Int):Void {
		
		// TODO
		
	}
	
	
}