import cpp.cppia.HostClasses;

import nme.display.*;
import nme.script.Server;
import nme.geom.Point;
import nme.Assets;
import nme.utils.ByteArray;
import gm2d.Screen;
import nme.geom.Rectangle;
import gm2d.ui.Layout;
import gm2d.ui.*;
import gm2d.skin.FillStyle;
import gm2d.skin.LineStyle;
import gm2d.skin.Shape;
import gm2d.skin.Skin;
import gm2d.svg.Svg;
import gm2d.svg.SvgRenderer;
import gm2d.Game;
import sys.FileSystem;
import nme.net.*;
import nme.events.*;
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
   var button:Button;
   var nmeVersion:String;
   var isWeb:Bool;
   var listenStage:Stage;

   public function new()
   {
      super();

      Acadnme.boot = this;

      var url = nme.Lib.getWebpageUrl();
      isWeb = url!=null;

      if (!isWeb)
      {
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
      }

      var skin = new gm2d.skin.Skin(false);
      var pad = skin.scale(2);
      skin.guiLight = 0xf0f0f0;
      skin.guiDark = 0xa0a0a0;
      skin.init();
      skin.replaceAttribs("DialogTitle", {
          align: Layout.AlignStretch | Layout.AlignCenterY,
          textAlign: "left",
          fontSize: skin.scale(20),
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
      titleBar.addWidget( new TextLabel(titleText,{ textColor:0xffffff, fontSize:skin.scale(24), bold:true, align:Layout.AlignCenterX|Layout.AlignTop }) );
      titleBar.addWidget(new TextLabel(defaultDir,{ textColor:accent, align: Layout.AlignCenterY|Layout.AlignLeft }) );


       var hostBar = new Widget({ align:Layout.AlignCenterY  });
       hostBar.setItemLayout( new HorizontalLayout([1,0]).stretch() );

       if (!isWeb)
       {
          hostBar.addWidget(new TextLabel("Host:" + getConnectionStatus(),{ textColor:accent, align:Layout.AlignCenterY|Layout.AlignStretch }) );
          hostBar.addWidget( button = Button.BMPButton( createMenuIcon(), onMenu, { shape:ShapeNone } ) );
       }
       else
       {
          hostBar.addWidget(new TextLabel("",{ textColor:accent, align:Layout.AlignCenterY|Layout.AlignStretch }) );
          hostBar.addWidget( button = Button.TextButton( "Load .nme file", onMenu, {
              textColor:0xffffff,
              //line:LineSolid(1,0xff0000,1),
              line:LineNone,
              //fill:FillSolid(0xffffff,0.25),
              fill:FillSolid(0xffa080,1),
              shape:ShapeRoundRect,
              margin:pad,
          } ) );
       }

       hostBar.build();

       titleBar.addWidget(hostBar);
       titleBar.build();


      if (isWeb)
      {
         var tl = new TextLabel("Welcome To NME!", {
               multiline:true,
               wordwrap:true,
               itemAlign:Layout.AlignTop,
            }
         );
         var tf = tl.getLabel();
         tf.htmlText = [
            "<br>",
            "<font size='32'><b>Welcome To NME!</b></font>",
            "<br>",
            "1. Compile your programs with <u>NME</u>.",
            "<br>",
            "   <i>nme cppia installer</i>",
            "<br>",
            "2. Run your .nme files using the button in the title bar!",
            "<br>",
         ].join("\n");
         addChild(tf);
         var b = skin.scale(10);
         var layout = new TextLayout(tf).setBorders(b,b,b,b).stretch();
         getItemLayout().add(layout);
      }
      else
      {
         tileCtrl = new TileControl(["Stretch"], { padding:new Rectangle(10,0,20,10), columnWidth:400});
         fillList();
         addWidget(tileCtrl);
         addListeners();
      }

      build();
      makeCurrent();

      /*
      CORS issues here 
      if (isWeb)
      {
         var q = nme.Lib.getWebpageParam("prog");
         if (q!=null && q!="")
            downloadAndRun(q);
      }
      */
   }

   function onDropFiles(e:DropEvent)
   {
      var items = e.items;
      if (items!=null && items.length==1)
      {
         launch(items[0]);
      }
   }

   function addListeners()
   {
      listenStage = stage;
      listenStage.addEventListener(DropEvent.DROP_FILES, onDropFiles);
   }

   function removeListeners()
   {
      if (listenStage!=null)
      {
         listenStage.removeEventListener(DropEvent.DROP_FILES, onDropFiles);
         listenStage = null;
      }
   }


   function downloadAndRun(url:String)
   {
      var loader = new URLLoader();
      loader.dataFormat = URLLoaderDataFormat.BINARY;

      var status:String = null;
      var progress = ProgressDialog.create("Download", url, status, 100.0, () -> {
         if (loader!=null)
         {
            loader = null;
         }
      } );
      progress.show(true,false);
      loader.addEventListener( Event.COMPLETE, (_) -> {
         Game.closeDialog();
         if (loader!=null)
         {
            var bytes:ByteArray = loader.data;
            if (bytes==null)
               warn("Error Loading Data","No data.");
            else
               runBytes(bytes);
         }
      });
      var lastPct = 0;
      loader.addEventListener(ProgressEvent.PROGRESS, (p) -> {
         var pct = Std.int( 100 * p.bytesLoaded / Math.max(1,p.bytesTotal) );
         if (pct!=lastPct)
         {
            lastPct = pct;
            progress.update(pct);
         }
      } );
      loader.addEventListener(IOErrorEvent.IO_ERROR, (e) -> {
          Game.closeDialog();
          warn("Error Loading Data", "Error: " + e.text );
      } );

      var req = new URLRequest(url);
      req.preferHaxeHttp = true;
      loader.load(req);
   }

   public function warn(title:String, message:String)
   {
      var panel = new Panel(title);
      //Sys.println("Warning:" + message);
      panel.addLabel(message);
      panel.addTextButton("Ok", Game.closeDialog );
      var dlg = new gm2d.ui.Dialog(panel.getPane());
      Game.doShowDialog(dlg,true);
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
      if (isWeb)
      {
         onOpen(null);
      }
      else
      {
         var menuItemm = new MenuItem("Options");
         menuItemm.add( new MenuItem("Settings..", onSettings ) );
         menuItemm.add( new MenuItem("Open..", onOpen ) );

         var popup = new PopupMenu(menuItemm);
         var pos = button.localToGlobal( new Point(0,0) );
         gm2d.Game.popup( popup, pos.x, pos.y);
      }
   }

   function onOpen(_)
   {
      nme.system.Dialog.fileOpen("Select NME File", "Selct file to run", null, "Nme Files|*.nme", filename-> {
         if (filename!=null)
            launch(filename);
      } );
   }

   function onSettings(_)
   {
      var panel = new gm2d.ui.Panel("Settings");
      panel.addLabelUI("Enable Network", new CheckButtons(serverEnabled, onEnable) );
      panel.addLabelUI("Network Password", new TextInput(serverPassword, onPassword) );
      panel.addTextButton("Ok", function() { gm2d.Game.closeDialog(); } );
      panel.showDialog(true, { chromeButtons:[] } );
   }

   function createMenuIcon()
   {
      var gap = Skin.getSkin().scale(1);
      var bar = Skin.getSkin().scale(2);
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

      var path = null;
      if (launchScript!=null)
      {
         path = launchScript.get(name);
         if (path==null)
         {
            for(k in launchScript.keys())
            {
               var parts = k.split(".");
               if (parts[ parts.length-1 ]==name)
                   path = launchScript[k];
            }
         }
      }
      if (path==null && FileSystem.exists(name) )
         path = name;
      if (path==null)
         return 'Unknown application $name';
      haxe.Timer.delay( () -> run(path), 0 );
      return "launched...";
   };


   function runBytes(bytes:ByteArray)
   {
      removeListeners();
      Acadnme.runScriptBytes(bytes);
   }

   function run(path:String)
   {
      removeListeners();
      Acadnme.runScript(path);
   }



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
         run(path);
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
               var size = gm2d.skin.Skin.getSkin().scale(48);
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
         {
            bitmap = createSvgBmp( details.svgIcon );
         }

         if (bitmap==null)
         {
            bitmap = createSvgBmp( Assets.getString("default.svg") );
         }

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
      if (isWeb)
         return;

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

         var size = Skin.getSkin().scale(48);
         var sx = size/w;
         var sy = size/h;
         var scale = Math.min(sx,sy);
         var bmp = renderer.renderBitmap( new Rectangle(0,0,size,size), scale );
         return new Image(bmp, { wantsFocus:false } );
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



