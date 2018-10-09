package nme.system;

import nme.net.SharedObject;
import nme.PrimeLoader;

class Dialog
{
   inline static public var Save            = 0x0001;
   inline static public var PromptOverwrite = 0x0002;
   inline static public var MustExist       = 0x0004;
   inline static public var Directory       = 0x0008;
   inline static public var MultiSelect     = 0x0010;
   inline static public var HideReadOnly    = 0x0020;


   public static function fileDialog(title:String, text:String, ?defaultPath:String, filesSpec:String = "All Files|*.*", onResult:String->Void,?rememberKey:String, inFlags:Int) : Bool
   {
      var resultCallback = onResult;
      if (rememberKey!=null)
      {
         if (defaultPath==null)
         {
            var def = SharedObject.getLocal("fileOpen");
            if (def!=null)
               defaultPath = Reflect.field(def.data, rememberKey);
            if (defaultPath==null) defaultPath = "";
         }
         resultCallback = function(name:String) {
            if (name!=null && name!="")
            {
               var path = name;
               if ((inFlags&MultiSelect)!=0)
               {
                  var nullTerm = path.indexOf( String.fromCharCode(0) );
                  if (nullTerm>=0)
                     path = path.substr(0,nullTerm);
               }
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
      }

      return nme_file_dialog_open(title, text, defaultPath, filesSpec, resultCallback, inFlags);
   }


   public static function fileOpen(title:String, text:String, ?defaultPath:String, filesSpec:String = "All Files|*.*", onResult:String->Void,?rememberKey:String, inFlags=MustExist) : Bool
   {
      return fileDialog(title, text, defaultPath, filesSpec, onResult, rememberKey, inFlags);
   }

   public static function fileSave(title:String, text:String, ?defaultPath:String, filesSpec:String = "All Files|*.*", onResult:String->Void,?rememberKey:String, inFlags=PromptOverwrite|HideReadOnly) : Bool
   {
      var flags = Save | inFlags;

      return fileDialog(title, text, defaultPath, filesSpec, onResult, rememberKey, flags);
   }


   public static function getImage(title:String, text:String, ?defaultPath:String, onResult:String->Void,?rememberKey:String) : Bool
   {
      if (rememberKey==null)
         rememberKey = "imageDirectory";
      var imageFiles = "Image Files(*.jpg,*.png)|*.jpg;*.png|All Files(*.*)|*.*";
      var flags = MustExist;
      return fileDialog(title, text, defaultPath, imageFiles, onResult, rememberKey, flags);
   }

   public static function getImages(title:String, text:String, ?defaultPath:String, onResult:Array<String>->Void,?rememberKey:String) : Bool
   {
      if (rememberKey==null)
         rememberKey = "imageDirectory";
      var imageFiles = "Image Files(*.jpg,*.png)|*.jpg;*.png|All Files(*.*)|*.*";
      var flags = MustExist;
      flags |= MultiSelect;

      var split = function(string:String) onResult( splitStringList(string) );

      return fileDialog(title, text, defaultPath, imageFiles, split, rememberKey, flags);
   }

   public static function splitStringList(s:String) : Array<String>
   {
      var result = new Array<String>();
      var term = String.fromCharCode(0);
      while(true)
      {
         var pos = s.indexOf(term);
         if (pos>=0)
         {
            result.push(s.substr(0,pos));
            s = s.substr(pos+1);
         }
         else
         {
            if (s.length>0)
               result.push(s);
            break;
         }
      }
      if (result.length>1)
      {
         var dir = result.shift();
         result = [ for(r in result) '$dir/$r' ];
      }
      return result;
   }



   public static function getDirectory(title:String, text:String, ?defaultPath:String, onResult:String->Void,?rememberKey:String) : Bool
   {
      if (rememberKey==null)
         rememberKey = "lastDirectory";
      var directoryMatch = "<directory>";
      return fileDialog(title, text, defaultPath, directoryMatch, onResult, rememberKey, Directory);
   }


   static var nme_file_dialog_open = PrimeLoader.load("nme_file_dialog_open", "ssssoib");
}

