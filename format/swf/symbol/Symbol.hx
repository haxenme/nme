package format.swf.symbol;


enum Symbol {
	
	shapeSymbol (data:Shape);
	morphShapeSymbol (data:MorphShape);
	spriteSymbol (data:Sprite);
	bitmapSymbol (data:Bitmap);
	fontSymbol (data:Font);
	staticTextSymbol (data:StaticText);
	editTextSymbol (data:EditText);
	buttonSymbol (data:Button);
	
}