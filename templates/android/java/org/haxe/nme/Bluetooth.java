package org.haxe.nme;

import android.util.Log;

import android.content.Context;
import android.content.Intent;

import java.io.InputStream;
import java.io.OutputStream;

import java.io.Closeable;

import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import java.util.Set;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.UUID;
import java.io.IOException;
import android.os.ParcelUuid;
import android.content.BroadcastReceiver;
import android.content.IntentFilter;
import android.app.Activity;
import android.annotation.SuppressLint;
import org.json.*;

// You will need to add the permission android.permission.BLUETOOTH/BLUETOOTH_ADMIN to use this
@SuppressLint("MissingPermission") 
public class Bluetooth
{
   static final String TAG = "Bluetooth";
   static final int REQUEST_ENABLE_BT = 5;
 
   static final int BLUETOOTH_DISABLED = -2;
   static final int NO_BLUETOOTH = -1;
   static final int BLUETOOTH_OK = 0;
   static final int SCANNING = 1;
   static final int NO_PAIRED_DEVICES = 2;


   private static final UUID SerialUuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");


   static BluetoothAdapter sBluetoothAdapter;
   static HashMap<String,BluetoothDevice> sDeviceMap = new HashMap<String,BluetoothDevice>();
   static boolean isScanning = false;

   BluetoothDevice mDevice;
   BluetoothSocket mSocket;
   InputStream mInput;
   OutputStream mOutput;
   byte [] mBuffer;
   

   public Bluetooth(String inAddress)
   {
      if (isScanning)
      {
         Log.e(TAG,"cancelDiscovery..");
         sBluetoothAdapter.cancelDiscovery();
      }

      mDevice = sDeviceMap.get(inAddress);
      if (mDevice!=null)
      {
         // Get a BluetoothSocket to connect with the given BluetoothDevice
         try {
            mSocket = mDevice.createRfcommSocketToServiceRecord(SerialUuid);
         } catch (IOException e)
         {
            Log.e(TAG,"Error opening bluetooth "+e);
         }
      }

      if (mSocket!=null)
      {
         try
         {
            // Connect the device through the socket. This will block
            // until it succeeds or throws an exception
            mSocket.connect();
            mInput = mSocket.getInputStream();
            mOutput = mSocket.getOutputStream();
         }
         catch (IOException connectException)
         {
            Log.e(TAG,"Error connecting bluetooth "+connectException);
            // Unable to connect; close the socket and get out
            try {
                mSocket.close();
            } catch (IOException closeException) { }
            mSocket = null;
        }
      }
      Log.e(TAG,"Connected " + (mSocket!=null) );
   }

   public static boolean isEnabled()
   {
      return sBluetoothAdapter!=null && sBluetoothAdapter.isEnabled();
   }


   public static void getDevices()
   {
      if (sBluetoothAdapter==null)
         sBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

      if (sBluetoothAdapter!=null)
      {
         if (!sBluetoothAdapter.isEnabled())
         {
            Log.e(TAG,"Enable bluetooth...");
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            GameActivity activity = GameActivity.getInstance();
            activity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
         }
         else
         {
            Log.e(TAG,"Bluetooth already enabled ...");
         }
      }
   }

   static void postDevices(final HaxeObject inHandler,final int inState, final String[] inDevices)
   {
      GameActivity activity = GameActivity.getInstance();
      activity.sendToView( new Runnable() { @Override public void run()
         {
             Log.e(TAG,"Sending devices " + inState + "/" + inDevices);
             inHandler.call2("setDevicesAsync",inState,inDevices);
         } }
      );
   }

   static void addDevice(ArrayList<String> scannedDevices,BluetoothDevice device)
   {
      try
      {
         JSONObject obj= new JSONObject();
         obj.put("name", device.getName() );
         obj.put("string", device.toString() );
         obj.put("address", device.getAddress() );
         obj.put("alias", device.getAlias() );
         obj.put("bondState", device.getBondState() );
         obj.put("type", device.getType() );
         Log.e(TAG,"Found device " + obj.toString() );
         // If it's already paired, skip it
         //if (device.getBondState() != BluetoothDevice.BOND_BONDED
         scannedDevices.add(obj.toString());
      }
      catch (JSONException e)
      {
         Log.e(TAG, "Error in device serialization." + device.toString() );
      }
      sDeviceMap.put(device.getAddress(), device );
 }

