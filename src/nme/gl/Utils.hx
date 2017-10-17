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
         if( !StringTools.startsWith(inVertexSource,"#v") )
         {
            inVertexSource = HEADER(GL.VERTEX_SHADER) + inVertexSource;
         }
         if( !StringTools.startsWith(inFragmentSource,"#v") )
         {
            inFragmentSource = HEADER(GL.FRAGMENT_SHADER) + inFragmentSource;
         }
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

   public static function isWebGL():Bool 
   {
      if(!_glVersionInit)
         GLVersion();

      return _isWebGL;
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
            _isWebGL = false;
            _glVersion = Std.parseFloat(version.split(" ")[2]);
            _isGLES3compat = (_glVersion>=3.0);
         }
         else if(version.indexOf("WebGL")>=0)
         { 
            _isGLES = true; //a kind of GLES
            _isWebGL = true;
            _glVersion = Std.parseFloat(version.split(" ")[1]);
            _isGLES3compat = (_glVersion>=2.0);
         }
         else
         {
            _isGLES = false;
            _isWebGL = false;
            _glVersion = Std.parseFloat(version.split(" ")[0]);
            _isGLES3compat = (_glVersion>=3.3);
         }
         _glVersionInit = true;
         //trace("version: "+_glVersion+" is GLES: "+(_isGLES?"true":"false")+", is GLES3 compatible:"+(_isGLES3compat?"true":"false"));
     }
     return _glVersion;
   }

   //Helper functions for writting compatible gles3/gles2 shader sources
   //1) In VS: attribute -> IN(n)
   //2) In VS: varying -> OUT()
   //2a) In FS: varyng -> IN()
   //3) In FS: OUT_COLOR("color"): define the name output instead of gl_FragColor
   //5) HEADER is included automatically in "createProgram" unless inAutoHeader is set to false

   public static inline function IN(slot:Int = -1):String
   {
     return slot < 0 ? IN_FS() : IN_VS(slot);
   }

   public static inline function IN_FS():String
   {
     return isGLES3compat()? 
            "\nin " : 
            "\nvarying ";
   }

   public static inline function IN_VS(slot:Int):String 
   {
     return isGLES3compat()? 
            "\nlayout(location = " + slot + ") in " : 
            "\nattribute ";
   }

   public static inline function OUT():String
   {
    return isGLES3compat()? 
         "\nout" : 
         "\nvarying";
   }

   public static inline function OUT_COLOR(fragColor:String):String
   {
     return isGLES3compat()? 
         "\nout vec4 "+fragColor+";\n" : 
         "\n#define "+fragColor+" gl_FragColor\n";
   }

   public static inline function TEXTURE():String
   {
    return isGLES3compat()? 
         " texture" : 
         " texture2D";
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
   public static var _isWebGL:Bool;
   public static var _isGLES3compat:Bool;
   public static var _glVersion:Float;
   public static var _glVersionInit:Bool;
}

