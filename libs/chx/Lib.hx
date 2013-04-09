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

package chx;
import chx.io.StringOutput;
import chx.lang.FatalException;

/**
	Common library functions.
**/
class Lib {

	/**
	 * Load a dynamic library.
	 * @param	lib
	 * @param	prim
	 * @param	nargs
	 * @return
	 * @todo Flash: url loader to swf libs
	 * @todo JS: possibilities?
	 */
	public static function load( lib : String, prim : String, nargs : Int ) : Dynamic {
		#if cpp
			#if iphone
				return loadLazy(lib,prim,nargs);
			#else
				return untyped __global__.__loadprim(lib,prim,nargs);
			#end
		#elseif neko
			return untyped __dollar__loader.loadprim((lib + "@" + prim).__s, nargs);
		#else
			return null;
		#end
	}
	
	/**
	 * Tries to load a dynamic library, and always returns a valid function, 
	 * but the function may throw if called.
	 * @param	lib
	 * @param	prim
	 * @param	nargs
	 * @return
	 */
	public static function loadLazy(lib : String, prim : String, nargs : Int) : Dynamic {
		#if cpp
			try {
				return untyped __global__.__loadprim(lib,prim,nargs);
			} catch( e : Dynamic ) {
				switch(nargs) {
				case 0 : return function() { throw e; };
				case 2 : return function(_1,_2) { throw e; };
				case 3 : return function(_1,_2,_3) { throw e; };
				case 4 : return function(_1,_2,_3,_4) { throw e; };
				case 5 : return function(_1,_2,_3,_4,_5) { throw e; };
				default : return function(_1) { throw e; };
				}
			}
		#elseif neko
			try {
				return load(lib,prim,nargs);
			} catch( e : Dynamic ) {
				return untyped __dollar__varargs(function(_) { throw e; });
			}
		#else
			return null;
		#end
	}

	/**
	 * Rethrow an exception. This is useful when manually filtering an exception in order
	 * to keep the previous exception stack.
	 * @param	e
	 * @return
	 */
	public static function rethrow( e : Dynamic ) : Dynamic {
		#if neko
			return untyped __dollar__rethrow(e);
		#elseif php
			if(Std.is(e, php.Exception)) {
				var __rtex__ = e;
				untyped __php__("throw $__rtex__");
			}
			else throw e;
		#else
			throw e;
		#end
	}

	/**
	 * Print the specified value on the default output.
	 * @param	v
	 * @todo better interface for traced platforms
	 */
	public static function print( v : Dynamic ) : Void {
		#if neko
			untyped __dollar__print(v);
		#elseif cpp
			untyped __global__.__hxcpp_print(v);
		#elseif php
			untyped __call__("echo", Std.string(v));
		#else
			trace(v);
		#end
	}

	/**
	 * Print the specified value on the default output followed by a newline character.
	 * @param	v
	 * @todo See print
	 */
	public static function println( v : Dynamic ) : Void {
		#if neko
			untyped __dollar__print(v, "\n");
		#elseif cpp
			untyped __global__.__hxcpp_println(v);
		#elseif php
			untyped __call__("echo", Std.string(v) + "\n");
		#else
			trace(v);
		#end
	}
	
	/**
	 * Returns a string referencing the data contains in bytes.
	 * @param	b
	 */
	public inline static function stringReference( b : Bytes ) {
		#if cpp
			throw b;
		#else
			return new String( cast b.getData() );
		#end
	}

	/**
	 * Returns bytes referencing the content of a string.
	 * @param	s
	 * @return
	 * @todo test
	 */
	public inline static function bytesReference( s : String ) : Bytes {
		#if neko
			return untyped new Bytes( s.length, s.__s );
		#elseif php
			return untyped new Bytes(untyped __call__("strlen", s), cast s);
		#else
			return throw new FatalException("unimplemented");
		#end
	}

	/**
	 * Serialize using native serialization. This will return a Binary string that can be
	 * stored for long term usage. The serialized data is optimized for speed and not for size.
	 * @param	v
	 * @return
	 */
	public static function serialize( v : Dynamic ) : String {
		#if neko
			return new String(__serialize(v));
		#elseif php
			return untyped __call__("serialize", v);
		#else
			var so = new StringOutput();
			Serializer.run(v, so);
			return so.toString();
		#end
	}


	/**
	 * Unserialize a string using native serialization. See [serialize].
	 * @param	s
	 * @return
	 */
	public static function unserialize( s : String ) : Dynamic {
		#if neko
			return untyped __unserialize(s.__s, __dollar__loader);
		#elseif php
			return untyped __call__("unserialize", s);
		#else
			return Unserializer.run(s);
		#end
	}

	static var dll_init : Hash<Bool>;
	/**
	 * For platforms that require initialization of loaded libraries. This is required when
	 * using ndlls generated with hxcpp for neko
	 * @param libName Short name for lib, without .ndll extension
	 * @param entryFunc Library init function. If not provided, will be libName_init
	 */
	public static function initDll(libName:String, entryFunc : String = null) : Void {
		if(dll_init == null)
			dll_init = new Hash();
		if(dll_init.exists(libName))
			return;
		var init : Dynamic = null;

		#if neko
			init = chx.Lib.load(libName, "neko_init", 5);
			if(init == null)
				throw("Could not find NekoAPI interface.");

			//neko_init(inNewString,inNewArray,inNull,inTrue,inFalse)
			init(function(s) return new String(s),
					function(len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; },
					null, true, false);

		#end
		if(entryFunc == null)
			entryFunc = libName + "_init";
		init = chx.Lib.load(libName, entryFunc, 0);
		if(init != null)
			init();
		dll_init.set(libName, true);
	}

#if (neko || cpp)
	public static inline function nekoStringToHaxe( v : String ) : String {
		return
		#if cpp
			v;
		#elseif neko
			new String(v);
		#end
	}

