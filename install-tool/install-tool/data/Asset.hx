package data;


import neko.io.Path;


class Asset {
	
	
	public static var TYPE_ASSET:String = "asset";
	public static var TYPE_FONT:String = "font";
	public static var TYPE_IMAGE:String = "image";
	public static var TYPE_MUSIC:String = "music";
	public static var TYPE_SOUND:String = "sound";
	
	public var embed:Bool;
	public var id:String;
	public var resourceName:String;
	public var sourcePath:String;
	public var targetPath:String;
	public var type:String;
	
	
	public function new (sourcePath:String, targetPath:String, type:String, id:String, embed:String) {
		
		this.sourcePath = sourcePath;
		this.targetPath = targetPath;
		
		if (this.targetPath == "") {
			
			this.targetPath = sourcePath;
			
		}
		
		this.type = type;
		this.id = id;
		
		if (this.id == "") {
			
			this.id = targetPath;
			
		}
		
		this.resourceName = targetPath;
		
		if (this.type == "") {
			
			var extension:String = Path.extension (targetPath);
			
			switch (extension.toLowerCase ()) {
				
				case "jpg", "jpeg", "png", "svg", "gif":
					
					this.type = TYPE_IMAGE;
				
				case "otf", "ttf":
					
					this.type = TYPE_FONT;
				
				case "wav", "ogg":
					
					this.type = TYPE_SOUND;
				
				case "mp3", "mp2":
					
					this.type = TYPE_MUSIC;
				
				default:
					
					this.type = TYPE_ASSET;
				
			}
			
		}
		
		if (embed == "" || embed == "1" || embed == "true") {
			
			this.embed = true;
			
		} else {
			
			this.embed = false;
			
		}
		
	}
	
	
}
