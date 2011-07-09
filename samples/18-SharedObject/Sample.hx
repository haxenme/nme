
import flash.Lib;
import flash.text.TextField;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.net.SharedObject;


class Sample extends Sprite
{
   private var so:SharedObject;
	
   public function new()
   {
      super();
      var label:TextField=new TextField();
	  label.width=600;
	  label.height=800;
      Lib.current.stage.addChild(this);
	  label.text="";
	  addChild(label);
	  label.text="Loading SO 'nmeTest':";

	  so=SharedObject.getLocal("nmeTest");	  

	  var strData:String=expandAsString(so.data);
	  trace("str data:'"+strData+"'");
	  label.text+=strData;
	  label.text+="\n, Click to save and flush!";

	  Lib.current.stage.addEventListener(MouseEvent.CLICK,onClick);
   }

   public function onClick(inEvent:MouseEvent)
   {
       Reflect.setField(so.data,"name","John Doe");
	   Reflect.setField(so.data,"age","24");
	   so.flush();
	   label.text+="DONE";
   }

   public static function main()
   {
      new Sample();
   }
   
   private static function expandAsString(obj:Dynamic):String
   {
	   if (obj==null)
	   {
		   return null;
	   }
	   
	   var str:String="{";
	   var iter:Iterator<String>=Reflect.fields(obj).iterator();
	   for (i in iter)
	   {
		   str+=i+"="+Reflect.field(obj,i);
		   if (iter.hasNext())
		   {
			   str+=",";
		   }
	   }
	   str+="}";
	   
	   return str;
   }

}
