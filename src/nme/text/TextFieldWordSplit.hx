package nme.text;

enum abstract TextFieldWordSplit(Int) from Int to Int
{
   var SPLIT_NEVER = 0;
   var SPLIT_ANYWHERE = 1;
   var SPLIT_SYMBOLS = 2;
}