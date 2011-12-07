import haxe.io.Input;
import neko.io.Process;

typedef JNIType = { name:String, java:String, arrayCount:Int };

class CreateJNI
{
   static inline var ACC_PUBLIC=0x0001;
   static inline var ACC_PRIVATE=0x0002;
   static inline var ACC_PROTECTED=0x0004;
   static inline var ACC_STATIC=0x0008;
   static inline var ACC_FINAL=0x0010;
   static inline var ACC_SUPER=0x0020;
   static inline var ACC_INTERFACE=0x0200;
   static inline var ACC_ABSTRACT=0x0400;
   static inline var dollars="___";

   static var base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

   var mConstants : Array<Dynamic>;
   var mProcessed:Hash<Bool>;
   var mStack:Array<String>;
   var mOutput:haxe.io.Output;
   var mCurrentType:String;
   var mExactTypes:Hash<Bool>;

   public function new(inClass:String)
   {
      mProcessed = new Hash<Bool>();
      mExactTypes = new Hash<Bool>();
      mProcessed.set(inClass,true);
      mExactTypes.set(inClass,true);
      mProcessed.set("java/lang/Object",true);
      mStack = [ inClass ];

      while(mStack.length>0)
      {
         var clazz = mStack.pop();
         var members = new Hash<String>();
         generate(clazz,members);
      }
   }

   function generate(inClass:String, inMembers:Hash<String>)
   {
      trace(inClass);
      var parts = inClass.split("/");
      var old_type = mCurrentType;
      mCurrentType = parts.join(".");
      mExactTypes.set(mCurrentType,true);
      var dir_parts = parts.slice(0,parts.length-1);
      var outputBase = "gen";
      var dir = outputBase;
      mkdir(dir);
      for(d in dir_parts)
      {
         dir += "/" + d;
         mkdir(dir);
      }
      var filename = "classes/" + parts.join("/") + ".class";
      var source = neko.io.File.read(filename,true);
      var class_name = parts[parts.length-1].split("$").join(dollars);

      var old_output = mOutput;
      mOutput = neko.io.File.write(dir + "/" + class_name +".hx",true);
      var old_constants = mConstants;
      mConstants = new Array<Dynamic>();
      parse(source,inMembers);
      source.close();
      mOutput.close();
      mOutput = old_output;
      mCurrentType = old_type;
      mConstants = old_constants;
   }

   function mkdir(inName:String)
   {
      if (!neko.FileSystem.exists(inName))
         neko.FileSystem.createDirectory(inName);
   }

   function readAttribute(src:Input,inOutputConst:Bool,asString:Bool)
   {
       var name_ref = src.readUInt16();
       debug("   attr:" + mConstants[name_ref]);
       var len = src.readInt31();
       var bytes = haxe.io.Bytes.alloc(len);
       src.readBytes(bytes,0,len);
       if (inOutputConst && mConstants[name_ref]=="ConstantValue")
       {
          var ref = (bytes.get(0)<<8) + bytes.get(1);
          if (asString)
             output(" = \"" + mConstants[mConstants[ref]] + "\"");
          else
             output(" = " + mConstants[ref] );
       }
   }

   function output(str:String)
   {
      mOutput.writeString(str);
   }

   function pushClass(inName:String)
   {
      if (!mProcessed.get(inName))
      {
         mProcessed.set(inName,true);
         mStack.push(inName);
      }
   }

   function processObjectArg(inObj:String,inArrayCount:Int)
   {
      if (inObj=="java.lang.CharSequence" || inObj=="java.lang.String" )
         return "String";
      if ( mExactTypes.exists(inObj) && inArrayCount==0)
         return inObj;
      return "Dynamic /*" + inObj + "*/";
   }

