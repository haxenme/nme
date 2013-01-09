package native.display3D;


import native.utils.Float32Array;
import native.utils.ArrayBufferView;
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
        var bytesPerIndex = 2;
		GL.bindBuffer (GL.ELEMENT_ARRAY_BUFFER, glBuffer);
		GL.bufferData (GL.ELEMENT_ARRAY_BUFFER, new ArrayBufferView(byteArray,byteArrayOffset + startOffset * bytesPerIndex, count * bytesPerIndex), GL.STATIC_DRAW);
	}
	
	
	public function uploadFromVector (data:Vector<Int>, startOffset:Int, count:Int):Void {
        GL.bindBuffer (GL.ELEMENT_ARRAY_BUFFER, glBuffer);
        GL.bufferData (GL.ELEMENT_ARRAY_BUFFER, new Float32Array(data, startOffset, count), GL.STATIC_DRAW);
	}

    public function dispose ():Void {
        GL.deleteBuffer(glBuffer);
    }
	
	
}