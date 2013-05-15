package;

import nme.events.Event;
import nme.events.ErrorEvent;
import nme.display.Sprite;

import nme.display3D.IndexBuffer3D;
import nme.display3D.shaders.glsl.GLSLFragmentShader;
import nme.display3D.shaders.glsl.GLSLVertexShader;
import nme.display3D.shaders.glsl.GLSLProgram;
import nme.display3D.VertexBuffer3D;

using nme.geom.Matrix3D;

using nme.Vector;
using nme.display3D.Context3DUtils;

class Main extends Sprite {


    var stage3D : nme.display.Stage3D;
    var context3D : flash.display3D.Context3D;

    var vertexBuffer : VertexBuffer3D;
    var indexBuffer : IndexBuffer3D;
    var glslProgram : GLSLProgram;

	public function new () {

		super ();

        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

	}

    function onAddedToStage(event : Event) : Void{
        stage3D = stage.stage3Ds[0];
        stage3D.addEventListener( Event.CONTEXT3D_CREATE, onReady );
        stage3D.addEventListener( ErrorEvent.ERROR, onError );
        stage3D.requestContext3D();
    }

    function onError(event : ErrorEvent) : Void{
        trace(event);
    }


    function onReady( _ ) {
        context3D = stage3D.context3D;
        context3D.configureBackBuffer( stage.stageWidth, stage.stageHeight, 0, false);
        context3D.enableErrorChecking = true;

        createProgram ();

        var vertices : Array<Float> = [

        100, 100, 0,
        -100, 100, 0,
        100, -100, 0,
        -100, -100, 0

        ];


        //TODO deal with this in some way ? (note : can use ByteArray instead)
        var indices : Array<#if flash UInt #else Int #end> = [0,1,2,2,3,1];

        vertexBuffer = context3D.createVertexBuffer(4,3);
        vertexBuffer.uploadFromVector(#if flash Vector.ofArray(vertices) #else vertices #end, 0, 4);

        indexBuffer = context3D.createIndexBuffer(6);
        indexBuffer.uploadFromVector(#if flash Vector.ofArray(indices) #else indices #end, 0, 6);

        context3D.setRenderCallback(update);
    }

    private function createProgram ():Void {

        glslProgram = new GLSLProgram(context3D);

        var vertexShaderSource =

        "attribute vec3 vertexPosition;

        uniform mat4 mvpMatrix;

        void main(void) {
            gl_Position = mvpMatrix * vec4(vertexPosition, 1.0);
        }";

        var vertexShader = new GLSLVertexShader(vertexShaderSource);



        var fragmentShaderSource =

        "void main(void) {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
        }";

        var fragmentShader = new GLSLFragmentShader(fragmentShaderSource);

        glslProgram.upload(vertexShader, fragmentShader);

    }


    function update() {

        var positionX = stage.stageWidth / 2;
        var positionY = stage.stageHeight / 2;

        var projectionMatrix = createOrtho (0, stage.stageWidth, stage.stageHeight, 0, 1000, -1000);
        var modelViewMatrix = create2D (positionX, positionY, 1, 0);

        var mvpMatrix = modelViewMatrix.clone();
        mvpMatrix.append(projectionMatrix);

        glslProgram.attach();
        glslProgram.setVertexUniformFromMatrix("mvpMatrix",mvpMatrix, true);
        glslProgram.setVertexBufferAt("vertexPosition",vertexBuffer, 0, nme.display3D.Context3DVertexBufferFormat.FLOAT_3);


        context3D.clear(0, 0, 0, 1.0);
        context3D.drawTriangles(indexBuffer);
        context3D.present();

    }


    public static function create2D(x:Float, y:Float, scale:Float = 1, rotation:Float = 0) : Matrix3D{
        #if (cpp || neko || js)
            return Matrix3D.create2D(x,y,scale,rotation);
        #else


        var theta = rotation * Math.PI / 180.0;
        var c = Math.cos(theta);
        var s = Math.sin(theta);

        return new Matrix3D(Vector.ofArray([
            c*scale,  -s*scale, 0,  0,
            s*scale,  c*scale, 0,  0,
            0,        0,        1,  0,
            x,        y,        0,  1
        ]));

        #end

    }



    public static function createOrtho(x0:Float, x1:Float,  y0:Float, y1:Float, zNear:Float, zFar:Float) : Matrix3D {
        #if (cpp || neko || js)
            return Matrix3D.createOrtho(x0,x1,y0,y1,zNear,zFar);
        #else
        var sx = 1.0 / (x1 - x0);
        var sy = 1.0 / (y1 - y0);
        var sz = 1.0 / (zFar - zNear);

        return new Matrix3D(Vector.ofArray([
            2.0*sx,       0,          0,                 0,
            0,            2.0*sy,     0,                 0,
            0,            0,          -2.0*sz,           0,
            - (x0+x1)*sx, - (y0+y1)*sy, - (zNear+zFar)*sz,  1,
        ]));
        #end

    }


}