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
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothProfile;
import java.io.ByteArrayOutputStream;
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
import org.haxe.nme.GameActivity;
import java.util.List;
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
   // TODO - allow explicit UUIDs to be specified for RX/TX characteristics
   UUID bleRxUuid = null;
   UUID bleTxUuid = null;
 

   BluetoothDevice mDevice;
   BluetoothGatt   mGatt;
   BluetoothGattCharacteristic tx;
   BluetoothGattCharacteristic rx; 
   boolean  bleConnected;
   boolean  bleConnecting;
   ByteArrayOutputStream mBleReceiveBuffer = new ByteArrayOutputStream();
   final Object mBleLock = new Object();
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
         boolean isBLE = mDevice.getType()==BluetoothDevice.DEVICE_TYPE_LE;
         Log.e(TAG,"Create bluetooth " + inAddress + " isBLE:" + isBLE);
         // Get a BluetoothSocket to connect with the given BluetoothDevice
         final Bluetooth thiz = this;
         try
         {
            if (isBLE)
            {
               final BluetoothGattCallback bluetoothGattCallback = new BluetoothGattCallback() {
               @Override
               public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                   if (newState == BluetoothProfile.STATE_CONNECTED) {
                     Log.e(TAG, "BLE connected, starting service discovery...");
                     gatt.discoverServices();
                   } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                     thiz.onBLEConnected(false);
                   }
               }
               @Override
               public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                   if (status == BluetoothGatt.GATT_SUCCESS) {
                     thiz.onBLEConnected(true);
                   } else {
                     Log.e(TAG, "Service discovery failed with status: " + status);
                   }
               }
               @Override
               public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
                   byte[] data = characteristic.getValue();
                   Log.e(TAG,"Received BLE notification, " + data.length + " bytes");
                   if (data != null && data.length > 0) {
                     synchronized (thiz.mBleLock) {
                        thiz.mBleReceiveBuffer.write(data, 0, data.length);
                     }
                   }
               } };
               bleConnecting = true;
               mGatt = mDevice.connectGatt(GameActivity.getInstance().getActivity(), false, bluetoothGattCallback);
            }
            else
               mSocket = mDevice.createRfcommSocketToServiceRecord(SerialUuid);
         }
         catch (IOException e)
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
      Log.e(TAG,"Connected " + (mSocket!=null || mGatt!=null) );
   }

   void onBLEConnected(boolean inConnected)
   {
      bleConnected = inConnected;
      bleConnecting = false;
      Log.e(TAG,"Bluetooth " + (inConnected ? "connected" : "disconnected"));
      if (inConnected)
      {
         Log.e(TAG,"Discover services...");
         List<BluetoothGattService> services = mGatt.getServices();
         
        
         // Standard BLE services to skip during auto-detection
         final UUID genericAccessUuid = UUID.fromString("00001800-0000-1000-8000-00805f9b34fb");
         final UUID genericAttributeUuid = UUID.fromString("00001801-0000-1000-8000-00805f9b34fb");
         final UUID deviceInfoUuid = UUID.fromString("0000180a-0000-1000-8000-00805f9b34fb");
         
         // Candidates for auto-detection fallback
         BluetoothGattCharacteristic autoRx = null;
         BluetoothGattCharacteristic autoTx = null;
         
         for (BluetoothGattService service : services)
         {
            UUID serviceUuid = service.getUuid();
            Log.e(TAG,"Service " + serviceUuid);
            
            boolean isStandardService = serviceUuid.equals(genericAccessUuid) || 
                                         serviceUuid.equals(genericAttributeUuid) ||
                                         serviceUuid.equals(deviceInfoUuid);
            
            for (BluetoothGattCharacteristic characteristic : service.getCharacteristics())
            {
               UUID uuid = characteristic.getUuid();
               int props = characteristic.getProperties();
               Log.e(TAG,"  Characteristic " + uuid + " props=0x" + Integer.toHexString(props));
               
               // First priority: explicit UUID match
               if (bleRxUuid!=null && uuid.equals(bleRxUuid))
               {
                  Log.e(TAG,"  Found RX characteristic (explicit UUID)");
                  rx = characteristic;
               }
               else if (bleTxUuid!=null && uuid.equals(bleTxUuid))
               {
                  Log.e(TAG,"  Found TX characteristic (explicit UUID)");
                  tx = characteristic;
               }
               
               // Second priority: auto-detect based on properties (skip standard services)
               if (!isStandardService)
               {
                  if (autoRx == null && ((props & BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0 ||
                                         (props & BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0))
                  {
                     autoRx = characteristic;
                     Log.e(TAG,"  Found candidate RX characteristic (notify/indicate)");
                  }
                  if (autoTx == null && ((props & BluetoothGattCharacteristic.PROPERTY_WRITE) != 0 ||
                                         (props & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0))
                  {
                     autoTx = characteristic;
                     Log.e(TAG,"  Found candidate TX characteristic (write)");
                  }
               }
            }
         }
         
         // Fall back to auto-detected characteristics if explicit UUIDs not found
         if (rx == null && autoRx != null)
         {
            Log.e(TAG,"Using auto-detected RX characteristic: " + autoRx.getUuid());
            rx = autoRx;
         }
         if (tx == null && autoTx != null)
         {
            Log.e(TAG,"Using auto-detected TX characteristic: " + autoTx.getUuid());
            tx = autoTx;
         }
      }
      else
      {
         tx = null;
         rx = null;
      }
      if (tx!=null && rx!=null)
      {
         Log.e(TAG,"Enable notifications...");
         mGatt.setCharacteristicNotification(rx, true);
         // Write to CCCD descriptor to enable notifications on the remote device
         UUID cccdUuid = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
         BluetoothGattDescriptor descriptor = rx.getDescriptor(cccdUuid);
         if (descriptor != null) {
            descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
            mGatt.writeDescriptor(descriptor);
         }
      }  
      Log.e(TAG,"BLE streams " + (tx!=null) + "/" + (rx!=null) );
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
      if (bleConnecting && tx==null)
      {
         Log.e(TAG,"Still connecting BLE, cannot write byte yet:" + buffer);
         return 0;
       }
      if (tx != null)
      {
         try
         {
            byte[] data = buffer.getBytes();
            tx.setValue(data);
            if (mGatt.writeCharacteristic(tx))
               return data.length;
         } catch(Exception e)
         {
            Log.e(TAG,"Error writing to BLE characteristic: " + e);
         }
         return 0;
      }
      try
      {
         if (mOutput==null)
            return 0;
         mOutput.write(buffer.getBytes());
         return buffer.length();
      } catch(IOException e) { }
      return 0;
   }

   public String readBytes(int length)
   {
      if (bleConnecting && rx==null)
      {
         Log.e(TAG,"Still connecting BLE, cannot read byte yet:" + length);
         return null;
       }
      if (rx != null) {
         synchronized (mBleLock) {
            byte[] buffered = mBleReceiveBuffer.toByteArray();
            int toRead = Math.min(length, buffered.length);
            if (toRead > 0) {
               //Log.e(TAG,"Read " + toRead + " bytes from BLE buffer, " + (buffered.length - toRead) + " bytes remain");
               mBleReceiveBuffer.reset();
               if (toRead < buffered.length) {
                  mBleReceiveBuffer.write(buffered, toRead, buffered.length - toRead);
               }
               return new String(buffered, 0, toRead);
            }
         }
         return null;
      }
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
      if (bleConnecting && tx==null)
      {
         Log.e(TAG,"Still connecting BLE, cannot write byte yet:" + inByte);
         return false;
       }
      if (tx!=null)
      {
         try
         {
            tx.setValue(new byte[] { (byte)inByte });
            return mGatt.writeCharacteristic(tx);
         } catch(Exception e) { }
         return false;
      }
      try
      {
         if (mOutput==null)
            return false;
         mOutput.write(inByte);
         return true;
      } catch(IOException e) { }
      return false;
   }

   public int readByte()
   {
      if (rx != null) {
         synchronized (mBleLock) {
            byte[] buffered = mBleReceiveBuffer.toByteArray();
            if (buffered.length > 0) {
               mBleReceiveBuffer.reset();
               if (buffered.length > 1) {
                  mBleReceiveBuffer.write(buffered, 1, buffered.length - 1);
               }
               return buffered[0] & 0xFF;
            }
         }
         return 0;
      }
      try
      {
         if (mInput==null)
            return 0;
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
      if (rx != null) {
         synchronized (mBleLock) {
            return mBleReceiveBuffer.size();
         }
      }
      try
      {
         if (mInput==null)
            return 0;
         return mInput.available();
      } catch(IOException e) { }
      return 0;
   }

   public int close()
   {
      try
      {
         if (mGatt!=null)
            mGatt.close();
         if (mInput!=null)
            mInput.close();
         if (mOutput!=null)
            mOutput.close();
         if (mSocket!=null)
            mSocket.close();
      } catch(IOException e) { }
      return 1;
   }

   public boolean ok()
   {
      return mSocket!=null || bleConnecting || (tx!=null && rx!=null);
   }


   public static Bluetooth create(String inDeviceName)
   {
      if (!getAdapter())
         return null;
      return new Bluetooth(inDeviceName);
   }

}

