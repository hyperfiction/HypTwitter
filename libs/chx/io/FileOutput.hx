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
import chx.io.File;
import chx.lang.EofException;
import chx.lang.Exception;

#if (neko || php || cpp)
/**
	Use [php.io.File.write] to create a [FileOutput]
**/
class FileOutput extends chx.io.Output {
	private var __f : FileHandle;

	public function new(f) {
		__f = f;
	}

	public override function writeByte( c : Int ) : Output {
		#if php
			var r = untyped __call__('fwrite', __f, __call__('chr', c));
			if(untyped __physeq__(r, false)) return throw new Exception("error");
		#else
			try file_write_char(__f, c) catch ( e : Dynamic ) throw new Exception("error", e);
		#end
		return this;
	}

	public override function writeBytes( b : Bytes, p : Int, l : Int ) : Int {
		#if php
			var s = b.readString(p, l);
			if(untyped __call__('feof', __f)) return throw new EofException();
			var r = untyped __call__('fwrite', __f, s, l);
			if(untyped __physeq__(r, false)) return throw new Exception("error");
			return r;
		#else
			return try file_write(__f,b.getData(),p,l) catch( e : Dynamic ) throw new Exception("error", e);
		#end
	}

	public override function flush() : Output {
		#if php
			var r = untyped __call__('fflush', __f);
			if (untyped __physeq__(r, false)) throw new Exception("error");
		#else
			file_flush(__f);
		#end
		return this;
	}

	public override function close() {
		super.close();
		#if php
			if(__f != null)	untyped __call__('fclose', __f);
		#else
			file_close(__f);
		#end
	}

	public function seek( p : Int, pos : FileSeek ) {
		#if php
			var w;
			switch( pos ) {
				case SeekBegin: w = untyped __php__('SEEK_SET');
				case SeekCur  : w = untyped __php__('SEEK_CUR');
				case SeekEnd  : w = untyped __php__('SEEK_END');
			}
			var r = untyped __call__('fseek', __f, p, w);
			if(untyped __physeq__(r, false)) throw new Exception("error");
		#else
			file_seek(__f,p,switch( pos ) { case SeekBegin: 0; case SeekCur: 1; case SeekEnd: 2; });
		#end
	}

	public function tell() : Int {
		#if php
			var r = untyped __call__('ftell', __f);
			if(untyped __physeq__(r, false)) return throw new Exception("error");
			return cast r;
		#else
			return file_tell(__f);
		#end
	}

	#if (neko || cpp)
	private static var file_close = chx.Lib.load("fileext","fileext_close",1);
	private static var file_seek = chx.Lib.load("fileext","fileext_seek",3);
	private static var file_tell = chx.Lib.load("fileext","fileext_tell",1);

	private static var file_flush = chx.Lib.load("fileext","fileext_flush",1);
	private static var file_write = chx.Lib.load("fileext","fileext_write",4);
	private static var file_write_char = chx.Lib.load("fileext","fileext_write_char",2);
	#end
}

#else
#error
#end
