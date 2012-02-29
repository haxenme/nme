package nme;


import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.view.View;
import android.view.KeyEvent;
import org.haxe.nme.GameActivity;
import android.content.Context;


class NMEWebView extends WebView
{
   private class NMEWebViewClient extends WebViewClient {
    @Override
    public boolean shouldOverrideUrlLoading(WebView view, String url) {
        Log.e("NMEWebView","shouldOverrideUrlLoading " + url);
        view.loadUrl(url);
        return true;
    }
   }

   public NMEWebView(Context inContext,String inURL)
   {
      super(inContext);

      WebSettings webSettings = getSettings();
      webSettings.setSavePassword(false);
      webSettings.setSaveFormData(false);
      webSettings.setJavaScriptEnabled(true);
      webSettings.setSupportZoom(false);

      setWebViewClient(new NMEWebViewClient());

      loadUrl(inURL);
   }

   @Override
   public boolean onKeyDown(final int keyCode, KeyEvent event) {
    Log.e("NMEWebView","onKeyDown " + keyCode);
    if ((keyCode == KeyEvent.KEYCODE_BACK) && !canGoBack()) {
        GameActivity.popView();
    }
    return super.onKeyDown(keyCode, event);
   }

   public static View nmeCreate(String inURL)
   {
      Log.e("NMEWebView","==========Create================");
      View view = new NMEWebView(GameActivity.getContext(),inURL);
      // TODO: May need new activity
      GameActivity.pushView(view);
      return view;
   }
}


