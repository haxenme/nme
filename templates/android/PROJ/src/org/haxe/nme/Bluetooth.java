package org.haxe.nme;

import android.util.Log;

import android.content.Context;
import android.content.Intent;

import java.io.InputStream;
import java.io.OutputStream;

import java.io.Closeable;

import android.bluetooth.BluetoothAdapter;


public class Bluetooth
{
   static final String TAG = "Bluetooth";
   static final int REQUEST_ENABLE_BT = 123;
   BluetoothAdapter mBluetoothAdapter;

   public Bluetooth(BluetoothAdapter inAdapter)
   {
      mBluetoothAdapter = inAdapter;
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

