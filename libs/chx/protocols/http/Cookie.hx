/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
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

package chx.protocols.http;
import dates.GmtDate;

// TODO: Finish Cookie V1
class Cookie {

	public var name(getName,setName)			: String;
	public var value(getValue,setValue)			: Dynamic;
	public var comment(getComment,setComment)	: String;
	public var domain(getDomain,setDomain)		: String;
	public var expires(getExpires,setExpires)	: Date;
	public var max_age(getMaxAge,setMaxAge)		: Int;
	public var path(getPath,setPath)			: String;

	public var secure(getSecure,setSecure)		: Bool;
	public var version(getVersion,setVersion)	: Int;

	/**
		Create a new cookie. Will throw if the name is invalid.
	*/
	public function new(name:String, value:String) {
		this.name = name;
		this.value = value;
		expires = null;
		max_age = -1;
		path = null;
		domain = null;
		secure = false;
		version = 0;
	}

	public function getName() : String { return name; }
	public function setName(str:String) : String { name = str; return name; }

	public function getValue() : Dynamic { return value; }
	public function setValue(str:Dynamic) : Dynamic { value = str; return value; }

	public function getComment() { return comment; }
	public function setComment(str:String) : String {
		setVersion(1);
		comment = str;
		return comment;
	}

	public function getDomain() : String { return domain; }
	public function setDomain(str:String) : String { domain = str; return domain; }

	public function getExpires() : Date { return expires; }
	public function setExpires(d:Date) : Date { expires = d; return expires; }

	/**
		Get maximum age in seconds. If no max was specified, returns
		-1
	*/
	public function getMaxAge() : Int { return max_age; }
	/**
		Set the max age in seconds for this cookie. To
		set no max age, specify -1
	*/
	public function setMaxAge(v:Int): Int {
		if(v < 0) v = -1;
		max_age = v;
		return max_age;
	}

	public function getPath() : String  { return path; }
	public function setPath(str:String) : String { path = str; return path; }

	public function getSecure() : Bool { return secure; }
	public function setSecure(v:Bool) : Bool { secure = v; return secure;}

	public function getVersion() : Int { return version; }
	public function setVersion(v:Int) : Int {
		if(v != 0 && v != 1)
			throw "Invalid cookie version";
		version = v;
		return version;
	}

	/**
		Parse cookies from a http request header. The header string
		may include the "Set-Cookie: " or "Cookie: " prefix which is
		stripped if it's included.
	**/
	public static function fromString(cs:String) : Array<Cookie> {
		var cookielist = new Array<Cookie>();
		var eReg = ~/^[Set-]*Cookie: /gi;
		cs = eReg.replace(cs,"");

		var tags = StringTools.trim(cs).split(";");
		var cookie : Cookie = null;
		for(t in tags) {
			t = StringTools.trim(t);
			var nameValue = t.split("=");
			nameValue[0] = StringTools.trim(nameValue[0]);
			var attr = StringTools.urlDecode(nameValue[0]).toLowerCase();
			var value = StringTools.urlDecode(nameValue[1]);
			switch(attr) {
			case "comment": // V1
				if(cookie != null) {
					cookie.setVersion(1);
					cookie.setComment(value);
				}
			case "domain":  // both
				if(cookie != null)
					cookie.setDomain(value);
			case "expires": // V0
				if(cookie != null) {
					try {
						cookie.expires = GmtDate.fromString(value).getLocalDate();
					}
					catch(e:Dynamic) {
						cookie.expires = null;
					}
				}
			case "max-age": // V1
				if(cookie != null) {
					cookie.setVersion(1);
					cookie.setMaxAge(Std.parseInt(value));
				}
			case "path": // BOTH
				if(cookie != null)
					cookie.setPath(value);
			case "secure": // BOTH
				if(cookie != null)
					cookie.setSecure(true);
			case "version": // V1 only
				if(cookie != null)
					cookie.setVersion(Std.parseInt(value));
			default:
				if(cookie != null)
					cookielist.push(cookie);
				cookie = new Cookie(nameValue[0], nameValue[1]);
			}
		}
		if(cookie != null)
			cookielist.push(cookie);

		return cookielist;
	}

	/**
		Return a cookie header line for sending to web browser
		From a web script/webserver, syntax is "Set-Cookie: name=val[; ...]"
	*/
	public function toString() {
		var cs = new StringBuf();
		cs.add("Set-Cookie: ");
		cs.add(Cookie.bodyString(this));
		return cs.toString();
	}

	/**
		Return cookie header for sending to a http server.
		From a web browser, syntax is "Cookie: name=val[; ...]"
	*/
	public function toClientString() {
		var cs = new StringBuf();
		cs.add("Cookie: ");
		cs.add(Cookie.bodyString(this));
		return cs.toString();
	}

	/**
		Generate only the body of the cookie, that is the
		part not including the Cookie: or Set-Cookie: part.
	*/
	public static function bodyString(c:Cookie) : StringBuf {
		var buf = new StringBuf();
		buf.add(StringTools.urlEncode(c.getName()));
		buf.addChar(61);
		buf.add(StringTools.urlEncode(c.getValue()));
		if(c.getExpires() != null) {
			buf.add("; expires=");
			buf.add(GmtDate.timestamp(c.getExpires()));
			//buf.add(c.getExpires().rfc822timestamp());
		}
		if(c.getPath() != null) {
			buf.add("; path=");
			buf.add(StringTools.urlEncode(c.getPath()));
		}
		if(c.getDomain() != null) {
			buf.add("; domain=");
			buf.add(StringTools.urlEncode(c.getDomain()));
		}
		if(c.getSecure()) {
			buf.add("; secure");
		}
		return buf;
	}

	/**
		This creates a single Cookie line from a set of cookies.
		By default, the cookie line is assumed to be coming from
		the server, sent to the web browser. If you wish to send
		a Cookie: line from a web browser client, set fromClient
		to true.
	*/
	public static function toSingleLineString(cookies:Array<Cookie>, ?fromClient:Bool) : String {
		var buf = new StringBuf();
		if(!fromClient)
			buf.add("Set-Cookie: ");
		else
			buf.add("Cookie: ");
		var initial : Bool = true;
		for(i in cookies) {
			if(initial)
				initial = false;
			else
				buf.add(", ");
			buf.add(bodyString(i));
		}
		return buf.toString();
	}
}