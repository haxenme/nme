package furusystems.display.gl.materials;
import furusystems.display.gl.camera.Camera;
import furusystems.display.gl.materials.properties.uniforms.UniformF;
import furusystems.display.gl.materials.properties.uniforms.UniformM4;
import furusystems.display.gl.mesh.Mesh;
import nme.Assets;
import nme.geom.Matrix;
import nme.geom.Matrix3D;
import nme.gl.GL;
import nme.Lib;

/**
 * ...
 * @author Andreas Rønning
 */
class Material
{

	public var blendSource:Int = GL.SRC_ALPHA;
	public var blendDestination:Int = GL.ONE_MINUS_SRC_ALPHA;
	public var shader:GLSLShader = null;
	
	private var posLocation:Int;
	private var normLocation:Int;
	private var binormLocation:Int;
	private var uvLocation:Int;
	private var colorLocation:Int;
	
	public var renderMode:Int;
	
	public var name:String = "Material";
	public function new(name:String = "Material", vsPath:String = "shaders/Base.vs", fsPath:String = "shaders/Simple.fs") 
	{
		trace("New material: " + name);
		renderMode = GL.TRIANGLES;
		this.name = name;
		this.shader = new GLSLShader(Assets.getText(vsPath), Assets.getText(fsPath));
		posLocation = GL.getAttribLocation(shader.program, "aPosition");
		normLocation = GL.getAttribLocation(shader.program, "aNormal");
		binormLocation = GL.getAttribLocation(shader.program, "aBiNormal");
		uvLocation = GL.getAttribLocation(shader.program, "aUV");
		colorLocation = GL.getAttribLocation(shader.program, "aColor");
	}
	public function predraw(camera:Camera, world:Matrix3D, wvp:Matrix3D, time:Float):Void {
		GL.useProgram(shader.program);
		GL.blendFunc(blendSource, blendDestination);
		shader.setUniform("uWorld", world);
		shader.setUniform("uView", camera.view);
		shader.setUniform("uProjection", camera.projection);
		shader.setUniform("uViewProjection", camera.camProj);
		shader.setUniform("uWorldViewProjection", wvp);
		
		shader.setUniform("uTime", time);
		shader.setUniform("uCameraPos", camera.p);
		
		shader.updateUniforms();
		//cast(shader.getUniform("time"), UniformF).prop.value = Lib.getTimer() / 1000;
	}
	public function apply(mesh:Mesh):Void {
		GL.enableVertexAttribArray(posLocation);
		GL.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, Mesh.VERT_STRIDE, 0);
		
		if (normLocation > -1) { 
			GL.enableVertexAttribArray(normLocation);
			GL.vertexAttribPointer(normLocation, 3, GL.FLOAT, false, Mesh.VERT_STRIDE, 12);
		}
		
		if (binormLocation > -1) { 
			GL.enableVertexAttribArray(binormLocation);
			GL.vertexAttribPointer(binormLocation, 3, GL.FLOAT, false, Mesh.VERT_STRIDE, 24);
		}
		
		if (uvLocation > -1) { 
			GL.enableVertexAttribArray(uvLocation);
			GL.vertexAttribPointer(uvLocation, 2, GL.FLOAT, false, Mesh.VERT_STRIDE, 36);
		}
		
		if (colorLocation > -1) { 
			GL.enableVertexAttribArray(colorLocation);
			GL.vertexAttribPointer(colorLocation, 4, GL.FLOAT, false, Mesh.VERT_STRIDE, 44);
		}
		
	}
	public function postdraw():Void {
		if (posLocation > -1) GL.disableVertexAttribArray(posLocation);
		if (normLocation > -1) GL.disableVertexAttribArray(normLocation);
		if (uvLocation > -1) GL.disableVertexAttribArray(uvLocation);
		if (colorLocation > -1) GL.disableVertexAttribArray(colorLocation);
		if (binormLocation > -1) GL.disableVertexAttribArray(binormLocation);
		GL.useProgram(null);
		
	}
	public function dispose():Void {
		postdraw();
		GL.deleteProgram(shader.program);
	}
	
}