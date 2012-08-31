package nme;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;
import org.haxe.nme.sample21.R;
import org.haxe.nme.GameActivity;

public class BrowserLauncher {

    public static void launchChrome(String url)
    {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        GameActivity.getInstance().startActivity(intent);
    }
    
    public static void launchEmbedded(String url)
    {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setClass(GameActivity.getContext(), BrowserActivity.class);
        intent.putExtra("url", url);
        GameActivity.getInstance().startActivity(intent);
    }
    
    public static class BrowserActivity extends Activity {
        
        WebView webView;
        
        protected void onCreate(Bundle state)
        {
            super.onCreate(state);
            
            requestWindowFeature(Window.FEATURE_INDETERMINATE_PROGRESS);
            requestWindowFeature(Window.FEATURE_PROGRESS);

            setTitle(getString(R.string.browser_title));
            getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
            
            String url = getIntent().getStringExtra("url");

            webView = new WebView(this);
            webView.loadUrl(url);
            
            WebSettings settings = webView.getSettings();
            settings.setJavaScriptEnabled(true);

            final Activity activity = this;
            
            webView.setWebChromeClient(new WebChromeClient() {
                public void onProgressChanged(WebView view, int progress) {
                    activity.setProgress(progress * 100);
                }
            });
            
            webView.setWebViewClient(new WebViewClient() {
                public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon)
                {
                    activity.setTitle("");
                }

                public void onPageFinished(WebView view, String url)
                {
                    activity.setTitle(view.getTitle());
                }

                public void onReceivedError(WebView view, int errorCode, String description, String failingURL)
                {
                    Toast.makeText(activity, "Problem loading page " + description, Toast.LENGTH_SHORT).show();
                }
            });

            webView.requestFocus();
            setContentView(webView);

            overridePendingTransition(R.anim.slide_in_from_right, R.anim.hold);
        }
        
        @Override
        protected void onPause() {
            overridePendingTransition(R.anim.hold, R.anim.slide_out_ro_right);
            super.onPause();
        }
        
        @Override
        public void onBackPressed() {
            if (webView.canGoBack()) {
                webView.goBack();
            }
            else {
                super.onBackPressed();
            }
        }
    }
}
