package installers;


import neko.io.Path;
import neko.Lib;
import neko.Sys;
import data.Asset;

import format.swf.Data;
import format.swf.Constants;
import format.mp3.Data;
import format.wav.Data;

import nme.text.Font;


class FlashInstaller extends InstallerBase {
	
	
	override function build ():Void {
		
		var destination:String = buildDirectory + "/flash/bin/";
		mkdir (destination);
		
		recursiveCopy (NME + "/install-tool/haxe", buildDirectory + "/flash/haxe");
		recursiveCopy (NME + "/install-tool/flash/hxml", buildDirectory + "/flash/haxe");
		recursiveCopy (NME + "/install-tool/flash/template", buildDirectory + "/flash/haxe");
		
		var hxml:String = buildDirectory + "/flash/haxe/" + (debug ? "debug" : "release") + ".hxml";
		
		runCommand ("", "haxe", [ hxml ] );
		
		var file = defines.get("APP_FILE") + ".swf";
		var input = neko.io.File.read(destination+"/"+file,true);
		var reader = new format.swf.Reader(input);
		var swf = reader.read();
		input.close();
		
		var new_tags = new Array<SWFTag>();
		var inserted = false;
		for(tag in swf.tags)
		{
			var name = Type.enumConstructor(tag);
			//trace(name);
			//if (name=="TSymbolClass") trace(tag);

			if (name=="TShowFrame" && !inserted && assets.length>0 )
			{
				new_tags.push(TShowFrame);
				for(asset in assets)
					if (toSwf(asset,new_tags) )
						inserted = true;
			}
			new_tags.push(tag);
		}

		if (inserted)
		{
			swf.tags = new_tags;
			var output = neko.io.File.write(destination+"/"+file,true);
			var writer = new format.swf.Writer(output);
			writer.write(swf);
			output.close();
		}
		
	}

   static var swfAddetID = 1000;
   function nextAssetID()
   {
      return swfAddetID++;
   }

