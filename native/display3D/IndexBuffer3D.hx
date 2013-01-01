package native.display3D;


import native.gl.GL;
import native.utils.ByteArray;
import nme.Vector;


class IndexBuffer3D {
	
	
	public var glBuffer:Buffer;
	public var numIndices:Int;
	
	
	public function new (glBuffer:Buffer, numIndices:Int) {
		
		this.glBuffer = glBuffer;
		this.numIndices = numIndices;
		
	}
	
	
	public function uploadFromByteArray (byteArray:ByteArray, byteArrayOffset:Int, startOffset:Int, count:Int):Void {
		
		// TODO deal with other agruments   ?
		
		GL.bindBuffer (GL.ELEMENT_ARRAY_BUFFER, glBuffer);
		GL.bufferData (GL.ELEMENT_ARRAY_BUFFER, byteArray, GL.STATIC_DRAW);
		
	}
	
	
	public function uploadFromVector (data:Vector<Int>, startOffset:Int, count:Int):Void {
		
		// TODO
		
	}
	
	
}