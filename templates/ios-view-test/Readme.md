Create the haxe files:
nme test ios-view

This will give you a directory with a ".h", ".mm" and ".a" files in it (bin/ios-view/APPNAME).


Create new xcode project

File - Add files to
  Tick Copy items to destination
  And keep the settings "Create groups for and added folders", Add to targets "App"

Browse to your files (APPNAME folder) using the ironically named "Finder" (Alt-Shift-G [Slash] [Enter] is the best way I have found so far if you have the temerity to not put you files in the "Documents" folder)
 
This should create a little folder in the xcode project view.

In the Linked Frameworks and Libraries, Add
 + AVFoundation Framework
 + MediaPlayer Framework
 + OpenAl Framework

Also, deleted the "Tests" folder as I will not be using it.

At this stage, the project should build, but nothing happens, since we have not hooked in our view.

Quick primer on some xcode stuff - since we starte with the single view application, some of this stuff is not needed.

https://developer.apple.com/library/ios/referencelibrary/GettingStarted/RoadMapiOS/FirstTutorial.html

---
Adding the view

Edit the "Main_iPad" story board
Drag in a "Container View" from the cube icon tab in the bottom-right panel.  If you get the zoom right, you can select this and position it in a sub-rectangle of the parent View.
Then you can zoom-out and see a new "View Controller" in the storyboard - select this.  On the top panel on the right, third tab "Identity" (looks like and postage envelope rotatd 180 degrees) Change the "Custom Class" the the name of your class (Same name as your ".mm" file) - it should be in the pick list.
If you edited the "ipad" storyboard first, make sure you test on ipad simulator, and hit the play button.  There you have it!

One final thing - hiding the keyboard.  The example code tracks the current "firstResponder" and dismisses it when the apply button is hit.  You may want to do something more intelligent here.

Now, do the same for the "Main_iPhone" story board, select the appropriate emulator and this should play too.

---
Ok, so the basics are now working.  Here is a small example of how the haxe view and the iosview can interact.  Start by adding two "TextField" views and one "Button" underneath the "Container" that holds our application.
Open the "Assistant editor" (back-tie icon), and control-drag the two text fields onto the "ViewController.h" @interface section.  Control-drag the button onth the @implementation section and add an "Apply property" action.
Also, we will give the segue a name ("StartHaxe") so that we can capture the pointer to our class instance ona a round-about sort of way later.
To test, You can add the code to the click callback:
NSLog (@"Set Prop %@ ", propName.text);
NSLog (@"Set Prop %@ ", propValue.text);

The next task is to get this value to haxe.  That is where the template files come in.

In the templates/ios-view directory there are a few files:
   CLASS.mm - this will get renamed and end up in the project.
      This has the "register" function that ensures the haxe library code is linked in and
      can be found by the interface builder.
   HEADER.h - this also ends up in your ios project.  It declares your class to be
      a type of UIViewController - that is how xcode knows to what to do with it and put
      it in the pick lists.  You can also add interface functions to this file.  Your
      application objc code will see these functions and can just call them using
      standard objc syntax.  The implementation of these interface functions will be in
      FrameworkInterface.mm, which exists in the library, rather than source code in the project.
   FrameworkInterface.mm  - this gets compiled at at the same time as your haxe code.
      It is "mm" (objc++), but because it is compiled with the same flags as your haxe
      code, it can "see" the headers (if you #include them).  Objc++ is a superset of c++,
      so it can call into your haxe code directly.  It can be a bit tricky to keep an
      instance variable (due to GC considerations), so it is easiest to call static functions.
      The example code uses the static nme.Lib.current.getChildAt(0) to find what it assumes
      is your main class.
      This is where you implenent the "glue" between the ios app and the haxe code.

You can customise these files in the usual template way, with a "templatePath" entry in you project file, and then your own version of these files.  These files use the haxe templating system, so "CLASS_NAME::" will be replaced with your app name.  The basic template has a "setProperty" example - you can delete this and replace it with your own functions.

To get the pointer to the class, we implement the "prepareForSegue" function and wait to a callback with a pointer, and store it in the view contoller.

Then, in the button callback, we can call the instance method [current setProperty:name toValue:value], which will call into FrameworkInterface, which will convert the args to haxe and call into our main class.

You need to redo the storyboard bits for ipad-iphone (but now the text & buttons can be wired to the existing properties/function, and the segue needs the same name), but you can reuse the event handlers.

