package nme.text;
#if code_completion


@:fakeEnum(String) extern enum AntiAliasType {
	ADVANCED;
	NORMAL;
}


#elseif (cpp || neko)
typedef AntiAliasType = neash.text.AntiAliasType;
#elseif js
typedef AntiAliasType = jeash.text.AntiAliasType;
#else
typedef AntiAliasType = flash.text.AntiAliasType;
#end