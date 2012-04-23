package format.swf.data;


class Tags {
	
	
	public static var End:Int = 00;
	public static var ShowFrame:Int = 01;
	public static var DefineShape:Int = 02;
	public static var FreeCharacter:Int = 03;
	public static var PlaceObject:Int = 04;
	public static var RemoveObject:Int = 05;
	public static var DefineBits:Int = 06;
	public static var DefineButton:Int = 07;
	public static var JPEGTables:Int = 08;
	public static var SetBackgroundColor:Int = 09;
	
	public static var DefineFont:Int = 10;
	public static var DefineText:Int = 11;
	public static var DoAction:Int = 12;
	public static var DefineFontInfo:Int = 13;
	
	public static var DefineSound:Int = 14;
	public static var StartSound:Int = 15;
	public static var StopSound:Int = 16;
	
	public static var DefineButtonSound:Int = 17;
	
	public static var SoundStreamHead:Int = 18;
	public static var SoundStreamBlock:Int = 19;
	
	public static var DefineBitsLossless:Int = 20;
	public static var DefineBitsJPEG2:Int = 21;
	
	public static var DefineShape2:Int = 22;
	public static var DefineButtonCxform:Int = 23;
	
	public static var Protect:Int = 24;
	
	public static var PathsArePostScript:Int = 25;
	
	public static var PlaceObject2:Int = 26;
	public static var c27:Int = 27;
	public static var RemoveObject2:Int = 28;
	
	public static var SyncFrame:Int = 29;
	public static var c30:Int = 30;
	public static var FreeAll:Int = 31;
	
	public static var DefineShape3:Int = 32;
	public static var DefineText2:Int = 33;
	public static var DefineButton2:Int = 34;
	public static var DefineBitsJPEG3:Int = 35;
	public static var DefineBitsLossless2:Int = 36;
	public static var DefineEditText:Int = 37;
	
	public static var DefineVideo:Int = 38;
	
	public static var DefineSprite:Int = 39;
	public static var NameCharacter:Int = 40;
	public static var ProductInfo:Int = 41;
	public static var DefineTextFormat:Int = 42;
	public static var FrameLabel:Int = 43;
	public static var DefineBehavior:Int = 44;
	public static var SoundStreamHead2:Int = 45;
	public static var DefineMorphShape:Int = 46;
	public static var FrameTag:Int = 47;
	public static var DefineFont2:Int = 48;
	public static var GenCommand:Int = 49;
	public static var DefineCommandObj:Int = 50;
	public static var CharacterSet:Int = 51;
	public static var FontRef:Int = 52;
	
	public static var DefineFunction:Int = 53;
	public static var PlaceFunction:Int = 54;
	
	public static var GenTagObject:Int = 55;
	
	public static var ExportAssets:Int = 56;
	public static var ImportAssets:Int = 57;
	
	public static var EnableDebugger:Int = 58;
	
	public static var DoInitAction:Int = 59;
	public static var DefineVideoStream:Int = 60;
	public static var VideoFrame:Int = 61;
	
	public static var DefineFontInfo2:Int = 62;
	public static var DebugID:Int = 63;
	public static var EnableDebugger2:Int = 64;
	public static var ScriptLimits:Int = 65;
	
	public static var SetTabIndex:Int = 66;
	
	public static var DefineShape4_hmm:Int = 67;
	public static var c68:Int = 68;
	
	public static var FileAttributes:Int = 69;
	
	public static var PlaceObject3:Int = 70;
	public static var ImportAssets2:Int = 71;
	
