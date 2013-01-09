package nme.display3D.shaders.glsl;
import nme.display3D.Program3D;
import nme.display3D.Context3D;
class GLSLProgram {

    private var context3D : Context3D;

    public var nativeProgram : Program3D; // TODO make it private and add API to set use, set uniform and buffers...

    public function new(context3D : Context3D) {
        this.context3D = context3D;
        nativeProgram = context3D.createProgram();
    }

    public function upload(vertexShader : GLSLVertexShader, fragmentShader : GLSLFragmentShader) : Void{
        nativeProgram.upload(vertexShader.nativeShader, fragmentShader.nativeShader);
    }

    public function dispose() : Void{
        nativeProgram.dispose();
    }
}
