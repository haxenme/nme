In eclipse, File > New android project
Fill in details
Create blank activity
Change main class to extend FragmentActivity instead of Activity

Build project with:
 nme test android-view

Copy all files in their directories to new project (refresh the "libs" directory)

(optional - to get "GameActivity" to show up)pplication.jat and use Build > add to build path

Edit the res/layout/activity_main.xml
  Delete the Hello text
  Add a Linear layout (Vertical)
    Add two Text boxes
    Add Button
    Add a Layout > Fragment, and select "GameActivity"
       Set layout width & height to "match parent"