   function outputPackage(cid:Int)
   {
       var name = (mConstants[mConstants[cid]]);
       var parts = name.split("/");
       parts.pop();
       output("package " + parts.join(".") + ";\n");
   }
   function outputClass(cid:Int,lastOnly:Bool)
   {
      var name:String = mConstants[mConstants[cid]];
      //pushClass(name);
      name = name.split("$").join(dollars);
      var parts = name.split("/");
      if (lastOnly)
         output(parts.pop());
      else
         output(parts.join("."));
   }
   var parsedTypes:Array<JNIType>;
   var parsedIsObj:Array<Bool>;

   function addType(inName:String, inJavaType:String, inArrayCount:Int)
   {
      parsedTypes.push( {name:inName, java:inJavaType, arrayCount:inArrayCount} );
   }

   function parseTypes(type:String,inArrayCount:Int)
   {
      if (type=="") return;
      var is_obj = false;
      switch(type.substr(0,1))
      {
         case "[": parseTypes(type.substr(1),inArrayCount+1);
         case "I" : addType("Int","int",inArrayCount);
         case "C" : addType("Int","char",inArrayCount);
         case "S" : addType("Int","short",inArrayCount);
         case "B" : addType("Int","byte",inArrayCount);
         case "V" : addType("Void","void",inArrayCount);
         case "Z" : addType("Bool","boolean",inArrayCount);
         case "J" : addType("Float","long",inArrayCount);
         case "F" : addType("Float","float",inArrayCount);
         case "D" : addType("Float","double",inArrayCount);
         case "L":
            is_obj = true;
            var end = type.indexOf(";");
            if (end<1) throw("Bad object string: "+ type);
            var name = type.substr(1,end-1);
            addType( processObjectArg(name.split("/").join("."),inArrayCount),name,inArrayCount);
            type=type.substr(end);
         default:
            throw("Unknown java type: " + type);
      }
      parsedIsObj.push(is_obj);
      if (type.length>1)
        parseTypes(type.substr(1),0);
   }
   function toHaxeType(inStr:String)
   {
      parsedTypes=[];
      parsedIsObj=[];
      parseTypes(inStr,0);
      return parsedTypes[0];
   }
   static var  fmatch = ~/^\((.*)\)(.*)/;
   var retType:JNIType;

   function splitFunctionType(type:String)
   {
      if (!fmatch.match(type))
         throw("Not a function : " + type);
      var args = fmatch.matched(1);
      retType = toHaxeType(fmatch.matched(2));
      parsedTypes = [];
      parsedIsObj = [];
      parseTypes(args,0);
   }
   function outputType(inType:JNIType)
   {
      for(i in 0...inType.arrayCount)
         output("Array< ");
      output( inType.name );
      for(i in 0...inType.arrayCount)
         output(" >");
   }
   function outputFunctionArgs()
   {
      output("(");
      for(i in 0...parsedTypes.length)
      {
         if (i>0) output(",");
         output("arg" + i + ":" );
         outputType(parsedTypes[i]);
      }
      output(")");
   }

   function javaType(inType)
   {
      var result = inType.java;
      for(i in 0...inType.arrayCount)
         result += "[]";
      return result;
   }

   function nmeCallType(inType)
   {
      if (isJavaObject(inType))
         return "callObjectFunction";
      return "callNumericFunction";
   }



   function isJavaObject(inType)
   {
      if (inType.arrayCount>0)
        return false;
      return switch(inType.name)
      {
         case "Int", "Void", "Bool", "Float" : false;
         default: true;
      }
   }

   function isPOD(inName:String)
   {
      switch(inName)
      {
         case "Int", "Void", "Bool", "Float", "String" : return true;
      }
      return false;
   }


	public static function getHaxelib(library:String):String
   {
		var proc = new Process("haxelib", ["path", library ]);
		var result = "";
		
		try {
			while(true)
         {
				var line = proc.stdout.readLine();
				if (line.substr(0,1) != "-")
					result = line;
			}
			
		} catch (e:Dynamic) { };
		proc.close();
		if (result == "")
			throw ("Could not find haxelib path  " + library + " - perhaps you need to install it?");
		return result;
	}
	





