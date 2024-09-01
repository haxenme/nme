package nme.android;

enum BluetoothScan
{
   BluetoothDisabled;
   BluetoothMissing;
   BluetoothNonePaired;
   BluetoothScanning;
   BluetoothDevices(devices:Array<String>);
}
