import cpp.cppia.HostClasses;

import nme.display.Sprite;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.script.Server;
import nme.geom.Point;
import nme.Assets;
import nme.utils.ByteArray;
import gm2d.Screen;
import nme.geom.Rectangle;
import gm2d.ui.Layout;
import gm2d.ui.TextLabel;
import gm2d.ui.TileControl;
import gm2d.ui.Widget;
import gm2d.ui.Button;
import gm2d.ui.TextInput;
import gm2d.ui.CheckButtons;
import gm2d.ui.Image;
import gm2d.ui.ListControl;
import gm2d.skin.FillStyle;
import gm2d.skin.LineStyle;
import gm2d.skin.Shape;
import gm2d.skin.Skin;
import gm2d.svg.Svg;
import gm2d.svg.SvgRenderer;
import sys.FileSystem;
import nme.net.SharedObject;
import sys.io.File;

using  StringTools;

class AcadnmeBoot extends Screen implements IBoot
{
   var defaultDir:String;
   var tileCtrl:TileControl;
   var launchScript:Map<String,String>;
   var serverPassword:String;
   var serverEnabled:Bool;
   var store:SharedObject;
   var storeData:Dynamic;
   var nmeVersion:String;

   public function new()
   {
      super();

      Acadnme.boot = this;

      store = SharedObject.getLocal("acadnme-server");
      storeData = store.data;

      serverPassword = storeData.serverPassword ==null ? "" : storeData.serverPassword;
      serverEnabled = storeData.serverEnabled==null ? true : storeData.serverEnabled;
      Server.setEnabled(serverEnabled);
      Server.setPassword(serverPassword);


      Server.functions["launch"] = launch;
      Server.functions["apps"] = apps;
      Server.functions["uninstall"] =  uninstall;
      Server.functions["reload"] =  reloadSync;
      defaultDir = getDefaultDir();

      var pad = Skin.scale(2);
      Skin.guiLight = 0xf0f0f0;
      Skin.guiDark = 0xa0a0a0;
      Skin.replaceAttribs("DialogTitle", {
          align: Layout.AlignStretch | Layout.AlignCenterY,
          textAlign: "left",
          fontSize: Skin.scale(20),
          padding: new Rectangle(pad,pad,pad*2,pad*2),
          shape: ShapeUnderlineRect,
          fill: FillSolid(0xffffff,1),
          line: LineSolid(1,0xFF9800,2),
        });

      setItemLayout( new VerticalLayout([0,1]).stretch() );

      var titleBar = new Widget(["AppBar"], {  fill: FillSolid(0xFF9800,1) }  );
      titleBar.setItemLayout( new VerticalLayout().stretch() );
      addWidget(titleBar);

      nmeVersion = Acadnme.getNmeVersion();

      var titleText = "Acadnme v" + nmeVersion;

      var accent = 0xFFF3E0;
      titleBar.addWidget( new TextLabel(titleText,{ textColor:0xffffff, fontSize:Skin.scale(24), bold:true, align:Layout.AlignCenterX|Layout.AlignTop }) );
      titleBar.addWidget(new TextLabel(defaultDir,{ textColor:accent, align: Layout.AlignCenterY|Layout.AlignLeft }) );


       var hostBar = new Widget({ align:Layout.AlignCenterY  });
       hostBar.setItemLayout( new HorizontalLayout([1,0]).stretch() );

       hostBar.addWidget(new TextLabel("Host:" + getConnectionStatus(),{ textColor:accent, align:Layout.AlignCenterY|Layout.AlignStretch }) );
       hostBar.addWidget( Button.BMPButton( createMenuIcon(), onMenu, { shape:ShapeNone } ) );
       hostBar.build();

       titleBar.addWidget(hostBar);
       titleBar.build();


      tileCtrl = new TileControl(["Stretch"], { padding:new Rectangle(10,0,20,10), columnWidth:400});
      fillList();
      addWidget(tileCtrl);

      build();
      makeCurrent();
   }

   function onEnable(inValue:Bool)
   {
      serverEnabled = inValue;
      Server.setEnabled(inValue);
      Reflect.setField(storeData, "serverEnabled", inValue);
      store.flush();
   }

   function onPassword(inPassword:String)
   {
      serverPassword = inPassword;
      Server.setPassword(inPassword);
      Reflect.setField(storeData, "serverPassword", inPassword);
      store.flush();
   }

   function onMenu()
   {
      var panel = new gm2d.ui.Panel("Settings");
      panel.addLabelUI("Enable Network", new CheckButtons(serverEnabled, onEnable) );
      panel.addLabelUI("Network Password", new TextInput(serverPassword, onPassword) );
      panel.addTextButton("Ok", function() { gm2d.Game.closeDialog(); } );
      panel.showDialog(true, { chromeButtons:[] } );
   }

