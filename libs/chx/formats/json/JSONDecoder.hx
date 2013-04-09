/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Ritchie Turner, Copyright (c) 2007 ritchie@blackdog-haxe.com
 * Contributors: Russell Weir, Danny Wilson
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

/*
 * The Software shall be used for Good, not Evil.
 *
 * Updated for haxe by ritchie turner
 * Copyright (c) 2007 ritchie@blackdog-haxe.com
 *
 * There are control character things I didn't bother with.
 */

/*
 * Danny: added control character support based on: http://www.json.org/json2.js
 */

package chx.formats.json;

class JSONDecoder {

	var at:Int;
	var ch:String;
	var text:String;

	public function new() {}

	/**
		It is safe to continur reusing this method to parse JSON strings
	**/
	public function parse(text:String):Dynamic {
		if(text == null || text == "")
			return {};
// 		try {
			at = 0 ;
			ch = '';
			this.text = text ;
			return value();
// 		}
// 		catch(e : JSONException) {
// 			throw(e);
// 		}
// 		catch (e : Dynamic) {
// 			throw(new JSONException("unhandled error "+Std.string(e)));
// 		}
		return {};
	}

	function error(m):Void {
		throw new JSONException(m, at-1, text);
	}

	function next() {
		ch = text.charAt(at);
		at += 1;
		if (ch == '') return ch = null;
		return ch;
	}

	function white() {
		while (ch != null) {
			if (at == 0 || ch <= ' ') {
				next();
			} else if (ch == '/') {
				switch (next()) {
					case '/':
						while (next() != null && ch != '\n' && ch != '\r') {}
						break;
					case '*':
						next();
						while (true) {
							if (ch == null)
								error("Unterminated comment");

							if (ch == '*' && next() == '/') {
								next();
								break;
							} else {
								next();
							}
						}
						break;
					default:
						error("Syntax error - whitespace");
				}
			} else {
				break;
			}
		}
	}

	function str():String {
		var s = new StringBuf(), t:Int, u:Int;
		var outer:Bool = false;

		if (ch != '"') {
			error("This should be a quote");
			return '';
		}

		while (next() != null) {
			if (ch == '"') {
				next();
				return s.toString();
			} else if (ch == '\\') {
				switch (next()) {
				case 'n': s.addChar(10);	// += '\n';
				case 'r': s.addChar(13);	// += '\r';
				case 't': s.addChar(9);		// += '\t';
				case 'u': // unicode
					u = 0;
					for (i in 0...4) {
						t = Std.parseInt(next());
						if (!Math.isFinite(t)) {
							outer = true;
							break;
						}
						u = u * 16 + t;
					}
					if(outer) {
						outer = false;
						break;
					}
					#if neko
						var utf = new neko.Utf8(4); utf.addChar(u);
						s.add(utf.toString());
					#elseif true
						s.addChar(u);
					#end
				default:
					s.add(ch);
				}
			} else {
				s.add(ch);
			}
		}
		error("Bad string");
		return s.toString();
	}

	function arr():Array<Dynamic> {
		var a = [];

		if (ch == '[') {
			next();
			white();
			if (ch == ']') {
				next();
				return a;
			}
			while (ch != null) {
				var v:Dynamic;
				v = value();
				a.push(v);
				white();
				if (ch == ']') {
					next();
					return a;
				} else if (ch != ',') {
					break;
				}
				next();
				white();
			}
		}
		error("Bad array");
		return []; // never get here
	}

	function obj():Dynamic {
		var k;
		var o = {};

		if (ch == '{') {
			next();
			white();
			if (ch == '}') {
				next();
				return o;
			}
			while (ch != null) {
				k = str();
				white();
				if (ch != ':') {
					break;
				}
				next();
				var v:Dynamic;
				v = value();
				Reflect.setField(o,k,v);

				white();
				if (ch == '}') {
					next();
					return o;
				} else if (ch != ',') {
					break;
				}
				next();
				white();
			}
		}
		error("Bad object");
		return o;
	}

	function num():Float {
		var n = '';
		var v:Float;

		if (ch == '-') {
			n = '-';
			next();
		}
		while (ch >= '0' && ch <= '9') {
			n += ch;
			next();
		}
		if (ch == '.') {
			n += '.';
			next();
			while (ch >= '0' && ch <= '9') {
				n += ch;
				next();
			}
		}
		if (ch == 'e' || ch == 'E') {
			n += ch;
			next();
			if (ch == '-' || ch == '+') {
				n += ch;
				next();
			}
			while (ch >= '0' && ch <= '9') {
				n += ch;
				next();
			}
		}
		v = Std.parseFloat(n);
		if (!Math.isFinite(v)) {
			error("Bad number");
		}
		return v;
	}

	function word():Null<Bool> {
		switch (ch) {
			case 't':
				if (next() == 'r' && next() == 'u' &&
						next() == 'e') {
					next();
					return true;
				}
			case 'f':
				if (next() == 'a' && next() == 'l' &&
						next() == 's' && next() == 'e') {
					next();
					return false;
				}
			case 'n':
				if (next() == 'u' && next() == 'l' &&
						next() == 'l') {
					next();
					return null;
				}
		}
		error("Syntax error - word");
		return false; // never get here
	}

	function value():Dynamic {
		white();
		var v:Dynamic;
		switch (ch) {
			case '{':	v = obj();
			case '[':	v = arr();
			case '"':	v = str();
			case '-':	v = num();
			default:
				if (ch >= '0' && ch <= '9')
					v = num();
				else
					v = word();
		}
		return v;
	}

}
