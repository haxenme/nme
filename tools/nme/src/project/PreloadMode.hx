enum PreloadMode
{
   PreloadNone;   // Default - do not preload this asset
   PreloadWait;   // Preload and wait for completion before handing control to wasm
   PreloadStart;  // Initiate the load but start the app immediately; load may complete later
}
