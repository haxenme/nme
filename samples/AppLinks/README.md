### App Links

A way to let your app handle http links.

1) Plugin your android test device
2) Send your android test device this link...

http://www.example.com/gizmos

Perhaps via gmail or sms.

3) nme test android
4) Click the link in SMS or gmail

Expect: 

* You should be able to open your App as one of the devices for handling this link.
* When you go into this app you should also be able to see a trace in ADB: 
  "Received App Link: http://www.example.com/gizmos"
* There are two times you can receive an app link event. 
  A) At onCreate (your app is not yet running)
  B) At onStart (your app is already running)
  In order to properly receive a callback for onCreate, make sure you register a callback in your Main Sprite constructor.