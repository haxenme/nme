package;

import neko.Lib;
#if nme
import nme.Loader;
#end
import NMEProject;

class LogHelper 
{
   public static var mute:Bool;
   public static var mVerbose:Bool = false;
   private static var sentWarnings = new Map<String,Bool>();

   public static function error(message:String, verboseMessage:String = "", e:Dynamic = null):Void 
   {
      #if nme
      if (message != "") 
      {
         var log = nme_error_output==null ? Sys.print : nme_error_output;
         try 
         {
            if (mVerbose && verboseMessage != "") 
            {
               log("Error: " + verboseMessage + "\n");
            }
            else
            {
               log("Error: " + message + "\n");
            }

         } catch(e:Dynamic) { }
      }
      #end

      if (mVerbose && e != null) 
      {
         Lib.rethrow(e);
      }

      Sys.exit(1);
   }

   public static function verbose(message:String):Void 
   {
      if (!mute && mVerbose)
         Sys.println(message);
   }

   public static function info(message:String, verboseMessage:String = ""):Void 
   {
      if (mute)
         return;

      if (mVerbose && verboseMessage != "") 
         Sys.println(verboseMessage);
      else if (message != "") 
         Sys.println(message);
   }

   public static function warn(message:String, verboseMessage:String = "", allowRepeat:Bool = false):Void 
   {
      if (mute)
         return;

      var output = "";

      if (mVerbose && verboseMessage != "") 
      {
         output = "Warning: " + verboseMessage;

      } else if (message != "") 
      {
         output = "Warning: " + message;
      }

      if (!allowRepeat && sentWarnings.exists(output)) 
      {
         return;
      }

      sentWarnings.set(output, true);
      Sys.println(output);
   }

   #if nme
   private static var nme_error_output = Loader.load("nme_error_output", 1);
   #end
}
