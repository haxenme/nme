import nme.display.OpenGLView;
import nme.display.Sprite;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.gl.GL;
import nme.gl.GLBuffer;
import nme.gl.GLProgram;
import nme.gl.GLShader;
import nme.utils.Float32Array;
import nme.Lib;
import shaders.FragmentShader_4278_1;
import shaders.FragmentShader_5359_8;
import shaders.FragmentShader_5398_8;
import shaders.FragmentShader_5454_21;
import shaders.FragmentShader_5492;
import shaders.FragmentShader_5733;
import shaders.FragmentShader_5805_18;
import shaders.FragmentShader_5812;
import shaders.FragmentShader_5891_5;
import shaders.FragmentShader_6022;
import shaders.FragmentShader_6043_1;
import shaders.FragmentShader_6049;
import shaders.FragmentShader_6147_1;
import shaders.FragmentShader_6162;
import shaders.FragmentShader_6175;
import shaders.FragmentShader_6223_2;
import shaders.FragmentShader_6238;
import shaders.FragmentShader_6284_1;
import shaders.FragmentShader_6286;
import shaders.FragmentShader_6288_1;
import shaders.VertexShader;


class Main extends Sprite {
	
	
	#if !mobile
	private static var fragmentShaders:Array<Dynamic> = [ FragmentShader_6286, FragmentShader_6288_1, FragmentShader_6284_1, FragmentShader_6238, FragmentShader_6223_2, FragmentShader_6175, FragmentShader_6162, FragmentShader_6147_1, FragmentShader_6049, FragmentShader_6043_1, FragmentShader_6022, FragmentShader_5891_5, FragmentShader_5805_18, FragmentShader_5812, FragmentShader_5733, FragmentShader_5454_21, FragmentShader_5492, FragmentShader_5359_8, FragmentShader_5398_8, FragmentShader_4278_1 ];
	#else
	private static var fragmentShaders:Array<Dynamic> = [ FragmentShader_6284_1, FragmentShader_6238, FragmentShader_6147_1, FragmentShader_5891_5, FragmentShader_5805_18, FragmentShader_5492, FragmentShader_5398_8 ];
	#end
	
	private static var maxTime = 7000;
	
	private var buffer:GLBuffer;
	private var currentIndex:Int;
	private var currentProgram:GLProgram;
	private var positionAttribute:Dynamic;
	private var timeUniform:Dynamic;
	private var mouseUniform:Dynamic;
	private var resolutionUniform:Dynamic;
	private var backbufferUniform:Dynamic;
	private var surfaceSizeUniform:Dynamic;
	private var startTime:Dynamic;
	private var vertexPosition:Dynamic;
	private var view:OpenGLView;
	
	
	public function new () {
		
		super ();
		
		if (OpenGLView.isSupported) {
			
			view = new OpenGLView ();
			
			fragmentShaders = randomizeArray (fragmentShaders);
			currentIndex = 0;
			
			buffer = GL.createBuffer ();
			GL.bindBuffer (GL.ARRAY_BUFFER, buffer);
			GL.bufferData (GL.ARRAY_BUFFER, new Float32Array ([ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]), GL.STATIC_DRAW);
			
			compile ();
			
			view.render = renderView;
			addChild (view);
			
		}
		
	}
	
	
	private function compile ():Void {
		
		var program = GL.createProgram ();
		var vertex = VertexShader.source;
		
		#if desktop
		var fragment = "";
		#else
		var fragment = "precision mediump float;";
		#end
		
		fragment += fragmentShaders[currentIndex].source;
		
		var vs = createShader (vertex, GL.VERTEX_SHADER);
		var fs = createShader (fragment, GL.FRAGMENT_SHADER);
		
		if (vs == null || fs == null) return;
		
		GL.attachShader (program, vs);
		GL.attachShader (program, fs);
		
		GL.deleteShader (vs);
		GL.deleteShader (fs);
		
		GL.linkProgram (program);
		
		if (GL.getProgramParameter (program, GL.LINK_STATUS) == 0) {
			
			trace (GL.getProgramInfoLog (program));
			trace ("VALIDATE_STATUS: " + GL.getProgramParameter (program, GL.VALIDATE_STATUS));
			trace ("ERROR: " + GL.getError ());
			return;
			
		}
		
		if (currentProgram != null) {
			
			GL.deleteProgram (currentProgram);
			
		}
		
		currentProgram = program;
		GL.useProgram (currentProgram);
		
		positionAttribute = GL.getAttribLocation (currentProgram, "surfacePosAttrib");
		GL.enableVertexAttribArray (positionAttribute);
		
		vertexPosition = GL.getAttribLocation (currentProgram, "position");
		GL.enableVertexAttribArray (vertexPosition);
		
		timeUniform = GL.getUniformLocation (program, "time");
		mouseUniform = GL.getUniformLocation (program, "mouse");
		resolutionUniform = GL.getUniformLocation (program, "resolution");
		backbufferUniform = GL.getUniformLocation (program, "backbuffer");
		surfaceSizeUniform = GL.getUniformLocation (program, "surfaceSize");
		
		startTime = Lib.getTimer ();
		
	}
	
	
	private function createShader (source:String, type:Int):GLShader {
		
		var shader = GL.createShader (type);
		GL.shaderSource (shader, source);
		GL.compileShader (shader);
		
		if (GL.getShaderParameter (shader, GL.COMPILE_STATUS) == 0) {
			
			trace (GL.getShaderInfoLog (shader));
			return null;
			
		}
		
		return shader;
		
	}
	
	
	private function randomizeArray<T> (array:Array<T>):Array<T> {
		
		var arrayCopy = array.copy ();
		var randomArray = new Array<T> ();
		
		while (arrayCopy.length > 0) {
			
			var randomIndex = Math.round (Math.random () * (arrayCopy.length - 1));
			randomArray.push (arrayCopy.splice (randomIndex, 1)[0]);
			
		}
		
		return randomArray;
		
	}
	
	
	private function renderView (rect:Rectangle):Void {
		
		GL.viewport (Std.int (rect.x), Std.int (rect.y), Std.int (rect.width), Std.int (rect.height));
		
		if (currentProgram == null) return;
		
		var time = Lib.getTimer () - startTime;
		
		GL.useProgram (currentProgram);
		
		GL.uniform1f (timeUniform, time / 1000);
		//GL.uniform2f (mouseUniform, (Lib.current.stage.mouseX / Lib.current.stage.stageWidth) * 2 - 1, (Lib.current.stage.mouseY / Lib.current.stage.stageHeight) * 2 - 1);
		GL.uniform2f (mouseUniform, 0.1, 0.1);
		GL.uniform2f (resolutionUniform, rect.width, rect.height);
		GL.uniform1i (backbufferUniform, 0 );
		GL.uniform2f (surfaceSizeUniform, rect.width, rect.height);
		
		GL.bindBuffer (GL.ARRAY_BUFFER, buffer);
		GL.vertexAttribPointer (positionAttribute, 2, GL.FLOAT, false, 0, 0);
		GL.vertexAttribPointer (vertexPosition, 2, GL.FLOAT, false, 0, 0);
		
		GL.clearColor (0, 0, 0, 1);
		GL.clear (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT );
		GL.drawArrays (GL.TRIANGLES, 0, 6);
		
		if (time > maxTime && fragmentShaders.length > 1) {
			
			currentIndex++;
			
			if (currentIndex > fragmentShaders.length - 1) {
				
				currentIndex = 0;
				
			}
			
			compile ();
			
		}
		
	}
	
	
}