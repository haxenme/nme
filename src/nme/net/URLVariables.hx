package nme.net;

#if (!flash)

class URLVariablesBase
{
   var fields:Map<String,String>;

   public function new(?inEncoded:String) 
   {
      if (inEncoded != null)
         decode(inEncoded);
      else
         fields = new Map();
   }

   public function decode(inVars:String) 
   {
      fields = new Map();

      var fieldStrings = inVars.split(";").join("&").split("&");

      for(f in fieldStrings) 
      {
         var eq = f.indexOf("=");

         if (eq > 0)
            fields.set(StringTools.urlDecode(f.substr(0, eq)), StringTools.urlDecode(f.substr(eq + 1)));
         else if (eq != 0)
            fields.set(StringTools.urlDecode(f), "");
      }
   }

   public function set(name:String, value:String) : String
   {
      fields.set(name,value);
      return value;
   }

   public function get(name:String):String
   {
      return fields.get(name);
   }

   public function toString():String 
   {
      var result = new Array<String>();

      for(f in fields.keys())
         result.push(StringTools.urlEncode(f) + "=" + StringTools.urlEncode(fields.get(f)));

      return result.join("&");
   }
}

@:forward(decode,toString)
abstract URLVariables(URLVariablesBase)
{
   public function new(?inEncoded:String)
   {
      this = new URLVariablesBase(inEncoded);
   }
   @:resolve
   public function set(name:String, value:String) : String
   {
      return this.set(name,value);
   }

   @:resolve
   public function get(name:String):String
   {
      return this.get(name);
   }
}


#else
typedef URLVariables = flash.net.URLVariables;

typedef URLVariablesBase = flash.net.URLVariables;
#end
