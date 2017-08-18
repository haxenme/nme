class ParseNme
{
   public static function parseNme() : String
   {
      var module:Dynamic = untyped window.Module;
      var data:js.html.ArrayBuffer = module.nmeApp;
      return "alert('parsed " + (data.byteLength) + "');";
   }

   public static function main()
   {
      (untyped window).parseNme = parseNme;
   }
}
