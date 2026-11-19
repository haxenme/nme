package nme.display;

// Whether a line (stroke) is drawn over or under the fill of the same path.
// This is the ordering part of the svg "paint-order" property.
enum LineOrder
{
   OVER_FILL; // default - the flash behaviour
   UNDER_FILL; // svg "paint-order: stroke"
}