   function createMenuIcon()
   {
      var gap = Skin.scale(1);
      var bar = Skin.scale(2);
      var size = gap * 6+bar*5;
      var bmp = new BitmapData(size,size, true, 0x0);
      var y = gap;
      var shape = new nme.display.Shape();
      var gfx = shape.graphics;
      gfx.beginFill(0xffffff);
      for(r in 0...3)
      {
         gfx.drawRect(1,y,size-1,bar);
         y+= gap*2 + bar;
      }
      bmp.draw(shape);
      return bmp;
   }


   function uninstall(app:String)
   {
      var path = launchScript.get(app);
      if (path!=null)
          return uninstallScript(path);
      if (path==null)
      {
         for(k in launchScript.keys())
         {
            var parts = k.split(".");
            if (parts[ parts.length-1 ]==app)
                return uninstallScript( launchScript.get(k) );
         }
      }
      return 'Unknown application $app';
   }


   function launch(name:String) : String
   {
      if (name=="" || name==null)
         return "usage : launch appName";

      var path = launchScript.get(name);
      if (path==null)
      {
         for(k in launchScript.keys())
         {
            var parts = k.split(".");
            if (parts[ parts.length-1 ]==name)
                path = launchScript[k];
         }
      }
      if (path==null)
         return 'Unknown application $name';
      haxe.Timer.delay( function() Acadnme.runScript(path), 0 );
      return "launched...";
   };


   function apps() : String
   {
      var result = new Array<String>();
      for(k in launchScript.keys())
         result.push(k + " (" + launchScript.get(k) + ")" );

      return result.join("\n");
   }


   public static function removeRecurse(directory:String):Void 
   {
      if (FileSystem.exists(directory)) 
      {
         for(file in FileSystem.readDirectory(directory)) 
         {
            var path = directory + "/" + file;

            if (FileSystem.isDirectory(path)) 
               removeRecurse(path);
            else
               FileSystem.deleteFile(path);
         }
         FileSystem.deleteDirectory(directory);
      }
   }


   public function uninstallScript(path:String) : String
   {
      if (!haxe.io.Path.isAbsolute(path))
         return "Can' uninstall built-in app " + path;

      try
      {
         if (path.endsWith(".nme"))
         {
            FileSystem.deleteFile(path);
            return reloadSync();
         }
         else if (path.endsWith(".cppia"))
         {
            var dir = haxe.io.Path.directory(path);
            removeRecurse(dir);
            return reloadSync();
         }
      }
      catch(e:Dynamic)
      {
         return "Error uninstalling " + path + ":" + e;
      }

      return "Unknown uninstall type " + path;
   }

   public function onConnect()
   {
   }


   public function getDefaultDir():String
   {
      return Acadnme.directory;
   }


   public function getConnectionStatus():String
   {
      return Acadnme.connectionStatus;
   }

   public function remove()
   {
      gm2d.Game.destroy();
   }

   public function reloadSync()
   {
      haxe.Timer.delay( function() {
         fillList();
         relayout();
         }, 0);
      return "ok";
   }

   public function onSelect(path:String):Void
   {
      if (path!=null)
         Acadnme.runScript(path);
   }

   function addNmeApp(appName:String, details:Dynamic,path:String)
   {
      if (details!=null)
      {
         var bitmap:Widget = null;
         if (details.bmpIcon!=null)
         {
            var bmp:BitmapData = details.bmpIcon;
            if (bmp!=null && bmp.width>0 && bmp.height>0)
            {
               var size = gm2d.skin.Skin.scale(48);
               var square = new BitmapData(size,size,true,0x00000000);
               var bitmapDraw = new Bitmap(bmp);
               var scale = new nme.geom.Matrix();
               scale.a = size/bmp.width;
               scale.d = size/bmp.height;
               square.draw( bitmapDraw, scale );
               bitmap = new Image(square, { padding:3, wantsFocus:false } );
            }
         }
         else if (details.svgIcon!=null)
            bitmap = createSvgBmp( details.svgIcon );

         if (bitmap==null)
            bitmap = createSvgBmp( Assets.getString("default.svg") );

         var idx = 0;
         while(true)
         {
            var key = idx==0 ? appName : appName + "." + idx;
            if (!launchScript.exists(key))
            {
               launchScript[key] = path;
               break;
            }
            idx++;
         }

         var disabled = getVersionError(details.nme);

         tileCtrl.add(createDetails(bitmap, defaultDir,details.name,details.developer, disabled, path));
      }
   }

   public function getVersionError(version:String) : String
   {
      if (version==null)
         return "No version";

      var parts = version.split(".");
      if (parts.length!=3)
         return "Bad version format :" + version;
      var nmeParts = nmeVersion.split(".");
      if (parts[0]!=nmeParts[0])
         return "Bad major version : " + parts[0];

      // check minor?
      return null;
   }


