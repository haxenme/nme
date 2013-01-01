package native.display3D;


import nme.gl.GL;


class Program3D {
	
	
	public var glProgram:Program;
	
	
    public function new (program:Program) {
		
        this.glProgram = program;
		
    }
	
	
	public function dispose ():Void {
		
		// TODO
		
	}
	
	
	// TODO: Use ByteArray instead of Shader?
	
    public function upload (vertexShader:Shader, fragmentShader:Shader):Void {
		
        GL.attachShader (glProgram, vertexShader);
		GL.attachShader (glProgram, fragmentShader);
		GL.linkProgram (glProgram);
		
		if (GL.getProgramParameter (glProgram, GL.LINK_STATUS) == 0) {
			
			var result = GL.getProgramInfoLog (glProgram);
			if (result != "") throw result;
			
		}
		
    }
	
	
}