	public static inline function haxeStringToNeko( v : String ) : String {
		return
		#if cpp
			v;
		#elseif neko
			untyped v.__s;
		#end
	}

	/**
	 * Converts a Neko value to its haXe equivalent. Used for wrapping String and Arrays raw values into haXe Objects.
	 * @param	v
	 * @return
	 */
	public static function nekoToHaxe( v : Dynamic ) : Dynamic untyped {
		#if cpp
			return v;
		#elseif neko
			switch( __dollar__typeof(v) ) {
			case __dollar__tnull: return v;
			case __dollar__tint: return v;
			case __dollar__tfloat: return v;
			case __dollar__tbool: return v;
			case __dollar__tstring: return new String(v);
			case __dollar__tarray:
				var a = Array.new1(v,__dollar__asize(v));
				for( i in 0...a.length )
					a[i] = nekoToHaxe(a[i]);
				return a;
			case __dollar__tobject:
				var f = __dollar__objfields(v);
				var i = 0;
				var l = __dollar__asize(f);
				var o = __dollar__new(v);
				if( __dollar__objgetproto(v) != null )
					throw "Can't convert object prototype";
				while( i < l ) {
					__dollar__objset(o,f[i],nekoToHaxe(__dollar__objget(v,f[i])));
					i += 1;
				}
				return o;
			default:
				throw "Can't convert "+string(v);
			}
		#end
	}

	/**
	 * Converts a Neko value to its haXe equivalent. Used to unwrap String and Arrays Objects into raw Neko values.
	 * @param	v
	 * @return
	 */
	public static function haxeToNeko( v : Dynamic ) : Dynamic untyped {
		#if cpp
			return v;
		#elseif neko
			switch( __dollar__typeof(v) ) {
			case __dollar__tnull: return v;
			case __dollar__tint: return v;
			case __dollar__tfloat: return v;
			case __dollar__tbool: return v;
			case __dollar__tobject:
				var cl = v.__class__;
				if( cl == String )
					return v.__s;
				if( cl == Array ) {
					var a = untyped __dollar__amake(v.length);
					for( i in 0...v.length )
						a[i] = haxeToNeko(v[i]);
					return a;
				}
				if( cl != null || __dollar__objgetproto(v) != null )
					throw "Can't convert "+string(v);
				var f = __dollar__objfields(v);
				var i = 0;
				var l = __dollar__asize(f);
				var o = __dollar__new(v);
				while( i < l ) {
					__dollar__objset(o,f[i],haxeToNeko(__dollar__objget(v,f[i])));
					i += 1;
				}
				return o;
			default:
				throw "Can't convert "+string(v);
			}
		#end
	}
#end
#if neko
	/**
	 * Unserialize a string using native serialization. See [serialize].
	 * This function assume that all the serialized data was serialized with current
	 * module, even if the module name was different. This can happen if you are unserializing
	 * some data into mod_neko that was serialized on a different server using a different
	 * file path.
	 * 
	 * @param	s
	 * @return
	 */
	public static function localUnserialize( s : String ) : Dynamic {
		return untyped __unserialize(s.__s,{
			loadmodule : function(m,l) { return __dollar__exports; },
			loadprim : function(p,n) { return __dollar__loader.loadprim(p,n); }
		});
	}
#end
#if php
	static function appendType(o : Dynamic, path : Array<String>, t : Dynamic) {
		var name = path.shift();
		if(path.length == 0)
			untyped __php__("$o->$name = $t");
		else {
			var so = untyped __call__("isset", __php__("$o->$name")) ? __php__("$o->$name") : {};
			appendType(so, path, t);
			untyped __php__("$o->$name = $so");
		}
	}
	
	public static function extensionLoaded(name : String) {
		return untyped __call__("extension_loaded", name);
	}

	public static function isCli() : Bool {
		return untyped __php__("(0 == strncasecmp(PHP_SAPI, 'cli', 3))");
	}

	public static function printFile(file : String) {
		return untyped __call__("fpassthru", __call__("fopen", file,  "r"));
	}

	public static inline function toPhpArray(a : Array<Dynamic>) : php.NativeArray {
		return untyped __field__(a, '»a');
	}

	public static inline function toHaxeArray(a : php.NativeArray) : Array<Dynamic> {
		return untyped __call__("new _hx_array", a);
	}

	public static function hashOfAssociativeArray<T>(arr : php.NativeArray) : Hash<T> {
		var h = new Hash<T>();
		untyped __php__("reset($arr); while(list($k, $v) = each($arr)) $h->set($k, $v)");
		return h;
	}
	
	public static function associativeArrayOfHash(hash : Hash<Dynamic>) : php.NativeArray {
		return untyped hash.h;
	}
#end

	/**
	 * Returns an object containing all compiled packages and classes.
	 * @return
	 * @todo possible on some other platforms
	 */
	public static function getClasses() : Dynamic {
		#if neko
			return untyped neko.Boot.__classes;
		#elseif php
			var path : String = null;
			var o = {};
			untyped __call__('reset', php.Boot.qtypes);
			while((path = untyped __call__('key', php.Boot.qtypes)) != null) {
				appendType(o, path.split('.'), untyped php.Boot.qtypes[path]);
				untyped __call__('next',php.Boot.qtypes);
			}
			return o;
		#else
			throw new FatalException("unimplemented");
		#end
	}

#if neko
	static var __serialize = load("std","serialize",1);
	static var __unserialize = load("std", "unserialize", 2);
#end
}