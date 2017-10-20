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
            inVertexSource = HEADER(GL.VERTEX_SHADER) + inVertexSource;

         if( !StringTools.startsWith(inFragmentSource,"#v") )
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
      initGLVersion();
      return _isGLES;
   };

   public static function isWebGL():Bool 
   {
      initGLVersion();
      return _isWebGL;
   };

   //is GLES3, WebGL2, or OpenGL 3.3+
   public static function isGLES3compat():Bool
   {
      initGLVersion();
      return _isGLES3compat;
   };

   //Gets version as float and inits isGLES, isGLES3compat
   public static function GLVersion():Float
   {
      initGLVersion();
      return _glVersion;
   }

   //Inits glVersion, isGLES, isGLES3compat, isWebGL
   public static function initGLVersion()
   {
      if(!_glVersionInit)
      {
         version = StringTools.ltrim(GL.getParameter(GL.VERSION));
         if(version.indexOf("OpenGL ES") >= 0)
         { 
            _isGLES = true;
            _glVersion = Std.parseFloat(version.split(" ")[2]);
            _isGLES3compat = (_glVersion>=3.0);
         }
         else if(version.indexOf("WebGL") >= 0)
         { 
            _isGLES = true; //a kind of GLES
            _isWebGL = true;
            _glVersion = Std.parseFloat(version.split(" ")[1]);
            _isGLES3compat = (_glVersion>=2.0);
         }
         else
         {
            _glVersion = Std.parseFloat(version.split(" ")[0]);
            _isGLES3compat = (_glVersion >= 3.3);
         }
         _glVersionInit = true;
         //trace("version: "+_glVersion+" is GLES: "+(_isGLES?"true":"false")+", is GLES3 compatible:"+(_isGLES3compat?"true":"false"));
     }
   }

   //Helper functions for writting gles3 shaders with gles2 fallback
   //1) In VS: attribute -> IN(n)
   //2) In VS: varying -> OUT()
   //3) In FS: varyng -> IN()
   //4) In FS: OUT_COLOR("color"): define the name output instead of gl_FragColor
   //5) In FS: texture2D(x) -> TEXTURE(x)
   //6) HEADER is included automatically in "createProgram" unless inAutoHeader is set to false

   public static function IN(slot:Int = -1):String
   {
      return slot < 0 ? IN_FS() : IN_VS(slot);
   }

   public static function IN_FS():String
   {
      return isGLES3compat()? "\nin " : "\nvarying ";
   }

   public static function IN_VS(slot:Int):String 
   {
      return isGLES3compat()? 
         "\nlayout(location = " + slot + ") in " : 
         "\nattribute ";
   }

   public static function OUT():String
   {
      return isGLES3compat()? "\nout " : "\nvarying ";
   }

   public static function OUT_COLOR(fragColor:String):String
   {
      return isGLES3compat()? 
         "\nout vec4 "+fragColor+";\n" : 
         "\n#define "+fragColor+" gl_FragColor\n";
   }

   public static function TEXTURE( arg:String=null ):String
   {
      if(arg==null)
         return isGLES3compat()? " texture" : " texture2D";
      else
         return isGLES3compat()? 
            " texture(" + arg + ")" : 
            " texture2D(" + arg + ")";
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

   private static var _isGLES:Bool;
   private static var _isWebGL:Bool;
   private static var _isGLES3compat:Bool;
   private static var _glVersion:Float;
   private static var _glVersionInit:Bool;
}

