package nme.gl;
import nme.geom.Matrix3D;
import nme.gl.GL;
import nme.Vector;

class GLUtils
{
	
	public static function createShader(source:String, type:Int):GLShader
	{
		var shader = GL.createShader(type);
		GL.shaderSource(shader, source);
		GL.compileShader(shader);
		if (GL.getShaderParameter(shader, GL.COMPILE_STATUS)==0)
		{
		 trace("\tERROR\n" + source);
		 var err = GL.getShaderInfoLog(shader);
		 if (err!="")
			throw err;
		}
		return shader;
	}
	public static function createProgram(inVertexSource:String, inFragmentSource:String):GLProgram
	{
		var program = GL.createProgram();
		var vshader = createShader(inVertexSource, GL.VERTEX_SHADER);
		var fshader = createShader(inFragmentSource, GL.FRAGMENT_SHADER);
		GL.attachShader(program, vshader);
		GL.attachShader(program, fshader);
		GL.linkProgram(program);
		if (GL.getProgramParameter(program, GL.LINK_STATUS)==0)
		{
		 var result = GL.getProgramInfoLog(program);
		 if (result!="")
			throw result;
		}
		return program;
	}
	
	public static function projection2D(w:Float, h:Float):Matrix3D 
	{
		var mvp = new Matrix3D();
		mvp.appendScale(1 / w * 2, -(1 / h) * 2, 1);
		mvp.appendTranslation( -1, 1, 0);
		return mvp;
	}
	
	public static function projectionPerspective(fov:Float, imageAspectRatio:Float, n:Float, f:Float, transpose:Bool = true):Matrix3D {
		var scale = Math.tan(degToRad(fov * 0.5)) * n;
		var r = imageAspectRatio * scale;
		var l = -r;
		var t = scale;
		var b = -t;
		if (transpose) {
			return frustumTransposed(l, r, b, t, n, f);
		}else {
			return frustum(l, r, b, t, n, f);
		}
	}
	
	private static function frustum(l:Float, r:Float, b:Float, t:Float, n:Float, f:Float):Matrix3D
	{
		var mat = new Vector<Float>();
		mat[0] = (2 * n) / (r - l);
		mat[1] = 0;
		mat[2] = (r + l) / (r - l);
		mat[3] = 0;
		
		mat[4] = 0;
		mat[5] = (2 * n) / (t - b);
		mat[6] = (t + b) / (t - b);
		mat[7] = 0;
		
		mat[8] = 0;
		mat[9] = 0;
		mat[10] = -((f + n) / (f - n));
		mat[11] = -((2 * f * n) / (f - n));
		
		mat[12] = 0;
		mat[13] = 0;
		mat[14] = -1;
		mat[15] = 0;
		
		return new Matrix3D(mat);
	}
	
	private static function frustumTransposed(l:Float, r:Float, b:Float, t:Float, n:Float, f:Float):Matrix3D {
		var mat = new Vector<Float>();
		mat[0] = (2 * n) / (r - l);
		mat[4] = 0;
		mat[8] = (r + l) / (r - l);
		mat[12] = 0;
		
		mat[1] = 0;
		mat[5] = (2 * n) / (t - b);
		mat[9] = (t + b) / (t - b);
		mat[13] = 0;
		
		mat[2] = 0;
		mat[6] = 0;
		mat[10] = -((f + n) / (f - n));
		mat[14] = -((2 * f * n) / (f - n));
		
		mat[3] = 0;
		mat[7] = 0;
		mat[11] = -1;
		mat[15] = 0;
		
		return new Matrix3D(mat);
	}
	
	//TODO: Move these somewhere convenient?
	public static inline function degToRad(deg:Float):Float {
		return deg * (Math.PI / 180);
	}
	
	public static inline function radToDeg(rad:Float):Float {
		return rad * (180 / Math.PI);
	}
}