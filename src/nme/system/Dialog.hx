package nme.system;

import nme.PrimeLoader;

class Dialog
{
   public static function fileOpen(title:String, text:String, defaultPath:String="", filesSpec:String = "All Files|*.*", onResult:String->Void) : Bool
   {
      return nme_file_dialog_open(title, text, defaultPath, filesSpec, onResult);
   }

   static var nme_file_dialog_open = PrimeLoader.load("nme_file_dialog_open", "ssssob");
}

