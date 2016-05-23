class HaxeVer
{
   static macro function getDefine(key : String) : haxe.macro.Expr
       return macro $v{haxe.macro.Context.definedValue(key)};

   #if !macro
   public static function main() Sys.print( getDefine("haxe_ver") );
   #end
}

