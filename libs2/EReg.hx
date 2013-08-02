/*
 * Copyright (c) 2005, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

#if (neko || cpp)
import chx.Lib;
#end

/**
	Regular expressions are a way to find regular patterns into
	Strings. Have a look at the tutorial on haXe website to learn
	how to use them.

	EReg is supported in flash before flash 9 with ExternalInterface
	calls to the haxe_support.js file which can be found in the tools
	subdirectory. This will only ensure that EReg is available in
	browsers with javascript enabled.

	@todo flash 8 full implementation of regular expressions
**/
class EReg {

	var r : Dynamic;
	#if flash9
	var result : {> Array<String>, index : Int, input : String };
	#elseif flash
	var pattern : String;
	var options : String;
	var input	: String;
	var index	: Null<Int>;
	var result	: Array<String>;
	var useChxRegEx : Bool;
	var chxRegEx : chx.RegEx;
	var chxRegExOk : Bool;
	/*
		Flash is unable to receive a JS object, so when returned to flash, the
		res.index and res.input are undefined, leaving only the array of matches.
		@param s String to match
		@param ereg Regular expression text
		@param opt Regular expression options
		@return Array with first element indicating the match index
	*/
	static var matchCode : String = "
	haxeERegMatch = function(s, ereg, opt) {
		var re = new RegExp(unescape(ereg), unescape(opt));
		var res = re.exec(unescape(s));
		if(res == null)
			return null;
		for(var i=0; i < res.length; i++)
			res[i] = escape(res[i]);
		res.unshift(res.index);
		return res;
	}";
	#end
	#if (neko || cpp || php)
	var last : String;
	var global : Bool;
	#end
	#if php
	var pattern : String;
	var options : String;
	var re : String;
	var matches : ArrayAccess<Dynamic>;
	#end


	/**
		Creates a new regular expression with pattern [r] and
		options [opt].
		@throws chx.lang.UnsupportedException in flash &lt; 9 if the haxe_support library is not available, or any other unsupported platform
	**/
	public function new( r : String, opt : String ) {
		#if (neko || cpp)
			var a = opt.split("g");
			global = a.length > 1;
			if( global )
				opt = a.join("");
			this.r = regexp_new_options(Lib.haxeStringToNeko(r), Lib.haxeStringToNeko(opt));
		#elseif js
			opt = opt.split("u").join(""); // 'u' (utf8) depends on page encoding
			this.r = untyped __new__("RegExp",r,opt);
		#elseif flash9
			this.r = untyped __new__(__global__["RegExp"],r,opt);
		#elseif flash
			pattern = StringTools.urlEncode(r);
			options = StringTools.urlEncode(opt);
			useChxRegEx = !flash.external.ExternalInterface.available;
			if(!useChxRegEx) {
				try {
					flash.ExternalInterface.call("eval("+matchCode+")");
				} catch(e:Dynamic) { useChxRegEx = true; }
			}
			if(useChxRegEx)
				chxRegEx = new chx.RegEx(r, opt);
		#elseif php
			this.pattern = r;
			var a = opt.split("g");
			global = a.length > 1;
			if( global )
				opt = a.join("");
			this.options = opt;
			this.re = "/" + untyped __php__("str_replace")("/", "\\/", r) + "/" + opt;
		#else
			throw new chx.lang.UnsupportedException("Regular expressions are not implemented for this platform");
		#end
	}

	/**
		Tells if the regular expression matches the String.
		Updates the internal state accordingly.
	**/
	public function match( s : String ) : Bool {
		#if (neko || cpp)
			var p = regexp_match(r,Lib.haxeStringToNeko(s),0,s.length);
			if( p )
				last = s;
			else
				last = null;
			return p;
		#elseif js
			untyped {
				r.m = r.exec(s);
				r.s = s;
				r.l = RegExp.leftContext;
				r.r = RegExp.rightContext;
				return (r.m != null);
			}
		#elseif flash9
			result = untyped r.exec(s);
			return (result != null);
		#elseif flash
			input = s;
			if(!useChxRegEx) {
				result = flash.external.ExternalInterface.call("haxeERegMatch", StringTools.urlEncode(s), pattern, options);
				if(result == null)
					return false;
				index = untyped result.shift();
				for(i in 0...result.length)
					result[i] = StringTools.urlDecode(result[i]);
				return true;
			} else {
				chxRegExOk = chxRegEx.match(s);
				return chxRegExOk;
			}
		#elseif php
			var p : Int = untyped __php__("preg_match")(re, s, matches, __php__("PREG_OFFSET_CAPTURE"));
			if(p > 0)
				last = s;
			else
				last = null;
			return p > 0;
		#else
			return false;
		#end
	}

