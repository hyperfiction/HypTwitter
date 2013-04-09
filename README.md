HypFacebook
=============================
A Twitter native extension for NME
-----------------------------

This NME native extension allows you to integrate Twitter into your NME application.

This is fully made with haxe code.
The only native parts are the logins methods.

It support:
- iOS     : Reverse Auth
- Android : Web Auth
- CPP     : PIN Auth

Installation
------------
There is an [include.nmml]() file and [ndll]() are compiled for:
* ios armv6
* ios armv7
* ios simulator
* android armv6

It should be soon on haxelib.

Android
-------

For android you need to merge you MainActivity.java if you are using another extension who is customizing the MainActivity ( by exammple HypFacebook )

If you need to use HypTwitter only just add in your nmml project file :
template path="[bin-folder]/android/bin/MainActivityTwitter.java" rename="src/fr/hyperfiction/test/MainActivity.java"/>

Recompiling
-----------
For recompiling the native extensions just use the sh files contained in the project folder

Login
-----

Initiliazing :

<pre><code>var t = new HypTwitter( );
t.consumerKey= "xxxxxx";	
t.consumerSecret= "xxxxx";
</code></pre>

For developement mode you can defined your token & secret key:
<pre><code>
	t.token = ""; //Optional Developer token	
	t.tokenSecret = "";//Optional for developer
</code></pre>

Login:

<pre><code>var connector = t.connect( _onConnect , _onError , _onAskPin );</pre></code>

For iOS & Android all is native & done automatically.

For c++ & other PIN base authorization targets when the "_askPin" method is called you must call the method verifiy with the user pin:

<pre><code>t.verifiy( "123456")</code>/<pre>

Usage
-----

Then just do the request by using the call method of the HypTwitter class instance and use the TwitterRequest enum values :

Examples
--------

Simple GET request:
<pre><code>_oTwitter.call( REQUEST( GET , HypTwitter.TIMELINE_USER ) );</pre></code>

Post a new Tweet:
<pre><code>_oTwitter.call( REQUEST(
						POST ,
						HypTwitter.TWEET_UPDATE ,
						null ,
						new Params( "status",">>Hello World Twitter from #Haxe &éè_çà)")
					)
			);</pre></code>

Todo
----

Better authentification for iOS & multiples accounts support.
Adding all the requests in to the definitions.
Better error handling.

Made at Hyperfiction
--------------------
[hyperfiction.fr](http://hyperfiction.fr)
Developed by :
Johann Martinache
[@shoe_box](https://twitter.com/shoe_box)

License
-------
This work is under BSD simplified License.
