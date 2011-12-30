package nme.format.swf;

import nme.format.swf.Character;
import nme.format.swf.DisplayAttributes;
import nme.geom.ColorTransform;
import nme.geom.Matrix;



class DepthSlot
{
   //static var sInstanceID = 1;

   public var mID:Int;
   public var mAttribs : DisplayAttributesList;
   public var mCharacter : Character;

   // This is used when building
   var mCurrentAttrib : DisplayAttributes;


   public function new(inCharacter:Character,inCharacterID:Int,
           inAttribs:DisplayAttributes)
   {
      mID = inCharacterID;
      mAttribs = [];
      mAttribs.push(inAttribs);
      mCurrentAttrib = inAttribs;
      mCharacter = inCharacter;
   }

   public function Move(inFrame:Int,
                  inMatrix:Matrix, inColTx:ColorTransform,
                  inRatio:Null<Int>)
   {
      mCurrentAttrib = mCurrentAttrib.clone();
      mCurrentAttrib.mFrame = inFrame;
      if (inMatrix!=null) mCurrentAttrib.mMatrix = inMatrix;
      if (inColTx!=null) mCurrentAttrib.mColorTransform = inColTx;
      if (inRatio!=null) mCurrentAttrib.mRatio = inRatio;
      mAttribs.push(mCurrentAttrib);
   }



   public function FindClosestFrame(inHintFrame:Int,inFrame:Int)
   {
      var last = inHintFrame;
      var n = mAttribs.length;
      if (last>=mAttribs.length)
         last = 0;
      else if (last>0)
      {
         if ( mAttribs[last-1].mFrame > inFrame)
            last = 0;
      }

      for(i in last...n)
      {
         if (mAttribs[i].mFrame > inFrame)
         {
            return last;
         }
         last = i;
      }
      
      return last;
   }


}



