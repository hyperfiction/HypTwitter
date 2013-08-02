/*
 * Copyright (c) 2009, The Caffeine-hx project contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chx.net;

import chx.lang.UriFormatException;

/**
	Class for building and parsing URIs.
	[
		var uri = new URI;
		uri.setHost("www.foo.com").setPort(80).setUserInfo("me:mypass");

		var relUri = URI.parse("subdir/file.html", uri);
	]

	@see http://www.ietf.org/rfc/rfc2396.txt
	@see For correct interpretation of {@link http://blogs.msdn.com/ie/archive/2006/12/06/file-uris-in-windows.aspx uris in windows}
	@todo Test parser
	@todo No IPv6 support yet
	@see {@link http://www.ietf.org/rfc/rfc2396.txt rfc2396}
	@author rweir
**/
class URI {
	public static var mark : String		= "-_.!~*'()";
	public static var punct: String		= ",;:$&+=";
	public static var unwise : String	= "{}|\\^[]`";

	// in order
	public var scheme(default, setSchemeInt)	: String;
	public var authority(default, null)			: String;
	public var userInfo(default, setUserInfoInt): String;
 	public var host(default, setHostInt)		: String;
	/** Will be null if not a valid port **/
	public var port(default, setPortInt)		: Null<Int>;
	public var path(default, setPathInt)		: String;
	public var query(default, null)				: String;
	public var fragment(default, null)			: String;

	// combination
	//public var schemeSpecific(default, null)	: String;

	public var context(default, null)			: URI;

	public function new() {
		port = null; // all others undefined as null
	}

	/**
		Same as in .net, set to true if the URI could be considered
		to be a Windows UNC
	**/
	public function isUnc() {
		return (scheme == "file" && host != null);
	}

	public function isWindowsDrivePath() : Bool {
		return ~/^(\/[a-z]:)/.match(this.path);
	}

	/**
		Extract a windows drive letter from the uri
		@returns Windows drive letter, with no trailing : (ie 'c'), or null
	**/
	public function getWindowsDrive() : String {
		var e = ~/^\/([a-z]:)/i;
		if(!e.match(this.path))
			return null;
		return e.matched(1);
	}

	/**
		Return a windows path, without the drive letter, with / transformed to \
	**/
	public function getWindowsPath() : String {
		var e = ~/^\/([a-z]:)/i;
		if(!e.match(this.path))
			return null;
		return StringTools.replace(e.matchedRight(), "/", "\\");
	}

	/**
		Set the host component. This method is the same as setting the
		host property.
		@param v A host name or ip address
		@returns Reference to this instance for chaining.
	**/
	public function setHost(v : String) : URI {
		this.host = v;
		return this;
	}

	/**	Internal host setting **/
	function setHostInt(v : String) : String {
		if(v == null || v.length == 0)
			this.host = null;
		else
			this.host = v;
		updateAuthority();
		return v;
	}

	/**
		Set the path component. This method is the same as setting the
		path property.
		@param v A host name or ip address
		@returns Reference to this instance for chaining.
	**/
	function setPath(v : String) : URI {
		this.path = v;
		return this;
	}

	function setPathInt(v : String) : String {
		this.path = escapePath(v);
		return v;
	}

	/**
		Takes any path, replaces all instances of \ with /, then any character
		not in unreserved, or escaped is replace with encoding, excepting @ and /
	**/
	static function escapePath(path : String) : String {

		var p = StringTools.replace(StringTools.urlDecode(path), "\\", "/");
trace("escapePath 1: " + p );
		p = StringTools.urlEncode(p);
trace("escapePath 2: " + p);

		// unreserved = alnum + mark
		// mark = "-" | "_" | "." | "!" | "~" | "*" | "'" | "(" | ")"
		// additional ",;:$&+="
		p = urlUnencodeChars(p, "@/" + mark + punct);
		p = urlEncodeChars(p, unwise);
trace("escapePath: " + p);
		return p;
	}

	/**
		Url unencode only the characters in array [a] in string [source].
		@param source A string
		@param a A string of single characters to unencode
		@todo Move to StringTools
	**/
	static function urlUnencodeChars(source: String, a : String) : String {
		for(i in 0...a.length) {
			var enc = "%" + StringTools.hex(a.charCodeAt(i), 2);
			var ereg = new EReg(enc, "ig");
			source = ereg.replace(source, a.charAt(i));
		}
		return source;
	}

