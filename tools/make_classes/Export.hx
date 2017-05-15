import ImportAll;

@:build(CreateExports.init())
class Export
{
   public static function main()
   {
      var classes = untyped __js__("$hxClasses['package']");
      ImportAll.main(classes);
      untyped __js__("$global['hxClasses'] = $hxClasses");
   }
}
