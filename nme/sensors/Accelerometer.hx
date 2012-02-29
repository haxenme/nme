package nme.sensors;

#if (cpp || neko)

typedef Accelerometer = neash.sensors.Accelerometer;

#elseif js

//typedef Accelerometer = jeash.sensors.Accelerometer;

#else

typedef Accelerometer = flash.sensors.Accelerometer;

#end