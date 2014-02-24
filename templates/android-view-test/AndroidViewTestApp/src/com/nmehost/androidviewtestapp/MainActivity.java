package com.nmehost.androidviewtestapp;

import android.os.Bundle;
import android.app.Activity;
import android.support.v4.app.FragmentActivity;
import android.view.Menu;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;


public class MainActivity extends FragmentActivity {

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
        final Button button = (Button) findViewById(R.id.button1);
        final EditText propName = (EditText) findViewById(R.id.editText1);
        final EditText propValue = (EditText) findViewById(R.id.editText2);
        final ::CLASS_PACKAGE::.::CLASS_NAME:: app = (::CLASS_PACKAGE::.::CLASS_NAME::)
        		getFragmentManager().findFragmentById(R.id.fragment1);
        button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
            	app.setProperty(propName.getText().toString(), propValue.getText().toString());
            }
        });
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}

}