   public function toSwf(inAsset:Asset, outTags:Array<SWFTag>)
   {
      var embed = inAsset.embed;
      var name = inAsset.sourcePath;
      var type = inAsset.type;
      var flatName = inAsset.flatName;

      if (!embed)
         return false;
      var cid=nextAssetID( );

      if (type=="music" || type=="sound")
      {
         var src = name;
         var ext = neko.io.Path.extension(src);
         if (ext!="mp3" && ext!="wav")
         {
            for( e in ["wav", "mp3"] )
            {
               src = name.substr(0, name.length - ext.length) + e;
               if (neko.FileSystem.exists(src))
                  break;
            }
         }
         if (!neko.FileSystem.exists(src))
            throw "Could not find mp3/wav source: " + src;
         var ext = neko.io.Path.extension(src);

         var input = neko.io.File.read(src, true);
         if (ext=="mp3")
         {
            // Code lifted from "samhaxe"
            var r = new format.mp3.Reader(input);
            var mp3 = r.read();
            if (mp3.frames.length == 0)
               throw "No frames found in mp3: " + src;

            // Guess about the format based on the header of the first frame found
            var fr0 = mp3.frames[0];
            var hdr0 = fr0.header;

            // Verify Layer3-ness
            if (hdr0.layer != Layer.Layer3)
               throw "Only Layer-III mp3 files are supported by flash. File " +
                    src + " is: " + format.mp3.Tools.getFrameInfo(fr0);

            // Check sampling rate
            var flashRate = switch (hdr0.samplingRate)
            {
               case SR_11025: SR11k;
               case SR_22050: SR22k;
               case SR_44100: SR44k;
               default:
                  throw "Only 11025, 22050 and 44100 Hz mp3 files are supported by flash. File " +
                     src + " is: " + format.mp3.Tools.getFrameInfo(fr0);
            }

            var isStereo = switch (hdr0.channelMode)
            {
               case Stereo, JointStereo, DualChannel: true;
               case Mono: false;
            };

            // Should we do this? For now, let's do.
            var write_id3v2 = true;

            var rawdata = new haxe.io.BytesOutput();
            (new format.mp3.Writer(rawdata)).write(mp3, write_id3v2);
            var dataBytes = rawdata.getBytes();

            var snd =
            {
                sid : cid,
                format : SFMP3,
                rate : flashRate,
                is16bit : true,
                isStereo : isStereo,
                samples : haxe.Int32.ofInt(mp3.sampleCount),
                data : SDMp3(0, dataBytes)
            };

            outTags.push( TSound(snd) );
         }
         else
         {
            var r = new format.wav.Reader(input);
            var wav = r.read();
            var hdr = wav.header;

            if (hdr.format != WF_PCM) 
               throw "Only PCM (uncompressed) wav files can be imported.";

            // Check sampling rate
            var flashRate = switch (hdr.samplingRate)
            {
               case  5512: SR5k;
               case 11025: SR11k;
               case 22050: SR22k;
                     case 44100: SR44k;
               default:
                  throw "Only 5512, 11025, 22050 and 44100 Hz wav files are supported by flash. Sampling rate of '" + src + "' is: " + hdr.samplingRate;
            }

            var isStereo = switch(hdr.channels)
            {
               case 1: false;
               case 2: true;
               default: throw "Number of channels should be 1 or 2, but for '" + src + "' it is " + hdr.channels;
            }
       
            var is16bit = switch(hdr.bitsPerSample)
            {
               case 8: false;
               case 16: true;
               default: throw "Bits per sample should be 8 or 16, but for '" + src + "' it is " + hdr.bitsPerSample;
            }

            var sampleCount = Std.int(wav.data.length / (hdr.bitsPerSample / 8));


            var snd : format.swf.Sound =
            {
               sid : cid,
               format : SFLittleEndianUncompressed,
               rate : flashRate,
               is16bit : is16bit,
               isStereo : isStereo,
               samples : haxe.Int32.ofInt(sampleCount),
               data : SDRaw(wav.data)
            }

            outTags.push(TSound(snd));
         }
         input.close();
      }
      else if (type=="image")
      {
         var src = name;
         var ext = neko.io.Path.extension(src).toLowerCase();
         if (ext=="jpg" || ext=="png")
         {
             var bytes: haxe.io.Bytes;
             try { bytes = neko.io.File.read(src, true).readAll(); }
             catch (e : Dynamic) { throw "Could not load image file: " + src; }

             outTags.push( TBitsJPEG(cid,JDJPEG2(bytes)) );

         }
         else
            throw("Unknown image type:" + src );
      }
      else if (type=="font")
      {
		  
		  
          // More code ripped off from "samhaxe"
          var src = name;
          var font_name = neko.io.Path.withoutExtension(name);
          var font = nme.text.Font.load(src);

          var glyphs = new Array<Font2GlyphData>();
          var glyph_layout = new Array<FontLayoutGlyphData>();


          for(native_glyph in font.glyphs)
          {
              if(native_glyph.char_code > 65535)
              {
                 neko.Lib.println("Warning: glyph with character code greater than 65535 encountered ("+
                     native_glyph.char_code+"). Skipping...");
                 continue;
              }


             var shapeRecords = new Array<ShapeRecord>();
             var i: Int = 0;
             var styleChanged: Bool = false;
   
             while(i < native_glyph.points.length)
             {
                var type = native_glyph.points[i++];
                switch(type)
                {
                  case 1: // Move
                     var dx = native_glyph.points[i++];
                     var dy = native_glyph.points[i++];
                     shapeRecords.push( SHRChange({
                        moveTo: {dx: dx, dy: -dy},
                        // Set fill style to 1 in first style change record
                        // Required by DefineFontX
                        fillStyle0: if(!styleChanged) {idx: 1} else null,
                        fillStyle1: null,
                        lineStyle:  null,
                        newStyles:  null
                     }));
                     styleChanged = true;

                  case 2: // LineTo
                     var dx = native_glyph.points[i++];
                     var dy = native_glyph.points[i++];
                     shapeRecords.push( SHREdge(dx, -dy) );

                  case 3: // CurveTo
                     var cdx = native_glyph.points[i++];
                     var cdy = native_glyph.points[i++];
                     var adx = native_glyph.points[i++];
                     var ady = native_glyph.points[i++];
                     shapeRecords.push( SHRCurvedEdge(cdx, -cdy, adx, -ady) );

                  default:
                     throw "Invalid control point type encountered! ("+type+")";
               }
            }
         
            shapeRecords.push( SHREnd );
   
            glyphs.push({
               charCode: native_glyph.char_code,
               shape: {
                  shapeRecords: shapeRecords
               } 
            });
   
            glyph_layout.push({
               advance: native_glyph.advance,
               bounds: {
                  left:    native_glyph.min_x,
                  right:   native_glyph.max_x,
                  top:    -native_glyph.max_y,
                  bottom: -native_glyph.min_y,
               }
            });
         }


         var kerning = new Array<FontKerningData>();
         for(k in font.kerning)
            kerning.push({
               charCode1:  k.left_glyph,
               charCode2:  k.right_glyph,
               adjust:     k.x,
            });

 
         var swf_em = 1024*20;
         var ascent = Math.ceil(font.ascend * swf_em / font.em_size);
         var descent = -Math.ceil(font.descend * swf_em / font.em_size);
         var leading = Math.ceil((font.height - font.ascend + font.descend) * swf_em / font.em_size);
         var language = LangCode.LCNone;


         outTags.push( TFont(cid, FDFont3({
                  shiftJIS:   false,
                  isSmall:    false,
                  isANSI:     false,
                  isItalic:   font.is_italic,
                  isBold:     font.is_bold,
                  language:   language,
                  name:       font_name,
                  glyphs:     glyphs,
                  layout: {
                     ascent:     ascent,
                     descent:    descent,
                     leading:    leading,
                     glyphs:     glyph_layout,
                     kerning:    kerning
                  }
            })) );
			
      }
      else
      {
         var bytes = neko.io.File.getBytes(name);
         outTags.push( TBinaryData(cid,bytes) );
      }

      outTags.push( TSymbolClass( [ {cid:cid, className:"NME_" + flatName} ] ) );
      return true;
   }

	override function run ():Void {
		
		var destination:String = buildDirectory + "/flash/bin";
		var player:String = Sys.getEnv ("FLASH_PLAYER_EXE");
		
		if (player == null) {
			
			if (defines.exists ("macos")) {
				
				player = "/Applications/Flash Player Debugger.app/Contents/MacOS/Flash Player Debugger";
				
			}
			
		}
		
		if (player == null || player == "") {
			
			var dotSlash:String = "./";
			
			if (defines.exists ("windows")) {
				
				dotSlash = ".\\";
				
			}
			
			runCommand (destination, dotSlash + defines.get ("APP_FILE") + ".swf", []);
			
		} else {
			
			runCommand (destination, player, [ defines.get ("APP_FILE") + ".swf" ]);
			
		}
		
	}
	
	
	override function update ():Void {
		
		var destination:String = buildDirectory + "/flash/bin";
		
		for (asset in assets) {
			
			if (!asset.embed) {
				
				mkdir (Path.directory (destination + asset.targetPath));
				copyIfNewer (asset.sourcePath, destination + asset.targetPath);
				
			}
			
		}
		
	}
	
	
}

