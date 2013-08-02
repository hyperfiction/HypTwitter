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

package chx.vfs;

/**
Path represents any full file path or directory path. Do not use Windows
representations, all paths are /path/to/file.txt
@todo Test me
@author rweir
**/
class Path {
	/** directory, with no trailing slash **/
	public var directory(default, setDirectory): String;

	/** name of file with extension (ie. readme.txt) **/
	public var name(getName, setName)	: String;

	/** file name without extension **/
	public var namePlain				: String;
	/** extension with no leading dot (ie. txt) **/
	public var extension				: String;


	/**
		Create a new Path from the string provided. To represent a directory,
		ensure the last character is a /. The unix style home directory
		path is also supported, using the ~/ syntax.
	**/
	public function new( path : String ) {
		if(path == null)
			path = "";

		path = StringTools.replace(path, "//", "/");
		directory = null;
		var slash = path.lastIndexOf("/");
		if(slash >= 0) {
			directory = path.substr(0, slash);
			name = path.substr(slash + 1);
		} else {
			name = path;
		}
	}

	function getName() : String {
		if(namePlain == null)
			return null;
		return namePlain + (extension == null ? "" : "." + extension);
	}

	function setDirectory(s : String) : String {
		if(s == null || s.length == 0) {
			directory = null;
			return s;
		}
		if(s.charAt(s.length-1) == "/")
			s = s.substr(0, s.length-1);
		if(s.charAt(0) == "~" && s.charAt(1) == "/")
			s = Vfs.homeDirectory.toString() + s.substr(1);
		return directory = s;
	}

	function setName(n : String) : String {
		if(n == null || n.length == 0) {
			extension = null;
			name = null;
			return n;
		}
		var period = n.lastIndexOf(".");
		if( period >= 0 ) {
			extension = n.substr(period + 1);
			namePlain = n.substr(0, period);
		} else {
			extension = null;
			namePlain = n;
		}
		return n;
	}

	/**
		Will return the full path. For directories, without any trailing slash.
	**/
	public function toString() {
		var rv : String = "";
		if(directory != null)
			rv += directory;
		if(name != null) {
			if(directory != null)
				rv += "/";
			rv += name;
		}
		return rv;
	}

	/**
		Translates a Windows path with backslashes to a Path instance
		@param path String with possible backslash path characters
		@returns A new Path instance
	**/
	public static function fromWindows(path : String) : Path {
		return new Path(StringTools.replace(path, "\\", "/"));
	}

	/**
		Translates the given Path instance to a Windows path string.
		@param p A path instance
		@returns Windows encoded path
	**/
	public static function toWindows(p : Path) : String {
		return StringTools.replace(p.toString(), "/", "\\");
	}
}