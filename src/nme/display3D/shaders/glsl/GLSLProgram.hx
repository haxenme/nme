package nme.display3D.shaders.glsl;
import nme.display3D.Context3DVertexBufferFormat;
import nme.display3D.VertexBuffer3D;
import nme.display3D.textures.Texture;
import nme.geom.Matrix3D;
import nme.display3D.Program3D;
import nme.display3D.Context3D;

@:nativeProperty
class GLSLProgram {

    private var context3D : Context3D;

    private var nativeProgram : Program3D;

    private var vertexShader : GLSLVertexShader;
    private var fragmentShader : GLSLFragmentShader;

    public function new(context3D : Context3D) {
        this.context3D = context3D;
        nativeProgram = context3D.createProgram();
    }

    public function upload(vertexShader : GLSLVertexShader, fragmentShader : GLSLFragmentShader) : Void{
        nativeProgram.upload(vertexShader.nativeShader, fragmentShader.nativeShader);
        this.vertexShader = vertexShader;
        this.fragmentShader = fragmentShader;
    }

    public function dispose() : Void{
        nativeProgram.dispose();
    }

    public function attach() : Void{
        context3D.setProgram(nativeProgram);

        //pass necessary constants (in case of agal)
        vertexShader.setup(context3D);
        fragmentShader.setup(context3D);
    }

    public function detach() : Void{
        context3D.setProgram(null);
    }

    public function setVertexUniformFromMatrix(name : String , matrix : Matrix3D,transposedMatrix : Bool = false) : Void{
        vertexShader.setUniformFromMatrix(context3D,name,matrix, transposedMatrix);
    }

    public function setFragmentUniformFromMatrix(name : String , matrix : Matrix3D,transposedMatrix : Bool = false) : Void{
        fragmentShader.setUniformFromMatrix(context3D,name,matrix, transposedMatrix);
    }

    // TODO set from vector and byte array

    //AGAL only allow texture for fragment shader
    // TODO add a function in cpp to set texture on vertex shader
    public function setTextureAt(name : String , texture : Texture){
        fragmentShader.setTextureAt(context3D,name,texture);
    }

    public function setVertexBufferAt(name : String, vertexBuffer : VertexBuffer3D, bufferOffset : Int, format : Context3DVertexBufferFormat) : Void{
        vertexShader.setVertexBufferAt(context3D,name,vertexBuffer,bufferOffset,format);
    }
}
