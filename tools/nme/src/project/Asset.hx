import haxe.io.Path;
import nme.display.BitmapData;
import nme.AlphaMode;
import sys.FileSystem;
import sys.io.File;


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
   public var alphaMode:AlphaMode;
   public var type:AssetType;
   public var isSound:Bool;
   public var isMusic:Bool;
   public var isImage:Bool;
   public var isLibrary:Bool;
   public var conversion:String;

   public function new(path:String = "", rename:String = "", inType:AssetType, inEmbed:Bool, ?inAlphaMode:AlphaMode) 
   {
      embed = inEmbed;
      isResource = embed;
      sourcePath = path;
      alphaMode = inAlphaMode==null ? AlphaDefault : inAlphaMode;

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

            case "swf":
               type = AssetType.SWF;

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
      isLibrary = type==SWF;
   }

   public function preprocess(convertDir:String)
   {
      if (type==IMAGE && format=="png")
      {
         if (alphaMode==AlphaPreprocess)
         {
            PathHelper.mkdir(convertDir);
            //var file = sys.io.File.getBytes(sourcePath);
            var convertName = convertDir + "/" + haxe.crypto.Md5.make( haxe.io.Bytes.ofString(sourcePath) ).toHex() + "_prem.png";
            if (FileHelper.isNewer(sourcePath, convertName))
            {
               Log.verbose('Premultiplying $sourcePath to $convertName');
               var bmp = BitmapData.load(sourcePath);
               bmp.premultipliedAlpha = true;
               bmp.setFormat( nme.image.PixelFormat.pfBGRA, false );
               var bytes = bmp.encode( BitmapData.PNG, 1);
               sys.io.File.saveBytes(convertName, bytes );
            }

            conversion = "prem";
            sourcePath = convertName;
            alphaMode = AlphaIsPremultiplied;
         }
      }
   }

   public function cleanConversion(dir:String, file:String)
   {
      if (!FileSystem.exists(dir))
         return;

      var dataFile = dir + "/" + haxe.crypto.Md5.make( haxe.io.Bytes.ofString(file) ).toHex() + ".dat";
      if (!FileSystem.exists(dataFile))
      {
         if (conversion!=null)
            File.saveContent(dataFile,conversion);
         return;
      }
      var oldConvert = File.getContent(dataFile);
      if (oldConvert!=conversion)
      {
         Log.verbose("Remove old conversion " + file);
         FileSystem.deleteFile(dataFile);
         FileSystem.deleteFile(file);
         if (conversion!=null)
            File.saveContent(dataFile,conversion);
      }
   }

   public function setId(inId:String)
   {
      if (inId!="" && inId!=null)
      {
         id = inId;
         flatName = StringHelper.getFlatName(id);
      }
   }
}
