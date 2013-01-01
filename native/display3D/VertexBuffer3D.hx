package native.display3D;
import nme.utils.ByteArray;
import nme.gl.GL;
class VertexBuffer3D {
    public var glBuffer : nme.gl.Buffer;
    public var numVertices : Int;
    public var data32PerVertex : Int;
    public function new(glBuffer : nme.gl.Buffer, numVertices : Int, data32PerVertex : Int) {
        this.glBuffer = glBuffer;
        this.numVertices = numVertices;
        this.data32PerVertex = data32PerVertex;
    }

    public function uploadFromByteArray(byteArray : ByteArray, byteArrayOffset : Int, startOffset : Int, count : Int): Void{
        // TODO deal with other agruments   ?
        GL.bindBuffer(GL.ARRAY_BUFFER, glBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, byteArray, GL.STATIC_DRAW);
    }
}