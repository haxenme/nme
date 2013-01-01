package native.display3D;
import nme.utils.ByteArray;
import nme.gl.GL;
class IndexBuffer3D {
    public var glBuffer : nme.gl.Buffer;
    public var numIndices : Int;
    public function new(glBuffer : nme.gl.Buffer, numIndices : Int) {
        this.glBuffer = glBuffer;
        this.numIndices = numIndices;
    }

    public function uploadFromByteArray(byteArray : ByteArray, byteArrayOffset : Int, startOffset : Int, count : Int): Void{
        // TODO deal with other agruments   ?
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, glBuffer);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, byteArray, GL.STATIC_DRAW);
    }
}