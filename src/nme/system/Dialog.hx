package nme.system;

import nme.net.SharedObject;
import nme.PrimeLoader;

class Dialog
{
   public static function fileOpen(title:String, text:String, ?defaultPath:String, filesSpec:String = "All Files|*.*", onResult:String->Void,?rememberKey:String) : Bool
   {
      if (rememberKey!=null)
      {
         if (defaultPath==null)
         {
            var def = SharedObject.getLocal("fileOpen");
            if (def!=null)
               defaultPath = Reflect.field(def.data, rememberKey);
            if (defaultPath==null) defaultPath = "";
         }
         var captureResult = function(name:String) {
            if (name!=null && name!="")
            {
               var path = name;
               #if !js
               if (path!="" && !sys.FileSystem.isDirectory(path))
                  path = haxe.io.Path.directory(path);
               #end
               var def = SharedObject.getLocal("fileOpen");
               if (def!=null)
               {
                  def.setProperty(rememberKey, path);
                  def.flush();
               }
            }
            onResult(name);
         }
         return nme_file_dialog_open(title, text, defaultPath, filesSpec, captureResult);
      }

      return nme_file_dialog_open(title, text, defaultPath, filesSpec, onResult);
   }

   public static function getImage(title:String, text:String, ?defaultPath:String, onResult:String->Void,?rememberKey:String) : Bool
   {
      if (rememberKey==null)
         rememberKey = "imageDirectory";
      var imageFiles = "Image Files(*.jpg,*.png)|*.jpg;*.png|All Files(*.*)|*.*";
      return fileOpen(title, text, defaultPath, imageFiles, onResult, rememberKey);
   }

   static var nme_file_dialog_open = PrimeLoader.load("nme_file_dialog_open", "ssssob");
}

