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
package chx.io;

#if neko
enum FileHandle {
}
#elseif cpp
typedef FileHandle = Dynamic;
#end

enum FileSeek {
	SeekBegin;
	SeekCur;
	SeekEnd;
}


#if (neko || cpp)

/**
	API for reading and writing to files.
**/
class File {

	public static function getContent( path : String ) : String {
		#if (neko || cpp)
			return Lib.nekoStringToHaxe(file_contents(Lib.haxeStringToNeko(path)));
		#elseif php
			return untyped __call__("file_get_contents", path);
		#end
	}

	public static function getBytes( path : String ) : Bytes {
		return Bytes.ofStringData(getContent(path));
	}

	/*
	public static function putContent( path : String, content : String) : Int {
		return untyped __call__("file_put_contents", path, content);
	}
	*/

	public static function read( path : String, binary : Bool ) : FileInput {
		#if neko
			return new FileInput(untyped file_open(path.__s,(if( binary ) "rb" else "r").__s));
		#elseif cpp
			return new FileInput(untyped file_open(path,(if( binary ) "rb" else "r")));
		#elseif php
			return new FileInput(untyped __call__('fopen', path, binary ? "rb" : "r"));
		#end
	}

	public static function write( path : String, binary : Bool ) : FileOutput {
		#if neko
			return new FileOutput(untyped file_open(path.__s,(if( binary ) "wb" else "w").__s));
		#elseif cpp
			return new FileOutput(untyped file_open(path,(if( binary ) "wb" else "w")));
		#elseif php
			return new FileOutput(untyped __call__('fopen', path, binary ? "wb" : "w"));
		#end
	}

	public static function append( path : String, binary : Bool ) : FileOutput {
		#if neko
			return new FileOutput(untyped file_open(path.__s,(if( binary ) "ab" else "a").__s));
		#elseif cpp
			return new FileOutput(untyped file_open(path,(if( binary ) "ab" else "a")));
		#elseif php
			return new FileOutput(untyped __call__('fopen', path, binary ? "ab" : "a"));
		#end
	}

	public static function copy( src : String, dst : String ) : Void {
		#if php
			return untyped __call__("copy", src, dst);
		#else
			var s = read(src,true);
			var d = write(dst,true);
			d.writeInput(s);
			s.close();
			d.close();
		#end
	}

	public static function stdin() {
		#if php
			return new FileInput(untyped __call__('fopen', 'php://stdin', "r"));
		#else
			return new FileInput(file_stdin());
		#end
	}

	public static function stdout() : FileOutput {
		#if php
			return new FileOutput(untyped __call__('fopen', 'php://stdout', "w"));
		#else
			return new FileOutput(file_stdout());
		#end
	}

	public static function stderr() : FileOutput {
		#if php
			return new FileOutput(untyped __call__('fopen', 'php://stderr', "w"));
		#else
			return new FileOutput(file_stderr());
		#end
	}

	public static function getChar( echo : Bool ) : Int {
		#if php
			var v : Int = untyped __call__("fgetc", __php__("STDIN"));
			if(echo)
				untyped __call__('echo', v);
			return v;
		#else
			return getch(echo);
		#end
	}

	public static function __init__()
	{
		chx.Lib.initDll("fileext");
	}

	#if !php
	private static var file_contents = chx.Lib.load("fileext","fileext_contents",1);
	private static var file_open = chx.Lib.load("fileext","fileext_open",2);
	private static var file_stdin = chx.Lib.load("fileext","fileext_stdin",0);
	private static var file_stdout = chx.Lib.load("fileext","fileext_stdout",0);
	private static var file_stderr = chx.Lib.load("fileext","fileext_stderr",0);
	private static var getch = chx.Lib.load("std","sys_getch",1);
	#end
}

#else
#error
#end