	public static var DoABC:Int = 72;
	public static var DefineFontAlignZones:Int = 73;
	public static var CSMTextSettings:Int = 74;
	public static var DefineFont3:Int = 75;
	public static var SymbolClass:Int = 76;
	public static var MetaData:Int = 77;
	public static var DefineScalingGrid:Int = 78;
	public static var c79:Int = 79;
	public static var c80:Int = 80;
	public static var c81:Int = 81;
	public static var DoABC2:Int = 82;
	public static var DefineShape4:Int = 83;
	public static var DefineMorphShape2:Int = 84;
	public static var c85:Int = 85;
	public static var DefineSceneAndFrameLabelData:Int = 86;
	public static var DefineBinaryData:Int = 87;
	public static var DefineFontName:Int = 88;
	public static var StartSound2:Int = 89;
	
	
	public static var LAST:Int = 90;
	
	
	private static var tags:Array <String> = [
		"End",               // 00
		"ShowFrame",         // 01
		"DefineShape",         // 02
		"FreeCharacter",      // 03
		"PlaceObject",         // 04
		"RemoveObject",         // 05
		"DefineBits",         // 06
		"DefineButton",         // 07
		"JPEGTables",         // 08
		"SetBackgroundColor",   // 09

		"DefineFont",         // 10
		"DefineText",         // 11
		"DoAction",            // 12
		"DefineFontInfo",      // 13

		"DefineSound",         // 14
		"StartSound",         // 15
		"StopSound",         // 16

		"DefineButtonSound",   // 17

		"SoundStreamHead",      // 18
		"SoundStreamBlock",      // 19

		"DefineBitsLossless",   // 20
		"DefineBitsJPEG2",      // 21

		"DefineShape2",         // 22
		"DefineButtonCxform",   // 23

		"Protect",            // 24

		"PathsArePostScript",   // 25

		"PlaceObject2",         // 26
		"27 (invalid)",         // 27
		"RemoveObject2",      // 28

		"SyncFrame",         // 29
		"30 (invalid)",         // 30
		"FreeAll",            // 31

		"DefineShape3",         // 32
		"DefineText2",         // 33
		"DefineButton2",      // 34
		"DefineBitsJPEG3",      // 35
		"DefineBitsLossless2",   // 36
		"DefineEditText",      // 37

		"DefineVideo",         // 38

		"DefineSprite",         // 39
		"NameCharacter",      // 40
		"ProductInfo",         // 41
		"DefineTextFormat",      // 42
		"FrameLabel",         // 43
		"DefineBehavior",      // 44
		"SoundStreamHead2",      // 45
		"DefineMorphShape",      // 46
		"FrameTag",            // 47
		"DefineFont2",         // 48
		"GenCommand",         // 49
		"DefineCommandObj",      // 50
		"CharacterSet",         // 51
		"FontRef",            // 52

		"DefineFunction",      // 53
		"PlaceFunction",      // 54

		"GenTagObject",         // 55

		"ExportAssets",         // 56
		"ImportAssets",         // 57

		"EnableDebugger",      // 58

		"DoInitAction",         // 59
		"DefineVideoStream",   // 60
		"VideoFrame",         // 61

		"DefineFontInfo2",      // 62
		"DebugID",             // 63
		"EnableDebugger2",       // 64
		"ScriptLimits",       // 65

		"SetTabIndex",          // 66

		"DefineShape4",       // 67
		"DefineMorphShape2",    // 68

		"FileAttributes",       // 69

		"PlaceObject3",       // 70
		"ImportAssets2",       // 71

		"DoABC",             // 72
		"DefineFontAlignZones",         // 73
		"CSMTextSettings",         // 74
		"DefineFont3",         // 75
		"SymbolClass",         // 76
		"Metadata",         // 77
		"DefineScalingGrid",         // 78
		"79 (invalid)",         // 79
		"80 (invalid)",         // 80
		"81 (invalid)",         // 81
		"DoABC2",               // 82
		"DefineShape4",         // 83
		"DefineMorphShape2",         // 84
		"c85", // 85
		"DefineSceneAndFrameLabelData", // 86
		"DefineBinaryData", //  87
		"DefineFontName", //  88
		"StartSound2", // 89
		"LAST", // 90
	];
	
	static public function string(i:Int) { return tags[i]; }
	
	
}