package;


import format.xfl.dom.DOMBitmapItem;
import format.XFL;
import haxe.io.Path;
import haxe.Serializer;


class XFLHelper {
	
	
	public static function preprocess (project:NMEProject):Void {
		
		for (library in project.libraries) {
			
			if (library.type == LibraryType.XFL) {
				
				var xfl = new XFL (library.sourcePath);
				var path = Path.directory (library.sourcePath);
				var targetPath = "libraries/" + library.name;
				
				//project.includeAssets (path, targetPath, [ "*.xml", "*.xfl" ]);
				
				var asset = new Asset ("", targetPath + "/" + library.name + ".dat", AssetType.TEXT);
				asset.data = Serializer.run (xfl);
				
				project.assets.push (asset);
				
				for (medium in xfl.document.media) {
					
					if (Std.is (medium, DOMBitmapItem)) {
						
						var bitmapItem = cast (medium, DOMBitmapItem);
						var asset = new Asset (path + "/bin/" + bitmapItem.bitmapDataHRef, targetPath + "/bin/" + bitmapItem.bitmapDataHRef, AssetType.IMAGE);
						asset.id = path + "/bin/" + bitmapItem.bitmapDataHRef;
						
						if (bitmapItem.isJPEG) {
							
							asset.format = "jpg";
							
						} else {
							
							asset.format = "png";
							
						}
						
						project.assets.push (asset);
						
					}
					
				}
				
				project.haxelibs.remove ("xfl");
				project.haxelibs.push ("xfl");
				
			}
			
		}
		
	}
	
	
}