	/**
		Url encode only the characters in array [a] in string [source].
		@param source A string
		@param a A string of single characters to encode
		@todo Move to StringTools
	**/
	static function urlEncodeChars(source : String, a : String) : String {
		for(i in 0...a.length) {
			var rep = "%" + StringTools.hex(a.charCodeAt(i), 2);
			var ereg = new EReg(regexEncode(a.charAt(i)), "g");
			source = ereg.replace(source, rep);
		}
		return source;
	}

	/**
		Escape single character for use in EReg constructor calls
		@param c A single character
		@throws chx.lang.FatalException if c is not length 1
		@todo Move to EReg or StringTools
	**/
	static function regexEncode(c : String) : String {
		if(c.length != 1)
			throw new chx.lang.FatalException(c + " should be a single char");
		return switch(c) {
		case "[": "\\[";
		case "]": "\\]";
		case "(": "\\(";
		case ")": "\\)";
		case "\\": "\\\\";
		case "|": "\\|";
		case "^": "\\^";
		default:
			c;
		}
	}

	/**
		Set the port number. This method is the same as setting the
		[port] property.
		@param v A port number or null. If port < 0 it is considered invalid.
		@returns Reference to this instance for chaining.
	**/
	public function setPort(v : Null<Int>) : URI {
		this.port = v;
		return this;
	}

	/** internal port setting **/
	function setPortInt(v : Null<Int>) : Null<Int> {
		if(v != null && v >= 0)
			this.port = v;
		else
			this.port = null;
		updateAuthority();
		return v;
	}

	/**
		Set the scheme, which will be set to lower case for consistency.
		This method is the same as setting the [scheme] property.
		@param v A valid scheme alpha *( alpha | digit | "+" | "-" | "." )
		@returns Reference to this instance for chaining.
	**/
	public function setScheme( v : String) : URI {
		this.scheme = v;
		return this;
	}

	/**
		@throws chx.lang.UriFormatException if the scheme is invalid
	**/
	function setSchemeInt(v : String) : String {
		//
		if(v == null || v.length == 0) {
			this.scheme = null;
		}
		else {
			v = v.toLowerCase();
			var e = ~/^[a-z]+[a-z0-9+\-\.]*/;
			if(! e.match(v))
				throw new UriFormatException("invalid scheme");
			this.scheme = v;
		}
		return v;
	}

	/**
		Set the user information. This method is the same as setting the
		[userInfo] property, but returns a reference to this URI instance.
		[
		*( unreserved | escaped | ";" | ":" | "&" | "=" | "+" | "$" | "," )
		unreserved    = alphanum | mark
		mark  = "-" | "_" | "." | "!" | "~" | "*" | "'" | "(" | ")"
		escaped = % hex hex
		]
		@param v user information
		@returns Reference to this instance for chaining.
	**/
	public function setUserInfo(v : String) : URI {
		this.userInfo = v;
		return this;
	}

