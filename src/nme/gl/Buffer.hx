package nme.gl;

import nme.utils.Float32Array;

@:nativeProperty
class Buffer
{
   var buffer:GLBuffer;
   var slot:Int;
   var dims:Int;

   function new(inProgram:GLProgram, inName:String, inDims:Int, inValues:Float32Array)
   {
      buffer = GL.createBuffer();
      slot =  GL.getAttribLocation(inProgram, inName);
      dims = inDims;
      GL.bindBuffer(GL.ARRAY_BUFFER, buffer);
      GL.bufferData(GL.ARRAY_BUFFER, inValues, GL.STATIC_DRAW);
      GL.bindBuffer(GL.ARRAY_BUFFER, null);
   }

   public function bind()
   {
      GL.bindBuffer(GL.ARRAY_BUFFER, buffer);
      GL.vertexAttribPointer(slot, dims, GL.FLOAT, false, 0, 0);
      GL.enableVertexAttribArray(slot);
   }

   public function unbind()
   {
      GL.disableVertexAttribArray(slot);
   }

   public static function fromArray(inProgram:GLProgram, inName:String, inComponents:Int, inValues:Array<Float>)
   {
       return new Buffer(inProgram, inName, inComponents, new Float32Array(inValues) );
   }
}

