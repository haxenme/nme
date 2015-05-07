package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class DesktopPlatform extends Platform
{
   public function new(inProject:NMEProject)
   {
      super(inProject);

      if (useNeko)
         project.haxeflags.push('-neko $haxeDir/ApplicationMain.n');
     else
         project.haxeflags.push('-cpp $haxeDir/cpp');

     project.haxedefs.set(is64 ? "HXCPP_M64" : "HXCPP_M32",null);
   }
}
