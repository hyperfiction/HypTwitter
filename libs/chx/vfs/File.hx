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


enum FileModeFlags {
	SUID;
	SGID;
	STICKY;

	U_READ;
	U_WRITE;
	U_EXECUTE;

	G_READ;
	G_WRITE;
	G_EXECUTE;

	O_READ;
	O_WRITE;
	O_EXECUTE;
}

enum FileMode {
	Mode(m : Array<FileModeFlags>);
}

/**
	A base class representing any real or virtual file or directory
	@todo Write me
	@author rweir
**/
class File {
	var name(getName, null)			: String;
	var path(default, null)			: Path;
	var length(getLength, null)		: Int;
	var mode : Int;
	var uid : Int;
	var gid : Int;
	var lastModified(getLastModified, setLastModified) : Date;
	/** @todo Move to a registry map of uid->username**/
	var user : String;
	/** @todo Move to a registry map of gid->groupname**/
	var group : String;

	/** The root directory this File is relative to **/
	var root : VfsRoot;

	private function new() {
	}

	/**
		Returns true if the current user can read from this file
	**/
	public function canRead() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns true if the current user can write to this file.
	**/
	public function canWrite() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Sets the default root to the directory specified by this
		File.
		@returns true if succeful, false otherwise
	**/
	public function chroot() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Will create an abstract File as a filesystem file.
		@returns true if file is successfully created
	**/
	public function createNewFile() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns true if the File was successfully deleted. If the
		File did not exists, will also return true.
	**/
	public function delete() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns true if the file exists
	**/
	public function exists() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns the final entry in the path, whether it is a directory
		name or a file name
	**/
	public function getName() : String {
		return throw new chx.lang.FatalException("not implemented properly");
		//return path.name;
	}

	public function getParent() : String {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns the date of last modification to the file, or null
		if it can not be determained.
	**/
	public function getLastModified() : Date {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns the file length. The return value is arbitrary if
		the File is a directory or other filesystem special.
	**/
	public function getLength() : Int {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns true if the file exists and is a directory.
	**/
	public function isDirectory() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns true if the file is a regular file, not a symlink or
		other filesystem special.
	**/
	public function isFile() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns a list of the names of the directories and files,
		not including parent directories. The returned array is
		in no particular order.

		@param filter Optional function that will filter the list of
		files, which must return true to include an entry
		@returns Array of strings representing file and directory names in the
		the directory of this File, or null if this File is not a directory
	**/
	public function list(?filter:String->Bool) : Array<String> {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Returns a list of File instances of the directories and files,
		not including parent directories. The returned array is
		in no particular order.

		@param filter Optional function that will filter the list of
		files, which must return true to include an entry
		@returns Array of strings representing file and directory names in the
		the directory of this File, or null if this File is not a directory
	**/
	public function listFiles(?filter:String->Bool) : Array<File> {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Create a directory of the abstract path.
		@returns true if directory is created, false otherwise
	**/
	public function mkdir() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Creates the directory of the abstract path, including any
		necessary parent directories.
		returns True if every directory in the path was successfully created.
	**/
	public function mkdirs() : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		Will attempt to rename the current file to the File
		provided.
	**/
	public function rename(f : File) : Bool {
		return throw new chx.lang.FatalException("not implemented");
	}


	/**
		Will attempt to set the last modification date
		of the File.
		@returns Same date if modification succeeds, or null on failure
	**/
	public function setLastModified(d : Date) : Date {
		return throw new chx.lang.FatalException("not implemented");
	}







	//////////////////////////////////////////////
	//                 Statics                  //
	//////////////////////////////////////////////

	/**
		The handlers for each uri with pointers to the function
		that shall return a File instance
	**/
	static var uriHandlers : Hash<String -> File> = new Hash();


	/**
		Will create a File based on a uri.
	**/
	public static function createFromURI(uri : chx.net.URI) : File {
		return throw new chx.lang.FatalException("not implemented");
	}

	/**
		File implementations must register what URI types they handle
		on initialization
		@param uriScheme short uri scheme name (ie. http)
		@param f Function taking the full URI and returning a File
	**/
	static function registerURIHandler(uriScheme:String, f : String->File) {
		if(uriHandlers.exists(uriScheme))
			throw new chx.lang.FatalException("URI Type " + uriScheme + " already registered");
		uriHandlers.set(uriScheme, f);
	}

// 	static function registerFileExtensionHandler(ext:String, f : )
}