   function parse(src:Input,inMembers:Hash<String>)
   {
      src.bigEndian = true;
      var m0 = src.readByte();
      var m1 = src.readByte();
      var m2 = src.readByte();
      var m3 = src.readByte();
      debug( StringTools.hex(m0,2)+StringTools.hex(m1,2)+
             StringTools.hex(m2,2)+StringTools.hex(m3,2)  );
      debug("Version (min):" + src.readUInt16());
      debug("Version (maj):" + StringTools.hex(src.readUInt16(),4));
      var ccount = src.readUInt16();
      debug("mConstants : " + ccount);
      var cid = 1;
      while(cid<ccount)
      {
         var tag = src.readByte();
         switch(tag)
         {
             case 1:
                var len = src.readUInt16();
                var str = src.readString(len);
                //debug("Str:"+str);
                mConstants[cid] = str;
             case 3:
                var i=src.readInt32();
                //debug("Int32:"+i);
                mConstants[cid] = i;
             case 4:
                var f=src.readFloat();
                //debug("Float32:"+f);
                mConstants[cid] = f;
             case 5:
                var hi=src.readInt32();
                var lo=src.readInt32();
                //debug("Long - ignore");
                mConstants[cid] = {lo:lo, hi:hi};
                cid++;
             case 6:
                var f=src.readDouble();
                //debug("Float64:"+f);
                mConstants[cid] = f;
                cid++;
             case 7:
                var cref = src.readUInt16();
                //debug("Class ref:" + cref);
                mConstants[cid] = cref;
             case 8:
                var sref = src.readUInt16();
                //debug("String ref:" + sref);
                mConstants[cid] = sref;
             case 9,10,11,12:
                var cref = src.readUInt16();
                var type = src.readUInt16();
                //debug("Member ref:" + cref + "," + type);
                mConstants[cid] = {cref:cref, type:type};

             default:
                throw("Unknown constant tag:"+tag);
         }
         cid++;
      }
      var access = src.readUInt16();
      debug("Access: " + access);

      var is_interface =  (access & ACC_INTERFACE)>0;
      var java_out:haxe.io.Output = null;


      var this_ref = src.readUInt16();
      debug("This : " + mConstants[mConstants[this_ref]] );
      outputPackage(this_ref);
      output("class ");
      outputClass(this_ref,true);
      var super_ref = src.readUInt16();
      if (super_ref>0)
      {
         debug("Super : " + mConstants[mConstants[super_ref]]);
         var name = mConstants[mConstants[super_ref]];
         if (name=="java/lang/Object")
         {
             debug(" -> ignore super");
             super_ref = 0;
         }
         else
         {
            output(" extends ");
            outputClass(super_ref,false);
         }
      }
      else
         debug("Super : None.");

      if (super_ref>0)
         generate(mConstants[mConstants[super_ref]], inMembers);

      var intf_count = src.readUInt16();
      debug("Interfaces:" + intf_count);

      for(i in 0...intf_count)
      {
         var i_ref = src.readUInt16();
         /*
          No need to expose these to haxe?
         if (i>0 || super_ref>0)
            output(",");
         output(" implements ");
         outputClass(i_ref,false);
         debug("Implements : " + mConstants[mConstants[i_ref]]);
         */
      }

      output("\n{\n");
      if (super_ref==0)
         output("   var __jobject:Dynamic;\n\n");

      var java_name = "";

      if (is_interface)
      {
         var dir = "stubs";
         var parts = mCurrentType.split(".");
         var dir_parts = parts.slice(0,parts.length-1);
         mkdir(dir);
         for(d in dir_parts)
         {
            dir += "/" + d;
            mkdir(dir);
         }
         var interface_name = parts[parts.length-1];
         var impl_name = "Haxe" + parts[parts.length-1].split("$").join("");
         java_name = dir_parts.join("/") + "/" + impl_name +".java";
         java_out = neko.io.File.write("stubs/" + java_name,true);
         java_out.writeString("package " + dir_parts.join(".") + ";\n");
         java_out.writeString("import org.haxe.nme.Value;\n");
         java_out.writeString("import org.haxe.nme.NME;\n\n");
         java_out.writeString("class " + impl_name + " implements " +
            interface_name.split("$").join(".") + " {\n");
         java_out.writeString("   long __haxeHandle;\n");
         java_out.writeString("   public " + impl_name + "(long inHandle) { __haxeHandle=inHandle; }\n");

         output("   public function new() { __jobject = nme.JNI.createInterface(this,\"" +
             dir_parts.join(".") + "." + impl_name + "\", classDef ); }\n\n" );
      }
 


      var field_count = src.readUInt16();
      debug("Fields:" + field_count);
      var seen = new Hash<Bool>();

      for(i in 0...field_count)
      {
         var access = src.readUInt16();
         var name_ref = src.readUInt16();
         debug(" field : " + mConstants[name_ref]);
         var desc_ref = src.readUInt16();
         debug("  desc : " + mConstants[desc_ref]);

         var expose = access == (ACC_PUBLIC|ACC_FINAL|ACC_STATIC);
         var as_string = false;
         if (expose)
         {
            var type = toHaxeType(mConstants[desc_ref]).name;
            if (isPOD(type))
            {
               output("   static inline public var " + mConstants[name_ref] + ":" + type );
               as_string = type=="String";
            }
            else
               expose = false;
         }
         var att_count = src.readUInt16();
         for(a in 0...att_count)
         {
            readAttribute(src,expose,as_string);
         }
         if (expose)
            output(";\n");
      }

      var method_count = src.readUInt16();
      debug("Method:" + method_count);

      output("\n");
      var constructed = false;
      for(i in 0...method_count)
      {
         var access = src.readUInt16();
         var expose = (access&ACC_PUBLIC)>0;
         var is_static = (access&ACC_STATIC)>0;
         var name_ref = src.readUInt16();
         debug(" method: " + mConstants[name_ref]);
         var desc_ref = src.readUInt16();

         var func_name = mConstants[name_ref];
         var constructor = func_name=="<init>";

         if (expose)
         {
            debug("  desc : " + mConstants[desc_ref]);
            splitFunctionType(mConstants[desc_ref]);
   
            var func_key = func_name + " " + mConstants[desc_ref];
            if (constructor)
            {
               func_name = "_create";
            }
   
            // Method overloading ...
            var uniq_name = func_name;
            var do_override = "";
            if (inMembers.exists(func_key))
            {
               uniq_name = inMembers.get(func_key);
               if (!constructor && !is_static)
                  do_override = "override ";
               seen.set(uniq_name,true);
            }
            else
            {
               if (seen.exists(func_name))
               {
                  for(i in 1...100000)
                  {
                     uniq_name = func_name + i;
                     if (!seen.exists(uniq_name))
                        break;
                  }
               }
               seen.set(uniq_name,true);
               inMembers.set(func_key, uniq_name);
            }

            if (constructor)
                is_static = true;
            var ret_full_class = constructor ||
                ( ( mExactTypes.exists(retType.name) || isPOD(retType.name)) && retType.arrayCount==0);
            if (constructor)
                retType = { name:mCurrentType, java:mCurrentType, arrayCount:0 };
            var ret_void = (retType.name=="Void" && retType.arrayCount==0);


            if (is_interface)
            {
               java_out.writeString("   @Override public " + javaType(retType) + " " +
                        func_name + "(" );
               for(i in 0...parsedTypes.length)
               {
                  if (i>0) output(",");
                  java_out.writeString( javaType(parsedTypes[i]) + " arg" + i);
               }
               java_out.writeString(") {\n");
               if (parsedTypes.length>0)
                  java_out.writeString( "      Object [] args = new Object["+parsedTypes.length+"];\n");
               else
                  java_out.writeString( "      Object [] args = null;\n");

               for(i in 0...parsedTypes.length)
               {
                  if (isJavaObject(parsedTypes[i]))
                     java_out.writeString("      args["+i+"] = arg" + i + ";\n" );
                  else
                     java_out.writeString("      args["+i+"] = new Value(arg" + i + ");\n" );
               }
  
               if (!ret_void)
                  java_out.writeString("      return (" + javaType(retType) + ")" );

               java_out.writeString("      NME." + nmeCallType(retType) + "(__haxeHandle,\"" +
                       uniq_name + "\",args)" );

               if (!ret_void)
                  java_out.writeString(")");
               java_out.writeString(";\n   }\n");


               output("   public function " + uniq_name );
               outputFunctionArgs();
               output(" : ");
                if (ret_full_class)
                  outputType(retType);
               else
                  output("Dynamic");
               output(" { return null; }\n");
            }
            else
            {
               output("   static var _" + uniq_name + "_func:Dynamic;\n");
               output("   public ");
               if (is_static || constructor)
                 output("static ");
               output(do_override + "function " + uniq_name );
               outputFunctionArgs();
               output(" : ");
   
               if (ret_full_class)
                  outputType(retType);
               else
                  output("Dynamic");
   
               output("\n");
               output("   {\n");
               func_name = "_" + uniq_name + "_func";
               output("      if (" + func_name + "==null)\n");
               output("         " + func_name + "=nme.JNI." +
                     (is_static?"createStaticMethod":"createMemberMethod") );
   
               output("(\"" + mCurrentType + "\",\"" + mConstants[name_ref] + "\",\"" +
                     mConstants[desc_ref] + "\");\n");
   
               output("      var a = new Array<Dynamic>();\n");
               for(i in 0...parsedTypes.length)
                  output("      a.push(arg" + i + ");\n");
  
               if (ret_void)
                  output("      ");
               else if (ret_full_class && !isPOD(retType.name) )
                  output("      return new " + retType.name + "(");
               else
                  output("      return ");
   
               if (is_static)
                  output("nme.JNI.callStatic(" + func_name + ",a)");
               else
                  output("nme.JNI.callMember(" + func_name + ",__jobject,a)");
   
               if (ret_full_class && !isPOD(retType.name) )
                  output(");\n");
               else
                  output(";\n");
   
               output("   }\n\n");
            }
         }

         if (constructor && !constructed)
         {
            constructed = true;
             output("   public function new(handle:Dynamic) { ");
             if (super_ref>0)
                output("super(handle);");
             else
                output("__jobject = handle;");
             output(" }\n");
         }

         var att_count = src.readUInt16();
         for(a in 0...att_count)
             readAttribute(src,false,false);
      }
 

      if (java_out!=null)
      {
         java_out.writeString("}\n");
         java_out.close();

         mkdir("compiled");
         var nme_path = getHaxelib("nme") + "/tools/command-line/android/template/src";
         neko.Sys.command( "javac", [ "-cp", "classes/android.jar",  "-sourcepath", 
            nme_path, "-d", "compiled", "stubs/" + java_name ] );


         neko.Sys.setCwd("compiled");

         var class_name =  java_name.substr(0,java_name.length-4) + "class";

         var dx = neko.Sys.getEnv("ANDROID_SDK") + "/platforms/android-7/tools/dx";

         neko.Sys.command(dx, [ "--dex", "--output=classes.jar", class_name ] );

         var class_def = neko.io.File.getBytes("classes.jar");

         class_def = neko.zip.Compress.run(class_def,9);

         var class_str = haxe.BaseCode.encode(class_def.toString(),base64);

         output("\n   static var classDef = \"" + class_str + "\";\n");
      }

      output("}\n");
   }

   static function debug(s:String) {  }

   public static function main()
   {
      var args = neko.Sys.args();
      debug(args.toString());


      new CreateJNI(args[0]);

   }
}
