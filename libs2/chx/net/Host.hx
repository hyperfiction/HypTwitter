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
 *
 */
package chx.net;

class Host {
#if php
	private var _ip : String;
#end
	public var ip(default,null) : haxe.Int32;
	var name : String;

	public function new( name : String ) {
		#if neko
			ip = host_resolve(untyped name.__s);
		#elseif cpp
			ip = host_resolve(name);
		#elseif php
			if(~/^(\d{1,3}\.){3}\d{1,3}$/.match(name)) {
				_ip = name;
			} else {
				_ip = untyped __call__('gethostbyname', name);
				if(_ip == name) {
					ip = haxe.Int32.ofInt(0);
					return;
				}
			}
			var p = _ip.split('.');
			ip = haxe.Int32.ofInt(untyped __call__('intval', __call__('sprintf', '%02X%02X%02X%02X', p[3], p[2], p[1], p[0]), 16));
		#else
			ip = haxe.Int32.ofInt(0);
		#end
		this.name = name;
	}

	public function toString() : String {
		#if (neko || cpp)
			return new String(host_to_string(ip));
		#elseif php
			return _ip;
		#else
			return name;
		#end
	}

	public function reverse() {
		#if (neko || cpp)
			return new String(host_reverse(ip));
		#elseif php
			return untyped __call__('gethostbyaddress', _ip);
		#else
			return name;
		#end
	}

	public static function localhost() : String {
		#if (neko || cpp)
			return new String(host_local());
		#elseif php
			return untyped __var__('_SERVER', 'HTTP_HOST');
		#else
			return "127.0.0.1";
		#end
	}

#if (neko || cpp)
	static function __init__() {
		chx.Lib.load("std","socket_init",0)();
	}

	private static var host_resolve = chx.Lib.load("std","host_resolve",1);
	private static var host_reverse = chx.Lib.load("std","host_reverse",1);
	private static var host_to_string = chx.Lib.load("std","host_to_string",1);
	private static var host_local = chx.Lib.load("std","host_local",0);
#end

}