	/**
		Returns a matched group or throw an expection if there
		is no such group. If [n = 0], the whole matched substring
		is returned.
	**/
	public function matched( n : Int ) : String {
		#if (neko || cpp)
			var m = regexp_matched(r,n);
			return (m == null) ? null : new String(m);
		#elseif js
			return untyped if( r.m != null && n >= 0 && n < r.m.length ) r.m[n] else throw "EReg::matched";
		#elseif flash9
			return untyped if( result != null && n >= 0 && n < result.length ) result[n] else throw "EReg::matched";
		#elseif flash
			if(!useChxRegEx) {
				return untyped if( result != null && n >= 0 && n < result.length ) StringTools.urlDecode(result[n]) else throw "EReg::matched";
			} else {
				return chxRegEx.matched(n);
			}
		#elseif php
			if( n < 0 ) throw "EReg::matched";
			// we can't differenciate between optional groups at the end of a match
			// that have not been matched and invalid groups
			if( n >= untyped __call__("count", matches)) return null;
			if(untyped __php__("$this->matches[$n][1] < 0")) return null;
			return untyped __php__("$this->matches[$n][0]");
		#else
			return null;
		#end
	}

	/**
		Returns the part of the string that was as the left of
		of the matched substring.
	**/
	public function matchedLeft() : String {
		#if (neko || cpp)
			var p = regexp_matched_pos(r,0);
			return last.substr(0,p.pos);
		#elseif js
			untyped {
				if( r.m == null ) throw "No string matched";
				if( r.l == null ) return r.s.substr(0,r.m.index);
				return r.l;
			}
		#elseif flash9
			if( result == null ) throw "No string matched";
			var s = result.input;
			return s.substr(0,result.index);
		#elseif flash
			if(!useChxRegEx) {
				if( result == null ) throw "No string matched";
				return input.substr(0, index);
			} else {
				if(chxRegExOk)
					return chxRegEx.matchedLeft();
				throw "No string matched";
			}
		#elseif php
			if( untyped __call__("count", matches) == 0 ) throw "No string matched";
			return last.substr(0, untyped __php__("$this->matches[0][1]"));
		#else
			return null;
		#end
	}

	/**
		Returns the part of the string that was at the right of
		of the matched substring.
	**/
	public function matchedRight() : String {
		#if (neko || cpp)
			var p = regexp_matched_pos(r,0);
			var sz = p.pos+p.len;
			return last.substr(sz,last.length-sz);
		#elseif js
			untyped {
				if( r.m == null ) throw "No string matched";
				if( r.r == null ) {
					var sz = r.m.index+r.m[0].length;
					return r.s.substr(sz,r.s.length-sz);
				}
				return r.r;
			}
		#elseif flash9
			if( result == null ) throw "No string matched";
			var rl = result.index + result[0].length;
			var s = result.input;
			return s.substr(rl,s.length - rl);
		#elseif flash
			if(!useChxRegEx) {
				if( result == null ) throw "No string matched";
				var rl = index + result[0].length;
				return input.substr(rl, input.length - rl);
			} else {
				if(chxRegExOk)
					return chxRegEx.matchedRight();
				throw "No string matched";
			}
		#elseif php
			if( untyped __call__("count", matches) == 0 ) throw "No string matched";
			return untyped last.substr(__php__("$this->matches[0][1]") + __php__("strlen")(__php__("$this->matches[0][0]")));
		#else
			return null;
		#end
	}

	/**
		Returns the position of the matched substring within the
		original matched string.
	**/
	public function matchedPos() : { pos : Int, len : Int } {
		#if (neko || cpp)
			return regexp_matched_pos(r,0);
		#elseif js
			if( untyped r.m == null ) throw "No string matched";
			return untyped { pos : r.m.index, len : r.m[0].length };
		#elseif flash9
			if( result == null ) throw "No string matched";
			return { pos : result.index, len : result[0].length };
		#elseif flash
			if(!useChxRegEx) {
				if( result == null ) throw "No string matched";
				return { pos : index, len : result[0].length };
			} else {
				if( !chxRegExOk ) throw "No string matched";
				return chxRegEx.matchedPos();
			}
		#elseif php
			return untyped { pos : __php__("$this->matches[0][1]"), len : __php__("strlen")(__php__("$this->matches[0][0]")) };
		#else
			return null;
		#end
	}

