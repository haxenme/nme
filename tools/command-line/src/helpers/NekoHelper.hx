package;

import sys.io.File;

class NekoHelper 
{
   static var exe:String = null;
   public static function getNekoExe()
   {
      if (exe==null)
         exe = nme.system.System.exeName;
      return exe;
   }

   public static function getNekoDir()
   {
      var neko = nme.system.System.exeName;
      return haxe.io.Path.directory(neko);
   }
   

   public static function createExecutable(source:String, target:String):Void 
   {
      var executablePath = getNekoExe();
      var executable = File.getBytes(executablePath);
      var sourceContents = File.getBytes(source);

      var output = File.write(target, true);
      output.write(executable);
      output.write(sourceContents);
      output.writeString("NEKO");
      output.writeInt32(executable.length);
      output.close();
   }
}
