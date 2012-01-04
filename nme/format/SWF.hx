package nme.format;


import nme.display.BitmapData;
import nme.display.Loader;
import nme.display.MovieClip;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.geom.Rectangle;
import nme.format.swf.Bitmap;
import nme.format.swf.Character;
import nme.format.swf.EditText;
import nme.format.swf.Font;
import nme.format.swf.Frame;
import nme.format.swf.MorphShape;
import nme.format.swf.Shape;
import nme.format.swf.Sprite;
import nme.format.swf.StaticText;
import nme.format.swf.SWFStream;
import nme.format.swf.Tags;
import nme.utils.ByteArray;

#if flash
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
#end


class SWF extends EventDispatcher
{
	
	public var backgroundColor (default, null):Int;
	public var frameRate (default, null):Float;
	public var height (default, null):Int;
	public var width (default, null):Int;
	
	private var loaded:Bool;
	private var mDictionary:Array<Character>;
	private var mMain:Sprite;
	private var mStream:SWFStream;
	private var mSymbols:Hash<Int>;
	private var mVersion:Int;
	
	#if flash
	private var loader:Loader;
	#end
	
	
	public function new(data:ByteArray)
	{
		super ();
		
		#if flash
		loader = new Loader ();
		var context = new LoaderContext (false, new ApplicationDomain ());
		loader.contentLoaderInfo.addEventListener (Event.COMPLETE, loader_onComplete);
		loader.loadBytes (data, context);
		#else
		
		mStream = new SWFStream(data);
		
		var mRect = mStream.ReadRect();
		width = Std.int(mRect.width);
		height = Std.int(mRect.height);
		
		frameRate = mStream.FrameRate();
		
		var count = mStream.Frames();
		
		mDictionary = [];
		mSymbols = new Hash<Int>();
		
		mMain = new Sprite(this, 0, count);
		
		var count:Array<Int> = [];
		for (i in 0...Tags.LAST)
			count.push(0);
		
		var tag = 0;
		while ((tag = mStream.BeginTag()) != 0)
		{
			//trace( Tags.string(tag) + "  x  " + mStream.mTagSize );
			count[tag]++;
			switch(tag)
			{
				case Tags.SetBackgroundColor:
					backgroundColor = mStream.ReadRGB();
				
				case Tags.DefineShape:
					DefineShape(1);
				case Tags.DefineShape2:
					DefineShape(2);
				case Tags.DefineShape3:
					DefineShape(3);
				case Tags.DefineShape4:
					DefineShape(4);
				
				case Tags.DefineMorphShape:
					DefineMorphShape(1);
				case Tags.DefineMorphShape2:
					DefineMorphShape(2);
				
				case Tags.DefineSprite:
					DefineSprite();
				
				case Tags.PlaceObject:
					mMain.PlaceObject(mStream, 1);
				case Tags.PlaceObject2:
					mMain.PlaceObject(mStream, 2);
				case Tags.PlaceObject3:
					mMain.PlaceObject(mStream, 3);
				
				case Tags.RemoveObject:
					mMain.RemoveObject(mStream, 1);
				case Tags.RemoveObject2:
					mMain.RemoveObject(mStream, 2);
				
				case Tags.DefineBits:
					throw("DefineBits not implemented");
				case Tags.JPEGTables:
					throw("JPEGTables not implemented");
				
				case Tags.DefineBitsJPEG2:
					DefineBitmap(false, 2);
				case Tags.DefineBitsJPEG3:
					DefineBitmap(false, 3);
				
				case Tags.DefineBitsLossless:
					DefineBitmap(true, 1);
				case Tags.DefineBitsLossless2:
					DefineBitmap(true, 2);
				
				case Tags.DefineFont:
					DefineFont(1);
				case Tags.DefineFont2:
					DefineFont(2);
				case Tags.DefineFont3:
					DefineFont(3);
				
				case Tags.DefineText:
					DefineText(1);
				
				case Tags.ShowFrame:
					mMain.ShowFrame();
				
				case Tags.DefineFontName:
					// safely ignore
				
				case Tags.DefineFontAlignZones:
					// todo:
				
				case Tags.CSMTextSettings:
					// todo:
				
				case Tags.DoAction:
					// todo:
				
				case Tags.DoABC2:
					// todo:
				
				case Tags.FileAttributes:
					ReadFileAttributes();
					// Do nothing
				
				case Tags.DefineEditText:
					DefineEditText(1);
				
				case Tags.SymbolClass:
					SymbolClass();
				
				case Tags.DefineSceneAndFrameLabelData:
					//ignored
				
				case Tags.MetaData:
					//ignored
				
				default:
					trace("Unknown tag:" + Tags.string(tag));
			}
			mStream.EndTag();
		}
		
		//This is quite good for debug
		/*
		for(i in 0...Tags.LAST)
		if (count[i]!=0)
		trace( Tags.string(i) + " = " + count[i] );
		*/
		
		mStream.close();
		mStream = null;
		
		loaded = true;
		
		#end
	}
	
	
	override public function addEventListener(type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		
		if (loaded)
		{
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
	
	
	public function createInstance(name:String = ""):MovieClip
	{
		#if flash
		if (loader == null)
		{
			return null;
		}
		
		if (name == "") {
			
			// If you want the whole SWF, we have to return the same instance in Flash
			return cast (loader.content, MovieClip);
			
		}
		
		var applicationDomain = loader.contentLoaderInfo.applicationDomain;
		
		if (applicationDomain.hasDefinition(name))
		{
			return Type.createEmptyInstance(applicationDomain.getDefinition(name));
		}
		#else
		
		if (name == "")
		{
			var result = new MovieClip();
			result.nmeCreateFromSWF(mMain);
			return result;
		}
		
		if (!mSymbols.exists(name))
			return null;
		
		switch (getCharacter(mSymbols.get(name)))
		{
			case charSprite(sprite) :
				var result = new MovieClip();
				result.nmeCreateFromSWF(sprite);
				return result;
			
			default:
				return null;
		}
		#end
		
		return null;
	}
	
	
	public function getBitmapData(name:String):BitmapData
	{
		#if flash
		if (loader == null)
		{
			return null;
		}
		
		var applicationDomain = loader.contentLoaderInfo.applicationDomain;
		
		if (applicationDomain.hasDefinition(name))
		{
			return Type.createEmptyInstance(applicationDomain.getDefinition(name));
		}
		#else
		
		if (!mSymbols.exists(name))
			return null;
		
		switch (getCharacter(mSymbols.get(name)))
		{
			case charBitmap(bits):
				return bits.GetBitmap();
				
			default:
				return null;
		}
		#end
		
		return null;
	}
	
	
	public function getBitmapDataID(id:Int):BitmapData
	{
		if (id == 0xffff)
			return null;
		
		if (mDictionary[id] == null)
			throw("Bitmap not defined: " + id);
		
		switch (getCharacter(id))
		{
			case charBitmap(bits) : return bits.GetBitmap();
			default: throw "Non-bitmap character";
		}
		
		return null;
	}
	
	
	public function getCharacter(inID:Int)
	{
		var result = mDictionary[inID];
		if (result == null)
			throw "Invalid character ID (" + inID + ")";
		return result;
	}
	
	
	private function DefineBitmap(inLossless:Bool, inVersion:Int)
	{
		var shape_id = mStream.ReadID();
		//trace("Define bitmap : " + shape_id);
		mDictionary[shape_id] = charBitmap(new Bitmap(mStream, inLossless, inVersion));
	}
	
	
	private function DefineEditText(inVersion:Int)
	{
		var text_id = mStream.ReadID();
		mDictionary[text_id] = charEditText(new EditText(this, mStream, inVersion));
	}
	
	
	private function DefineFont(inVersion:Int)
	{
		var shape_id = mStream.ReadID();
		mDictionary[shape_id] = charFont(new Font(mStream, inVersion));
	}
	
	
	private function DefineMorphShape(inVersion:Int)
	{
		var shape_id = mStream.ReadID();
		mDictionary[shape_id] = charMorphShape(new MorphShape(this, mStream, inVersion));
	}
	
	
	private function DefineShape(inVersion:Int)
	{
		var shape_id = mStream.ReadID();
		//trace("Define shape " + shape_id);
		mDictionary[shape_id] = charShape(new Shape(this, mStream, inVersion));
	}
	
	
	private function DefineSprite()
	{
		var id = mStream.ReadID();
		//trace("Define sprite " + id);
		var frames = mStream.Frames();
		mStream.PushTag();
		
		var sprite = new Sprite(this, id, frames);
		
		var tag = 0;
		var fid = 1;
		while ((tag = mStream.BeginTag ()) != 0)
		{
			//trace("sub tag:" + Tags.string(tag) );
			switch (tag)
			{
				case Tags.FrameLabel:
					sprite.LabelFrame(mStream.ReadString());
				case Tags.ShowFrame:
					//trace(" frame:" + (fid++));
					sprite.ShowFrame();
				
				case Tags.PlaceObject:
					sprite.PlaceObject(mStream, 1);
				case Tags.PlaceObject2:
					sprite.PlaceObject(mStream, 2);
				case Tags.PlaceObject3:
					sprite.PlaceObject(mStream, 3);
				
				case Tags.RemoveObject:
					sprite.RemoveObject(mStream, 1);
				case Tags.RemoveObject2:
					sprite.RemoveObject(mStream, 2);
				case Tags.DoAction:
					// not implemented
				default:
					trace("Unknown sub tag: " +  Tags.string(tag));
			}
			mStream.EndTag();
		}
		
		mDictionary[id] = charSprite(sprite);
		mStream.PopTag();
	}
	
	
	private function DefineText(inVersion:Int)
	{
		var text_id = mStream.ReadID();
		mDictionary[text_id] = charStaticText(new StaticText(this, mStream, inVersion));
	}
	
	
	private function ReadFileAttributes()
	{
		var flags = mStream.ReadByte();
		var zero = mStream.ReadByte();
		zero = mStream.ReadByte();
		zero = mStream.ReadByte();
	}
	

	private function SymbolClass()
	{
		var n = mStream.ReadUI16();
		for (i in 0...n)
		{
			var id = mStream.ReadUI16();
			var str = mStream.ReadString();
			mSymbols.set(str, id);
		}
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function loader_onComplete(event:Event):Void
	{
		trace ("hi");
		loaded = true;
		dispatchEvent(new Event(Event.COMPLETE));
	}


}


typedef Function = Dynamic -> Void;