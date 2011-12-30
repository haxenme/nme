package nme.format.swf;

import nme.geom.Matrix;
import nme.geom.ColorTransform;

import nme.format.swf.SWFStream;
import nme.format.swf.Tags;
import nme.format.swf.Character;
import nme.format.swf.Frame;
import nme.format.SWF;
import nme.display.BlendMode;
import nme.filters.BitmapFilter;

typedef FrameLabels = Hash<Int>;


class Sprite
{
   public var mSWF(default,null) : SWF;
   public var mFrames(default,null):Frames;
   var mFrameCount : Int;
   var mFrame:Frame;
   var mFrameLabels:FrameLabels;
   var mName:String;
   var mClassName:String;
   var mBlendMode:BlendMode;
   var mCacheAsBitmap:Bool;
   var mFilters:Array<BitmapFilter>;

   public function new(inSWF:SWF,inID:Int,inFrameCount:Int)
   {
      mSWF = inSWF;
      mFrameCount = inFrameCount;
      mFrames = [ null ]; // frame 0 is empty

      mFilters = null;
      mFrame = new Frame();
      mFrameLabels = new FrameLabels();
      mName = "Sprite " + inID;
      mCacheAsBitmap = false;
   }

   public function GetFrameCount() { return mFrameCount; }

   public function LabelFrame(inName:String)
   {
      mFrameLabels.set(inName,mFrame.GetFrame());
   }

   public function ShowFrame()
   {
      mFrames.push(mFrame);
      mFrame = new Frame(mFrame);
   }

   public function RemoveObject(inStream:SWFStream,inVersion:Int)
   {
      if (inVersion==1)
        inStream.ReadID();
      var depth = inStream.ReadDepth();
      mFrame.Remove(depth);
   }

   public function PlaceObject(inStream:SWFStream,inVersion : Int)
   {
      if (inVersion==1)
      {
         var id = inStream.ReadID();
         var chr = mSWF.GetCharacter(id);
         var depth = inStream.ReadDepth();
         var matrix = inStream.ReadMatrix();
         var col_tx:ColorTransform = inStream.BytesLeft()>0 ?
                 inStream.ReadColorTransform(false) : null;
         mFrame.Place(id,chr,depth,matrix,col_tx,null,null);
      }
      else if (inVersion==2 || inVersion==3)
      {
         inStream.AlignBits();
         var has_clip_action = inStream.ReadBool();
         var has_clip_depth = inStream.ReadBool();
         var has_name = inStream.ReadBool();
         var has_ratio = inStream.ReadBool();
         var has_color_tx = inStream.ReadBool();
         var has_matrix = inStream.ReadBool();
         var has_character = inStream.ReadBool();
         var move = inStream.ReadBool();

         var has_image = false;
         var has_class_name = false;
         var has_cache_as_bmp = false;
         var has_blend_mode = false;
         var has_filter_list = false;
         if (inVersion==3)
         {
            inStream.ReadBool();
            inStream.ReadBool();
            inStream.ReadBool();
            has_image = inStream.ReadBool();
            has_class_name = inStream.ReadBool();
            has_cache_as_bmp = inStream.ReadBool();
            has_blend_mode = inStream.ReadBool();
            has_filter_list = inStream.ReadBool();
         }

         var depth = inStream.ReadDepth();

         if (has_class_name)
            mClassName = inStream.ReadString();
         var cid = has_character ? inStream.ReadID() : 0;

         var matrix = has_matrix ? inStream.ReadMatrix() : null;

         var col_tx = has_color_tx ? inStream.ReadColorTransform(inVersion>2) : null;

         var ratio:Null<Int> = has_ratio ? inStream.ReadUI16() : null;

         if (has_name || (has_image && has_character) )
           mName = inStream.ReadString();


         var clip_depth = has_clip_depth ? inStream.ReadDepth() : 0;
         if (has_filter_list)
         {
            mFilters = [];
            var n = inStream.ReadByte();
            for(i in 0...n)
            {
               var fid = inStream.ReadByte();
               mFilters.push(
                  switch(fid)
                  {
                     case 0 : CreateDropShadowFilter(inStream);
                     case 1 : CreateBlurFilter(inStream);
                     case 2 : CreateGlowFilter(inStream);
                     case 3 : CreateBevelFilter(inStream);
                     case 4 : CreateGradientGlowFilter(inStream);
                     case 5 : CreateConvolutionFilter(inStream);
                     case 6 : CreateColorMatrixFilter(inStream);
                     case 7 : CreateGradientBevelFilter(inStream);
                     default: throw "Unknown filter : " + fid + "  " + i + "/" +n; 
                  }
               );
            }
         }
         if (has_blend_mode)
         {
            mBlendMode = switch( inStream.ReadByte() )
            {
               case 2 : BlendMode.LAYER;
               case 3 : BlendMode.MULTIPLY;
               case 4 : BlendMode.SCREEN;
               case 5 : BlendMode.LIGHTEN;
               case 6 : BlendMode.DARKEN;
               case 7 : BlendMode.DIFFERENCE;
               case 8 : BlendMode.ADD;
               case 9 : BlendMode.SUBTRACT;
               case 10 : BlendMode.INVERT;
               case 11 : BlendMode.ALPHA;
               case 12 : BlendMode.ERASE;
               case 13 : BlendMode.OVERLAY;
               case 14 : BlendMode.HARDLIGHT;
               default:
                   BlendMode.NORMAL;
            }
         }
         if (has_blend_mode)
         {
            mCacheAsBitmap = inStream.ReadByte()>0;
         }


         if (has_clip_action)
         {
            var reserved = inStream.ReadID();
            var action_flags = inStream.ReadID();
            throw("clip action not implemented");
         }

         if (move)
         {
            if (has_character)
            {
               mFrame.Remove(depth);
               mFrame.Place(cid,mSWF.GetCharacter(cid),depth,matrix,col_tx,ratio,mName);
            }
            else
            {
               mFrame.Move(depth,matrix,col_tx,ratio);
            }
         }
         else
         {
            mFrame.Place(cid,mSWF.GetCharacter(cid),depth,matrix,col_tx,ratio,mName);
         }
      }
      else
      {
         throw("place object not implemented:" + inVersion);
      }
   }

   function CreateDropShadowFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateDropShadowFilter");
      return null;
   }

   function CreateBlurFilter(inStream:SWFStream) : BitmapFilter
   {
      //trace("CreateBlurFilter");
      var blurx = inStream.ReadFixed();
      var blury = inStream.ReadFixed();
      var passes = inStream.ReadByte();
      //trace(blurx + "x" + blury + "  x " + passes);
      return null;
   }

   function CreateGlowFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateGlowFilter");
      return null;
   }

   function CreateBevelFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateBevelFilter");
      return null;
   }

   function CreateGradientGlowFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateGradientGlowFilter");
      return null;
   }

   function CreateConvolutionFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateConvolutionFilter");
      var w = inStream.ReadByte();
      var h = inStream.ReadByte();
      var div = inStream.ReadFloat();
      var bias = inStream.ReadFloat();
      var mtx = new Array<Float>();
      for(i in 0...w*h)
         mtx[i] = inStream.ReadFloat();
      var flags = inStream.ReadByte();
      return null;
   }

   function CreateColorMatrixFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateColorMatrixFilter");
      var mtx = new Array<Float>();
      for(i in 0...20)
         mtx.push( inStream.ReadFloat() );

      return null;
   }

   function CreateGradientBevelFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateGradientBevelFilter");
      return null;
   }



}
