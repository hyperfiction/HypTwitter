package ::APP_PACKAGE::;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.net.Uri;

import fr.hyperfiction.HypTwitter;

public class MainActivity extends org.haxe.nme.GameActivity {

	/**
	* 
	* 
	* @public
	* @return	void
	*/
	@Override
	protected void onNewIntent(Intent intent) {
		Log.i("trace","onNewIntent"+intent);
		super.onNewIntent(intent);

		Uri uri = intent.getData();
		if( uri != null ){
			Log.i("trace","uri "+uri);
			HypTwitter.onIntent( uri.toString( ) );
		}
	}

}

