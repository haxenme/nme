package data;


import haxe.io.Path;


class Asset {
	
	
	public static var TYPE_BINARY:String = "binary";
	public static var TYPE_FONT:String = "font";
	public static var TYPE_IMAGE:String = "image";
	public static var TYPE_MUSIC:String = "music";
	public static var TYPE_SOUND:String = "sound";
	public static var TYPE_TEXT:String = "text";
	
	public static var TYPE_TEMPLATE:String = "template";
	
	public var embed:Bool;
	public var hash:String;
	public var id:String;
	public var resourceName:String;
	public var sourcePath:String;
	public var targetPath:String;
	public var type:String;
	public var flatName:String;
	public var flashClass:String;
	
	
	public function new (sourcePath:String, targetPath:String, type:String, id:String, embed:String) {
		
		this.sourcePath = sourcePath;
		this.targetPath = targetPath;
		
		if (this.targetPath == "") {
			
			this.targetPath = sourcePath;
			
		}
		
		this.type = type;
		this.id = id;
		
		if (this.id == "") {
			
			this.id = this.targetPath;
			
		}
		
		this.resourceName = this.targetPath;
		
		if (this.type == "asset") {
			
			this.type = "";
			
		}
		
		if (this.type == "") {
			
			var extension:String = Path.extension (this.targetPath);
			
			switch (extension.toLowerCase ()) {
				
				case "jpg", "jpeg", "png", "gif":
					
					this.type = TYPE_IMAGE;
				
				case "otf", "ttf":
					
					this.type = TYPE_FONT;
				
				case "wav", "ogg":
					
					this.type = TYPE_SOUND;
				
				case "mp3", "mp2":
					
					this.type = TYPE_MUSIC;
				
				case "text", "txt", "json", "xml", "svg":
					
					this.type = TYPE_TEXT;
				
				default:
					
					this.type = TYPE_BINARY;
				
			}
			
		}
		
		if (embed == "" || embed == "1" || embed == "true") {
			
			this.embed = true;
			
		} else {
			
			this.embed = false;
			
		}
		
		hash = Utils.getUniqueID ();
		
		switch(this.type)
		{
			case TYPE_MUSIC : flashClass = "nme.media.Sound";
			case TYPE_SOUND : flashClass = "nme.media.Sound";
			case TYPE_IMAGE : flashClass = "nme.display.BitmapData";
			case TYPE_FONT : flashClass = "nme.text.Font";
			default:
			flashClass = "nme.utils.ByteArray";
		}
	  
      generateFlatName();
	}
	
   private static var usedFlatNames:Hash <String> = new Hash <String> ();
	function generateFlatName()
   {
		
		var chars:String = resourceName.toLowerCase ();
		flatName = "";
		
		for (i in 0...chars.length) {
			
			var code = chars.charCodeAt (i);
			
			if ((i > 0 && code >= "0".charCodeAt (0) && code <= "9".charCodeAt (0)) || (code >= "a".charCodeAt (0) && code <= "z".charCodeAt (0)) || (code == "_".charCodeAt (0))) {
				
				flatName += chars.charAt (i);
				
			} else {
				
				flatName += "_";
				
			}
			
		}
		
		if (flatName == "") {
			
			flatName = "_";
			
		}

      if (flatName.substr(0,1)=="_")
         flatName = "file" + flatName;
		
		while (usedFlatNames.exists (flatName)) {
			
         // Find last digit ...
         var match = ~/(.*?)(\d+)/;
         if (match.match(flatName))
         {
            flatName = match.matched(1) + (Std.parseInt(match.matched(2))+1);
         }
         else
			  flatName += "1";
		}
		
		usedFlatNames.set (flatName, "1");
		
		return flatName;
		
	}
	
}