	/**
		Split a string by using the regular expression to match
		the separators.
	**/
	public function split( s : String ) : Array<String> {
		#if (neko || cpp)
			var pos = 0;
			var len = s.length;
			var a = new Array();
			var first = true;
			do {
				if( !regexp_match(r,Lib.haxeStringToNeko(s),pos,len) )
					break;
				var p = regexp_matched_pos(r,0);
				if( p.len == 0 && !first ) {
					if( p.pos == s.length )
						break;
					p.pos += 1;
				}
				a.push(s.substr(pos,p.pos - pos));
				var tot = p.pos + p.len - pos;
				pos += tot;
				len -= tot;
				first = false;
			} while( global );
			a.push(s.substr(pos,len));
			return a;
		#elseif (js || flash9 || flash)
			// we can't use directly s.split because it's ignoring the 'g' flag
			var d = "#__delim__#";
			return untyped s.replace(r,d).split(d);
		#elseif php
			return untyped __php__("new _hx_array(preg_split($this->re, $s, $this->hglobal ? -1 : 2))");
		#else
			return null;
		#end
	}

	/**
		Replaces a pattern by another string. The [by] format can
		contains [$1] to [$9] that will correspond to groups matched
		while replacing. [$$] means the [$] character.
	**/
	public function replace( s : String, by : String ) : String {
		#if (neko || cpp)
			var b = new StringBuf();
			var pos = 0;
			var len = s.length;
			var a = by.split("$");
			var first = true;
			do {
				if( !regexp_match(r,Lib.haxeStringToNeko(s),pos,len) )
					break;
				var p = regexp_matched_pos(r,0);
				if( p.len == 0 && !first ) {
					if( p.pos == s.length )
						break;
					p.pos += 1;
				}
				b.addSub(s,pos,p.pos-pos);
				if( a.length > 0 )
					b.add(a[0]);
				var i = 1;
				while( i < a.length ) {
					var k = a[i];
					var c = k.charCodeAt(0);
					// 1...9
					if( c >= 49 && c <= 57 ) {
						var p = try regexp_matched_pos(r,c-48) catch( e : String ) null;
						if( p == null ){
							b.add("$");
							b.add(k);
						}else{
						b.addSub(s,p.pos,p.len);
						b.addSub(k,1,k.length - 1);
						}
					} else if( c == null ) {
						b.add("$");
						i++;
						var k2 = a[i];
						if( k2 != null && k2.length > 0 )
							b.add(k2);
					} else
						b.add("$"+k);
					i++;
				}
				var tot = p.pos + p.len - pos;
				pos += tot;
				len -= tot;
				first = false;
			} while( global );
			b.addSub(s,pos,len);
			return b.toString();
		#elseif (js || flash9 || flash)
			return untyped s.replace(r,by);
		#elseif php
			by = untyped __call__("str_replace", "$$", "\\$", by);
			untyped __php__("if(!preg_match('/\\\\([^?].+?\\\\)/', $this->re)) $by = preg_replace('/\\$(\\d+)/', '\\\\\\$\\1', $by)");
			return untyped __php__("preg_replace")(re, by, s, global ? -1 : 1);
		#else
			return null;
		#end
	}

	/**
		For each occurence of the pattern in the string [s], the function [f] is called and
		can return the string that needs to be replaced. All occurences are matched anyway,
		and setting the [g] flag might cause some incorrect behavior on some platforms.
	**/
	public function customReplace( s : String, f : EReg -> String ) : String {
		var buf = new StringBuf();
		while( true ) {
			if( !match(s) )
				break;
			buf.add(matchedLeft());
			buf.add(f(this));
			s = matchedRight();
		}
		buf.add(s);
		return buf.toString();
	}

#if (neko || cpp)
	static var regexp_new_options = chx.Lib.load("regexp","regexp_new_options",2);
	static var regexp_match = chx.Lib.load("regexp","regexp_match",4);
	static var regexp_matched = chx.Lib.load("regexp","regexp_matched",2);
	static var regexp_matched_pos : Dynamic -> Int -> { pos : Int, len : Int } = chx.Lib.load("regexp","regexp_matched_pos",2);
#end

}