   static int sScanId = 0;
   static void scanDevices(final HaxeObject inHandler)
   {
      Log.e(TAG,"cancelDiscovery..");
      sBluetoothAdapter.cancelDiscovery();

      final int recScanId = ++sScanId;
      Log.e(TAG,"scanDevices.." + recScanId );
      postDevices(inHandler, SCANNING , null );

      sDeviceMap = new HashMap<String,BluetoothDevice>();

      final BroadcastReceiver[] receiverRef = new BroadcastReceiver [1];
      final Activity activity = GameActivity.getInstance().getActivity();
      final ArrayList<String> scannedDevices = new ArrayList<String>();

      // The BroadcastReceiver that listens for discovered devices/scan done events
      final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (isInitialStickyBroadcast())
            {
               Log.e(TAG,"onReceive isInitialStickyBroadcast");
               return;
            }

            String action = intent.getAction();

            if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action))
            {
               Log.e(TAG,"Finished discovery:" + recScanId + "/" + sScanId);
               if (receiverRef[0]!=null)
               {
                  Log.e(TAG,"unregisterReceiver");
                  activity.unregisterReceiver(receiverRef[0]);
                  receiverRef[0] = null;
               }
            }

            if (recScanId!=sScanId)
            {
               Log.e(TAG,"Overlapping scans?" + recScanId + "/" + sScanId);
               return;
            }
            // When discovery finds a device
            else if (BluetoothDevice.ACTION_FOUND.equals(action))
            {
                // Get the BluetoothDevice object from the Intent
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                addDevice(scannedDevices, device);


            // When discovery is finished send the devices...
            }
            else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action))
            {
               Log.e(TAG,"Finished discovery - send");
               String [] devices = scannedDevices.toArray(new String[scannedDevices.size()]);
               postDevices(inHandler, devices.length==0 ? NO_PAIRED_DEVICES : BLUETOOTH_OK, devices );
            }
         }
       };
       receiverRef[0] = receiver;
 
       // Register for broadcasts when a device is discovered
       Log.e(TAG,"registerReceiver..");
       IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
       activity.registerReceiver(receiver, filter);

       // Register for broadcasts when discovery has finished
       filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
       activity.registerReceiver(receiver, filter);

       GameActivity.getInstance().addOnDestoryListener( new Runnable() {
          @Override public void run() {
             Log.e(TAG,"onDestroy");
             if (receiverRef[0]!=null)
             {
                Log.e(TAG,"unregisterReceiver");
                activity.unregisterReceiver(receiverRef[0]);
                receiverRef[0] = null;
                isScanning = false;
             }
          } } );



      sBluetoothAdapter.startDiscovery();

   }

   static void sendDevices(HaxeObject inHandler)
   {
      Set<BluetoothDevice> pairedDevices = sBluetoothAdapter.getBondedDevices();
      final ArrayList<String> scannedDevices = new ArrayList<String>();

      // If there are paired devices
      Log.e(TAG,"Found paired devices " +  pairedDevices.size());

      if (pairedDevices.size() > 0)
      {
          int idx = 0;
          // Loop through paired devices
          for (BluetoothDevice device : pairedDevices)
          {
             addDevice(scannedDevices, device);
             // Add the name and address to an array adapter to show in a ListView
             //result[idx++] = device.getName();// + "\n" + device.getAddress();
             //sDeviceMap.put(device.getAddress(), device );
          }
      }

      String [] devices = scannedDevices.toArray(new String[scannedDevices.size()]);
      postDevices(inHandler, devices.length==0 ? NO_PAIRED_DEVICES : BLUETOOTH_OK, devices );
   }

   static boolean getAdapter()
   {
      if (sBluetoothAdapter!=null)
         return true;

      Log.e(TAG,"Get adapter...");
      GameActivity activity = GameActivity.getInstance();
      BluetoothManager bluetoothManager = activity.getSystemService(BluetoothManager.class);
      sBluetoothAdapter = bluetoothManager.getAdapter();
      return sBluetoothAdapter!=null;
   }

   public static void getDeviceListAsync(final HaxeObject inHandler,final boolean inFullScan)
   {
      if (!getAdapter())
      {
         postDevices(inHandler,NO_BLUETOOTH, null);
         return;
      }

      if (!sBluetoothAdapter.isEnabled())
      {
         Log.e(TAG,"Enable bluetooth...");
         Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
         GameActivity activity = GameActivity.getInstance();
         activity.addResultHandler(REQUEST_ENABLE_BT, new IActivityResult() {
            @Override public void onActivityResult(int inCode, Intent inData)
            {
               Log.e(TAG,"Enabled bluetooth:" + inCode);
               if (inCode==android.app.Activity.RESULT_OK)
               {
                  if (inFullScan)
                     scanDevices(inHandler);
                  else
                     sendDevices(inHandler);
               }
               else
                  postDevices(inHandler,BLUETOOTH_DISABLED, null);
            }});
         activity.getActivity().startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
      }
      else
      {
         if (inFullScan)
            scanDevices(inHandler);
         else
            sendDevices(inHandler);
      }
   }


   public int writeBytes(String buffer)
   {
      try
      {
         mOutput.write(buffer.getBytes());
         return buffer.length();
      } catch(IOException e) { }
      return 0;
   }

   public String readBytes(int length)
   {
      if (mBuffer==null || mBuffer.length<length)
         mBuffer = new byte[length];

      try
      {
         mInput.read(mBuffer, 0, length);
         return new String(mBuffer,0,length);
      } catch(IOException e) { }
      return null;
   }

   public boolean writeByte(int inByte)
   {
      try
      {
         mOutput.write(inByte);
         return true;
      } catch(IOException e) { }
      return false;
   }

   public int readByte()
   {
      try
      {
         return mInput.read();
      } catch(IOException e) { }
      return 0;
   }

   public void flush(boolean flushIn, boolean flushOut)
   {
      // nothing?
   }

   public int available()
   {
      try
      {
         return mInput.available();
      } catch(IOException e) { }
      return 0;
   }

   public int close()
   {
      try
      {
         mInput.close();
         mOutput.close();
         mSocket.close();
      } catch(IOException e) { }
      return 1;
   }

   public boolean ok() { return mSocket!=null; }


   public static Bluetooth create(String inDeviceName)
   {
      if (!getAdapter())
         return null;
      return new Bluetooth(inDeviceName);
   }

}