	function setUserInfoInt(v : String) : String {

		if(v == null || v.length == 0) {
			this.userInfo = null;
		}
		else {
			if(! ~/^([a-z0-9;:&=+\$,\-_\.!~\*'\(\)]|%[0-9a-f][0-9a-f])+$/i.match(v))
				throw new UriFormatException("invalid user info");
			this.userInfo = v;
		}
		updateAuthority();
		return v;
	}

	function updateAuthority() : Void {
		var auth = "";
		if(userInfo != null) {
			auth += userInfo;
			auth += "@";
		}
		if(host != null)
			auth += host;
		if(port != null && port >= 0)
			auth += ":" + Std.string(port);
		if(auth.length > 0) {
			authority = auth;
		}
		else {
			if(isUnc())
				authority = "";
			else
				authority = null;
		}
	}


	//RFC 2396, section 5.2, step 7,
	public function toString2() : String {
		var uri : String = "";
		if(scheme != null)
			uri += scheme + ":";
		if(authority != null) {
			uri += "//";
			uri += authority;
		}

		if(path != null)
			uri += path;

		if(query != null) {
			uri += "?";
			uri += StringTools.urlEncode(query);
		}

		if(fragment != null) {
			uri += "#";
			uri += StringTools.urlEncode(fragment);
		}
		return uri;
	}

	/**
		Parses a full uri string and returns a Uri instance
		@param uri Full uri string (ex. mailto:john@foo.com or http://foo.com/index.html)
		@param context Another URI that forms the base context for the new one
		@returns new Uri instance
		@todo rfc2396 3.2.1 authority
		@throws chx.lang.UriFormatException if the uri is invalid
	**/
	public static function parse(uri : String, ?context:URI) : URI {
		var u = new URI();
		u.context = context;

		try {
			var e= ~/^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/;
			if(!e.match(uri))
				throw "uri invalid";
			//
			trace("====");
			trace("PARSING " + uri);
			trace("scheme: " + e.matched(2));
			trace(": " + e.matched(3));
			trace("authority: " + e.matched(4));
			trace("path: " + e.matched(5));
			trace(": " + e.matched(6));
			trace("query: " + e.matched(7));
			trace(": " + e.matched(8));
			trace("fragment: " + e.matched(9));
			trace("====");
			//

			u.scheme = e.matched(2);
			var auth = e.matched(4);
			u.path = e.matched(5);
			u.query = e.matched(7);
			u.fragment = e.matched(9);

			// parse userInfo, host and port
			if(auth != null) {
				// todo 3.2.1 here

				// 3.2.2 <userinfo>@<host>:<port>
				var e = ~/^(([^\/\?@]+)@)?([A-Za-z\.0-9\-]*)?(:([0-9]+))?/;
				if(!e.match(auth))
					throw "authority invalid";
				u.userInfo = e.matched(2);
				u.host = e.matched(3);
				if(u.host == null)
					throw "invalid host";
				if(e.matched(5) != null) {
					u.port = Std.parseInt(e.matched(5));
					if(u.port == null)
						throw "invalid port";
				}
			}

			var isUnc = ((context == null || context.isUnc()) &&
						(StringTools.startsWith(uri, "\\\\") || StringTools.startsWith(uri, "//")));

			if(u.scheme != null) {
				// Windows Drive
				if(~/^([a-z])$/.match(u.scheme)) {
					if(u.path == null)
						u.path = "/" + u.scheme + ":/";
					else
						u.path = "/" + u.scheme + ":" + ~/\\/g.replace(u.path,"/");
					u.scheme = "file";
				}
			} else {
				// Windows UNC host
				if(isUnc) {
					var ereg = ~/^\/\/([^\/]+)(\/)?/;
					if(!ereg.match(u.path)) {
						ereg = ~/^\\\\([^\\]+)(\\)?/;
						if(!ereg.match(u.path))
							throw "invalid unc host " + u.path;
					}
					u.scheme = "file";
					u.host = ereg.matched(1);
					u.path = "/" + ereg.matchedRight();
				}
			}
		}
		catch(e : UriFormatException) {
			throw new UriFormatException(e.message);
		}
		catch(e : Dynamic) {
			throw new UriFormatException(Std.string(e));
		}

		return u;
	}

	/**
		Creates a URI by first creating a string version, which is then passed through parse() to return the resulting URI instance. Any param may be null.
		@param scheme URI scheme (ex. http)
		@param userInfo User information (ex. user:password)
		@param host Hostname. No support for IPv6 yet.
		@param port Port number, null or <0 for no port
		@param path Path part
		@param query Part that would be after a ? in a web url
		@param fragment A URI fragment (ex. top)
		@todo Check quoting of path param
	**/
	public static function create(
				scheme : String,
				userInfo : String,
				host : String,
				port : Null<Int>,
				path : String,
				query : String,
				fragment : String) : URI
	{
		var u = new URI();
		u.scheme = scheme;
		u.userInfo = userInfo;
		u.host = host;
		u.port = port;
		u.path = path;
		u.query = query;
		u.fragment = fragment;
		return parse(u.toString2());
	}

	/**
		http://www.foo.com/subdir/file.html#top
		@param scheme URI scheme (ex. http)
		@param host URI hostname (ex. www.foo.com)
		@param path URI path part (ex. /subdir/file.html)
		@param fragment URI fragment (ex. top)
		@returns new Uri instance
	**/
	public static function createShort(scheme : String, host : String, path : String, fragment : String) : URI {
		return create(scheme, null, host, null, path, null, fragment);
	}
}