   public function fillList()
   {
      launchScript = new Map<String, String>();
      tileCtrl.clear();


      // User apps first...
      try
      {
         for( name in FileSystem.readDirectory(defaultDir))
         {
            var title = name;
            var path = defaultDir + "/" +name;
            var disabled = "No manifest";
            var developer = "unknown";
            var bitmap:Widget = null;
            var header:Dynamic = null;
            var script:String = null;

            if (sys.FileSystem.isDirectory(path))
            {
               script = path+"/ScriptMain.cppia";
               if (!FileSystem.exists(script))
                  continue;

               var manifest = path+"/manifest.json";
               if (FileSystem.exists(manifest))
               {
                  disabled = "Bad manifest";
                  try
                  {
                     var content = File.getContent(manifest);
                     header = haxe.Json.parse(content);
                  }
                  catch(e:Dynamic) { }
               }
            }
            else
            {
               if (!StringTools.endsWith(name,".nme"))
                  continue;

               script = path;
               disabled = "Bad manifest";
               header = nme.script.Nme.getFileHeader(path);
            }

            if (header!=null)
            {
               disabled = null;

               if (header.svgIcon!=null)
               {
                  bitmap = createSvgBmp(header.svgIcon);
               }
               else if (header.bmpIcon!=null)
               {
                  var bytes = haxe.crypto.Base64.decode(header.bmpIcon);
                  bitmap = createBmp(bytes);
               }

               if (header.developer!=null)
                  developer = "developer:" + header.developer;

               if (header.name!=null)
                  title = header.name;

               disabled = getVersionError(header.nme);
            }

            if (bitmap==null)
               bitmap = createSvgBmp( Assets.getString("default.svg") );

            var path = disabled==null ? script : null;
            if (path!=null)
               launchScript[name] = path;

            tileCtrl.add(createDetails(bitmap, path,title,developer,disabled, path));
         }
      }
      catch(e:Dynamic)
      {
      }



      // Distributed apps
      var nmeDir = Acadnme.getNmeAppsDir();
      if (nmeDir!=null)
      {
         try
         {
            for(app in FileSystem.readDirectory(nmeDir))
            {
               if (app.endsWith(".nme") && app!="AcadnmeBoot.nme" )
               {
                  var nmePath =  nmeDir + "/" + app;
                  var details = nme.script.Nme.getFileHeader(nmePath);
                  addNmeApp(app,details,nmePath);
               }
            }
         }
         catch(e:Dynamic) { }
      }

      // Build-in apps
      var assets = nme.Assets.info;
      for(asset in assets.keys())
      {
         if (asset.endsWith(".nme") && asset!="AcadnmeBoot.nme")
         {
            if (nme.Assets.hasBytes(asset))
            {
               var bytes = nme.Assets.getBytes(asset);
               if (bytes==null)
                  trace("No bytes for " + asset + "?");
               else
               {
                  var details = nme.script.Nme.getBytesHeader( nme.Assets.getBytes(asset) );
                  addNmeApp(asset,details,asset);
               }
            }
         }
      }
   }

   public function createDetails(bitmap:Widget, dir:String, name:String, developer:String, inDisabled:String, path:String)
   {
      var result = new gm2d.ui.Control(["SimpleTile"],{ onEnter:function() onSelect(path), onClick:function() onSelect(path) } );
      result.addChild(bitmap);
      var row = new HorizontalLayout();
      row.add(bitmap.getLayout());

      var layout = new VerticalLayout();
      layout.setAlignment(Layout.AlignLeft|Layout.AlignCenterY);
      row.add(layout);

      var text = new TextLabel(name,{bold:true});
      result.addChild(text);
      layout.add(text.getLayout().setAlignment(Layout.AlignLeft));

      var text = new TextLabel("  " + (inDisabled!=null ? inDisabled : developer) );
      result.addChild(text);
      layout.add(text.getLayout().setAlignment(Layout.AlignLeft));

      result.setItemLayout( row.setAlignment(Layout.AlignLeft|Layout.AlignCenterY) );
      result.getLayout().stretch();
      result.build();

      return result;
   }

   public function createBmp(bytes:haxe.io.Bytes) : Widget
   {
      //var bmp = renderer.renderBitmap( new Rectangle(0,0,size/scale,size/scale), scale );
      //return new Image(bmp, { padding:3, wantsFocus:false } );
      return null;
   }

   public function createSvgBmp(inSrc:String) : Widget
   {
      try
      {
         var xml = Xml.parse(inSrc);
         var svg = new Svg(xml);
         var renderer = new SvgRenderer(svg);
         var w = renderer.width;
         var h = renderer.height;
         if (w==0 || h==0)
            return null;

         var size = gm2d.skin.Skin.scale(48);
         var sx = size/w;
         var sh = size/h;
         var scale = Math.min(sx,sh);
         var bmp = renderer.renderBitmap( new Rectangle(0,0,size/scale,size/scale), scale );
         return new Image(bmp, { padding:3, wantsFocus:false } );
      }
      catch(e:Dynamic) { }
      return null;
   }


   public function browse()
   {
      gm2d.ui.FileOpen.load("Select Cppia File", function(name:String, bytes:ByteArray)
         {
            if (bytes!= null)
            {
            }
         }, "Cppia Script Files|*.cppia");

   }
}



