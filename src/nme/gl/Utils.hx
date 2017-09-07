package nme.gl;


class Utils
{
   public static function createShader(source:String, type:Int)
   {
      var shader = GL.createShader(type);
      GL.shaderSource(shader, source);
      GL.compileShader(shader);
      if (GL.getShaderParameter(shader, GL.COMPILE_STATUS)==0)
      {
         trace("--- ERR ---\n" + source);
         var err = GL.getShaderInfoLog(shader);
         if (err!="")
            throw err;
      }
      return shader;
   }

   public static function createProgram(inVertexSource:String, inFragmentSource:String, inAutoHeader:Bool = true)
   {
      var program = GL.createProgram();
      if(inAutoHeader)
      {
         inVertexSource = HEADER(GL.VERTEX_SHADER) + inVertexSource;
         inFragmentSource = HEADER(GL.FRAGMENT_SHADER) + inFragmentSource;
      }
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

   public static function isGLES():Bool 
   {
      if(!_glVersionInit)
         GLVersion();

      return _isGLES;
   };

   //is GLES3 or OpenGL 3.3
   public static function isGLES3compat():Bool
   {
      if(!_glVersionInit)
         GLVersion();

      return _isGLES3compat;
   };

   //Gets version as float and inits isGLES, isGLES3compat
   public static function GLVersion():Float
   {
      if(!_glVersionInit)
      {
         var version = GL.getParameter(GL.VERSION);
         //trace("shading language: "+version);

         version = StringTools.ltrim(version);
         if(version.indexOf("OpenGL ES")>=0)
         { 
            _isGLES = true;
            _glVersion = Std.parseFloat(version.split(" ")[2]);
            _isGLES3compat = (_glVersion>=3.0);
         }
         else
         {
            _isGLES = false;
            _glVersion = Std.parseFloat(version.split(" ")[0]);
            _isGLES3compat = (_glVersion>=3.3);
         }
         _glVersionInit = true;
         //trace("version: "+_glVersion+" is GLES: "+(_isGLES?"true":"false")+", is GLES3 compatible:"+(_isGLES3compat?"true":"false"));
     }
     return _glVersion;
   }

   //Helper functions for writting compatible gles3/gles2 shader sources
   //1) attribute -> IN(n)
   //2) varying -> OUT()
   //3) OUT_COLOR("color"): use it vertex shader to define the name output instead of gl_FragColor. 
   //4) HEADER is included automatically in "createProgram" unless inAutoHeader is set to false

   public static inline function IN(slot:Int):String
   {
     return isGLES3compat()? 
            "layout(location = "+slot+") in" : 
            "attribute";
   }

   public static inline function OUT():String
   {
    return isGLES3compat()? 
         "out" : 
         "varying";
   }

   public static inline function OUT_COLOR(fragColor:String):String
   {
     return isGLES3compat()? 
         "out vec4 "+fragColor+";" : 
         "#define "+fragColor+" gl_FragColor";
   }

   private static inline function HEADER(type:Int):String
   {
      return isGLES3compat()? 
      (
         _isGLES?
         "#version 300 es\nprecision mediump float; \n" : 
         "#version 330 core\n"
      )
      :
      (
         _isGLES?
         "#version 100\nprecision mediump float; \n" : 
         "#version 110\n"
      );
   }

   public static var _isGLES:Bool;
   public static var _isGLES3compat:Bool;
   public static var _glVersion:Float;
   public static var _glVersionInit:Bool;
}

