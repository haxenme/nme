package;

import haxe.io.Path;

class Asset 
{
   public var data:Dynamic;
   public var embed:Bool;
   public var isResource:Bool;
   public var flatName:String;
   public var format:String;
   public var glyphs:String;
   public var id:String;
   //public var path:String;
   //public var rename:String;
   public var resourceName:String;
   public var sourcePath:String;
   public var targetPath:String;
   public var flashClass:String;
   public var className:String;
   public var type:AssetType;
   public var isSound:Bool;
   public var isMusic:Bool;
   public var isImage:Bool;

   public function new(path:String = "", rename:String = "", inType:AssetType, inEmbed:Bool) 
   {
      embed = inEmbed;
      isResource = embed;
      sourcePath = path;

      if (rename == "") 
         targetPath = path;
      else
         targetPath = rename;

      id = targetPath;
      resourceName = targetPath;
      flatName = StringHelper.getFlatName(targetPath);
      format = Path.extension(path).toLowerCase();
      glyphs = "32-255";

      if (inType == null) 
      {
         var extension = Path.extension(path);

         switch(extension.toLowerCase()) 
         {
            case "jpg", "jpeg", "png", "gif":
               type = AssetType.IMAGE;

            case "otf", "ttf":
               type = AssetType.FONT;

            case "wav", "ogg":
               type = AssetType.SOUND;

            case "mp3", "mp2", "mid":
               type = AssetType.MUSIC;

            case "text", "txt", "json", "xml", "svg", "css":
               type = AssetType.TEXT;

            default:
               if (path != "" && FileHelper.isText(path)) 
                  type = AssetType.TEXT;
               else
                  type = AssetType.BINARY;
         }
      }
      else
      {
         type = inType;
      }

      isSound = type==SOUND;
      isMusic = type==MUSIC;
      isImage = type==IMAGE;
   }
}
