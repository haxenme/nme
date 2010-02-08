package nme.display;

import nme.events.Event;

class DisplayObjectContainer extends InteractiveObject
{
   public var mouseChildren(nmeGetMouseChildren,nmeSetMouseChildren) : Bool;
   public var numChildren(nmeGetNumChildren,null) : Int;
   public var tabChildren(nmeGetTabChildren,nmeSetTabChildren) : Bool;
   // Not implemented
   //public var textSnapshot(nmeGetTextSnapshot,null) : TextSnapshot;

   var nmeChildren:Array<DisplayObject>;

   public function new(inHandle:Dynamic)
   {
      super(inHandle);
      nmeName = "DisplayObjectContainer";
      nmeChildren = [];
   }

   override function nmeFindByID(inID:Int) : DisplayObject
   {
      if (nmeID==inID)
         return this;
      for(child in nmeChildren)
      {
          var found = child.nmeFindByID(inID);
          if (found!=null)
             return found;
      }
      return super.nmeFindByID(inID);
   }

   override public function nmeBroadcast(inEvt:Event)
   {
      var i = 0;
      if (nmeChildren.length>0)
         while(true)
         {
            var child = nmeChildren[i];
            child.nmeBroadcast(inEvt);
            if (i>=nmeChildren.length)
               break;
            if (nmeChildren[i]==child)
            {
               i++;
               if (i>=nmeChildren.length)
                  break;
            }
         }
      dispatchEvent(inEvt);
   }
 

   function nmeGetMouseChildren() { return false; }
   function nmeSetMouseChildren(inValue:Bool):Bool { return false; }
   function nmeGetTabChildren() { return false; }
   function nmeSetTabChildren(inValue:Bool) { return false; }
   function nmeGetNumChildren() : Int { return nmeChildren.length; }

   public function nmeRemoveChildFromArray( child : DisplayObject )
   {
      var i = getChildIndex(child);
      if (i>=0)
      {
         nmeChildren.splice( i, 1 );
      }
   }

   override function nmeOnAdded(inObj:DisplayObject)
   {
      super.nmeOnAdded(inObj);
      for(child in nmeChildren)
         child.nmeOnAdded(inObj);
   }

   override function nmeOnRemoved(inObj:DisplayObject)
   {
      super.nmeOnRemoved(inObj);
      for(child in nmeChildren)
         child.nmeOnRemoved(inObj);
   }

   public function addChild(child:DisplayObject):DisplayObject
   {
      if (child == this) {
         throw "Adding to self";
      }
      if (child.nmeParent==this)
      {
         setChildIndex(child,nmeChildren.length-1);
      }
      else
      {
         child.nmeSetParent(this);
         nmeChildren.push(child);
         nme_doc_add_child(nmeHandle,child.nmeHandle);
      }
      return child;
   }

   /*
   public function addChildAt(child:DisplayObject, index:int):DisplayObject
   public function areInaccessibleObjectsUnderPoint(point:Point):Bool
   public function contains(child:DisplayObject):Bool
   public function getChildAt(index:int):DisplayObject
    public function getChildByName(name:String):DisplayObject
   */
   public function getChildIndex(child:DisplayObject):Int
   {
      for ( i in 0...nmeChildren.length )
         if ( nmeChildren[i] == child )
            return i;
      return -1;
   }
   /*
   public function getObjectsUnderPoint(point:Point):Array
   public function removeChild(child:DisplayObject):DisplayObject
   public function removeChildAt(index:int):DisplayObject
   */
   public function setChildIndex(child:DisplayObject, index:Int):Void
   {
      if(index > nmeChildren.length)
         throw "Invalid index position " + index;

      var s : DisplayObject = null;
      var orig = getChildIndex(child);

      if (orig < 0) {
         var msg = "setChildIndex : object " + child.toString() + " not found.";
         if(child.nmeParent == this) {
            var realindex = -1;
            for(i in 0...nmeChildren.length) {
               if(nmeChildren[i] == child) {
                  realindex = i;
                  break;
               }
            }
            if(realindex != -1)
               msg += "Internal error: Real child index was " + Std.string(realindex);
            else
               msg += "Internal error: Child was not in nmeChildren array!";
         }
         throw msg;
      }

      nme_doc_set_child_index(nmeHandle,child.nmeHandle,index);

      // move down ...
      if (index<orig)
      {
         var i = orig;
         while(i > index) {
            nmeChildren[i] = nmeChildren[i-1];
            i--;
         }
         nmeChildren[index] = child;
      }
      // move up ...
      else if (orig<index)
      {
         var i = orig;
         while(i < index) {
            nmeChildren[i] = nmeChildren[i+1];
            i++;
         }
         nmeChildren[index] = child;
      }
   }
   /*
   public function swapChildren(child1:DisplayObject, child2:DisplayObject):Void
   public function swapChildrenAt(index1:int, index2:int):Void
   */



   static var nme_create_display_object_container = nme.Loader.load("nme_create_display_object_container",0);
   static var nme_doc_add_child = nme.Loader.load("nme_doc_add_child",2);
   //static var nme_doc_remove_child = nme.Loader.load("nme_doc_remove_child",2);
   static var nme_doc_set_child_index = nme.Loader.load("nme_doc_set_child_index",3);

}
