package nme2.display;

class DisplayObjectContainer extends DisplayObject
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
		nmeChildren = [];
	}
	function nmeGetMouseChildren() { return false; }
	function nmeSetMouseChildren(inValue:Bool):Bool { return false; }
	function nmeGetTabChildren() { return false; }
	function nmeSetTabChildren(inValue:Bool) { return false; }
	function nmeGetNumChildren() : Int { return nmeChildren.length; }

	/*
	public function addChild(child:DisplayObject):DisplayObject
	{
		if (child == this) {
			throw "Adding to self";
		}
		if (child.nmeParent==this)
		{
			setChildIndex(child,nmeChildren.length-1);
			return;
		}
		nmeChildren.push(child);
	}

	public function addChildAt(child:DisplayObject, index:int):DisplayObject
	public function areInaccessibleObjectsUnderPoint(point:Point):Bool
	public function contains(child:DisplayObject):Bool
	public function getChildAt(index:int):DisplayObject
 	public function getChildByName(name:String):DisplayObject
	public function getChildIndex(child:DisplayObject):int
	public function getObjectsUnderPoint(point:Point):Array
	public function removeChild(child:DisplayObject):DisplayObject
	public function removeChildAt(index:int):DisplayObject
	public function setChildIndex(child:DisplayObject, index:int):Void
	public function swapChildren(child1:DisplayObject, child2:DisplayObject):Void
	public function swapChildrenAt(index1:int, index2:int):Void
	*/



	static var nme_create_display_object_container = nme2.Loader.load("nme_create_display_object_container",0);

}
