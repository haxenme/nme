package org.haxe.nme;

import android.util.Log;

import android.content.Context;
import android.content.Intent;

import java.io.InputStream;
import java.io.OutputStream;

import java.io.Closeable;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import java.util.Set;
import java.util.ArrayList;
import android.content.BroadcastReceiver;
import android.content.IntentFilter;


public class Bluetooth
{
   static final String TAG = "Bluetooth";
   static final int REQUEST_ENABLE_BT = 5;
 
   static final int BLUETOOTH_DISABLED = -2;
   static final int NO_BLUETOOTH = -1;
   static final int BLUETOOTH_OK = 0;
   static final int SCANNING = 1;
   static final int NO_PAIRED_DEVICES = 2;

   BluetoothAdapter mBluetoothAdapter;

   public Bluetooth(BluetoothAdapter inAdapter)
   {
      mBluetoothAdapter = inAdapter;
   }

   public boolean isEnabled()
   {
      return mBluetoothAdapter!=null && mBluetoothAdapter.isEnabled();
   }


   public void getDevices()
   {
      if (mBluetoothAdapter!=null)
      {
         if (!mBluetoothAdapter.isEnabled())
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

   void postDevices(final HaxeObject inHandler,final int inState, final String[] inDevices)
   {
      GameActivity activity = GameActivity.getInstance();
      activity.sendToView( new Runnable() { @Override public void run()
         {
             Log.e(TAG,"Sending devices " + inState + "/" + inDevices);
             inHandler.call2("setDevicesAsync",inState,inDevices);
         } }
      );
   }

   void scanDevices(final HaxeObject inHandler)
   {
      postDevices(inHandler, SCANNING , null );

      final ArrayList<String> scannedDevices = new ArrayList<String>();

      final BroadcastReceiver[] receiverRef = new BroadcastReceiver [1];
      final GameActivity activity = GameActivity.getInstance();

      // The BroadcastReceiver that listens for discovered devices/scan done events
      final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            // When discovery finds a device
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                // Get the BluetoothDevice object from the Intent
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                Log.e(TAG,"Found device " + device.getName() );
                // If it's already paired, skip it
                //if (device.getBondState() != BluetoothDevice.BOND_BONDED
                    scannedDevices.add(device.getName() + ":" + device.getAddress());
            // When discovery is finished send the devices...
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
               Log.e(TAG,"Finished discovery");
               String [] devices = scannedDevices.toArray(new String[scannedDevices.size()]);
               postDevices(inHandler, devices.length==0 ? NO_PAIRED_DEVICES : BLUETOOTH_OK, devices );
               if (receiverRef[0]!=null)
               {
                  Log.e(TAG,"unregisterReceiver");
                  activity.unregisterReceiver(receiverRef[0]);
                  receiverRef[0] = null;
               }
            }
         }
       };
       receiverRef[0] = receiver;

       mBluetoothAdapter.cancelDiscovery();
 
       // Register for broadcasts when a device is discovered
       IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
       activity.registerReceiver(receiver, filter);

       // Register for broadcasts when discovery has finished
       filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
       activity.registerReceiver(receiver, filter);

       activity.addOnDestoryListener( new Runnable() {
          @Override public void run() {
             Log.e(TAG,"onDestroy");
             if (receiverRef[0]!=null)
             {
                Log.e(TAG,"unregisterReceiver");
                activity.unregisterReceiver(receiverRef[0]);
                receiverRef[0] = null;
             }
          } } );
    
       // Unregister broadcast listeners

       mBluetoothAdapter.startDiscovery();

   }

   void sendDevices(HaxeObject inHandler)
   {
      Set<BluetoothDevice> pairedDevices = mBluetoothAdapter.getBondedDevices();
      String [] result = null;

      // If there are paired devices
      Log.e(TAG,"Found paired devices " +  pairedDevices.size());

      if (pairedDevices.size() > 0)
      {
          result = new String[pairedDevices.size()];
          int idx = 0;
          // Loop through paired devices
          for (BluetoothDevice device : pairedDevices)
          {
              // Add the name and address to an array adapter to show in a ListView
              result[idx++] = device.getName() + ":" + device.getAddress();
          }
      }

      postDevices(inHandler, pairedDevices.size()==0 ? NO_PAIRED_DEVICES : BLUETOOTH_OK, result);
   }

   public void getDeviceListAsync(final HaxeObject inHandler,final boolean inFullScan)
   {
      final Bluetooth me = this;
      if (mBluetoothAdapter==null)
      {
          postDevices(inHandler,NO_BLUETOOTH, null);
      }
      if (!mBluetoothAdapter.isEnabled())
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
                     me.scanDevices(inHandler);
                  else
                     me.sendDevices(inHandler);
               }
               else
                  me.postDevices(inHandler,BLUETOOTH_DISABLED, null);
            }});
         activity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
      }
      else
      {
         if (inFullScan)
            me.scanDevices(inHandler);
         else
            me.sendDevices(inHandler);
      }
   }



   public static Bluetooth create()
   {
       Log.e(TAG, "getAdapter...");
       BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
       Log.e(TAG, "Found adapter : " + bluetoothAdapter );
       if (bluetoothAdapter==null)
          return null;
       return new Bluetooth(bluetoothAdapter);
   }

}

