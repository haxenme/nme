package;


import format.SVG;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Path;
import nme.display.BitmapData;
import nme.display.BitmapInt32;
import nme.display.Shape;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;


class IconHelper {
	
	
	public static function createMacIcon (project:NMEProject, targetDirectory:String):String {
		
		var out = new BytesOutput ();
		out.bigEndian = true;
		
		// Not sure why the 128x128 icon is not saving properly. Disabling for now
		
		for (i in 0...3) {
			
			var s =  ([ 16, 32, 48, 128 ])[i];
			var code =  ([ "is32", "il32", "ih32", "it32" ])[i];
			var bmp = getIconBitmap (project, s, s);
			
			if (bmp != null) {
				
				for (c in 0...4) out.writeByte (code.charCodeAt(c));
				
				var n = s * s;
				var pixels = bmp.getPixels (new Rectangle (0, 0, s, s));
				
				var bytes_r = packBits (pixels, 1, s * s);
				var bytes_g = packBits (pixels, 2, s * s);
				var bytes_b = packBits (pixels, 3, s * s);
				
				out.writeInt31 (bytes_r.length + bytes_g.length + bytes_b.length + 8);
				out.writeBytes (bytes_r, 0, bytes_r.length);
				out.writeBytes (bytes_g, 0, bytes_g.length);
				out.writeBytes (bytes_b, 0, bytes_b.length);
				
				var code =  ([ "s8mk", "l8mk", "h8mk", "t8mk" ])[i];
				
				for (c in 0...4) out.writeByte (code.charCodeAt (c));
				
				var bytes_a = extractBits (pixels, 0, s * s);
				out.writeInt31 (bytes_a.length + 8);
				out.writeBytes (bytes_a, 0, bytes_a.length);
				
			}
			
		}
		
		for (i in 0...5) {
			
			var s =  ([ 32, 64, 256, 512, 1024 ])[i];
			var code =  ([ "ic11", "ic12", "ic08", "ic09", "ic10" ])[i];
			var bmp = getIconBitmap (project, s, s);
			
			if (bmp != null) {
				
				for (c in 0...4) out.writeByte (code.charCodeAt(c));
				
				var bytes = bmp.encode ("png");
				
				out.writeInt31 (bytes.length + 8);
				out.writeBytes (bytes, 0, bytes.length);
				
			}
			
		}
		
		var bytes = out.getBytes ();
		
		if (bytes.length > 0) {
			
			var filename = PathHelper.combine (targetDirectory, "icon.icns");
			var file = File.write (filename, true);
			file.bigEndian = true;
			
			for (c in 0...4) file.writeByte ("icns".charCodeAt (c));
			
			file.writeInt31 (bytes.length + 8);
			file.writeBytes (bytes, 0, bytes.length);
			file.close ();
			
			return filename;
			
		}
		
		return "";
		
	}
	
	
	private static function extractBits (data:ByteArray, offset:Int, len:Int):Bytes {
		
		var out = new BytesOutput ();
		
		for (i in 0...len) {
			
			out.writeByte (data[i * 4 + offset]);
			
		}
		
		return out.getBytes ();
		
	}
	
	
	private static function getIconBitmap (project:NMEProject, width:Int, height:Int, /*targetPath:String="",*/ backgroundColor:BitmapInt32 = null):BitmapData {
		
		for (icon in project.icons) {
			
			if (icon.width == width && icon.height == height) {
				
				/*if (targetPath != "" && FileSystem.exists (targetPath) && !FileHelper.isNewer (icon.path, targetPath)) {
					
					return null;
					
				}*/
				
				return BitmapData.load (icon.path);
				
			}
			
		}
		
		var matches = [];
		
		for (icon in project.icons) {
			
			if ((icon.width == width || icon.width == -1) && (icon.height == height || icon.height == -1)) {
				
				matches.push (icon);
				
				/*if (targetPath != "" && FileSystem.exists (targetPath) && !FileHelper.isNewer (icon.path, targetPath)) {
					
					return null;
					
				}*/
				
			}
			
		}
		
		matches.reverse ();
		
		for (match in matches) {
			
			switch (Path.extension (match.path)) {
				
				case "svg":
					
					var svg = new SVG (File.getContent (match.path));
					var shape = new Shape ();
					svg.render (shape.graphics, 0, 0, width, height);
					
					var bitmapData = new BitmapData (width, height, true, (backgroundColor == null ? #if neko { a: 0, rgb: 0xFFFFFF } #else 0xFFFFFFFF #end : backgroundColor));
					bitmapData.draw (shape);
					
					return bitmapData;
				
			}
			
		}
		
		return null;
		
	}
   
   
	private static function packBits (data:ByteArray, offset:Int, len:Int):Bytes {
		
		var out = new BytesOutput ();
		var idx = 0;
		
		while (idx < len) {
			
			var val = data[idx * 4 + offset];
			var same = 1;
			
			/*
			Hmmmm...
			while( ((idx+same) < len) && (data[ (idx+same)*4 + offset ]==val) && (same < 2) )
			same++;
			*/
			
			if (same == 1) {
				
				var raw = idx + 120 < len ? 120 : len - idx;
				out.writeByte (raw - 1);
				
				for (i in 0...raw) {
					
					out.writeByte (data[idx * 4 + offset]);
					idx++;
					
				}
				
			} else {
				
				out.writeByte (257 - same);
				out.writeByte (val);
				idx += same;
				
			}
			
		}
		
		return out.getBytes ();
		
	}
		

}