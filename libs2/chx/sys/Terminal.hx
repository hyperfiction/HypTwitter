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

package system;

/**
	Static methods for dealing with command line input, output and prompting
**/
class Terminal {
	static var stdin : neko.io.FileInput;
	static var stdout : neko.io.FileOutput;

	/**
		Prints to stdout
	**/
	public static function print(s:Dynamic) : Void {
		stdout.write(Bytes.ofString(Std.string(s)));
		stdout.flush();
	}

	/**
		Returns a trimmed line of input
	**/
	public static function readTrimmed() : String {
		return StringTools.trim(stdin.readLine());
	}

	/**
		Prompts for an integer input value. A default can be supplied, as well as a minimum and maximum acceptable input value.
	**/
	public static function promptInteger(m:String, defaultVal:Null<Int>, min:Null<Int>, max:Null<Int>) {
		var retval : Int = 0;
		while(true) {
			print(m);
			if(defaultVal != null)
				print(" ["+Std.string(defaultVal)+"] ");
			var s = readTrimmed();
			if(s.length == 0 && defaultVal != null)
				return defaultVal;

			var input = Std.parseInt(s);
			if(input == null)
				continue;
			if(min != null && input < min) {
				print("ERROR: "+input+" is too low.\n");
				continue;
			}
			if(max != null && input > max) {
				print("ERROR: "+input+" is too high.\n");
				continue;
			}

			return input;
		}
		return 0;
	}

	/**
		Prompts with message m for a true or false Yes|No answer. If defaultVal
		is set to true, the question will be followed with [Y/n]
	**/
	public static function promptYesNo(m:String, defaultVal:Bool) : Bool {
		var retval : Bool = false;
		while(true) {
			print(m);
			if(defaultVal) {
				print(" [Y/n] ");
			}
			else {
				print(" [y/N] ");
			}
			var input = readTrimmed().toLowerCase();
			if(input.charAt(0) == "y")
				return true;
			if(input.charAt(0) == "n")
				return false;
			if(input.length == 0)
				return defaultVal;
		}
		return retval;
	}

	/**
		Prompts for a directory path. If allowEmpty is set with no default value,
		then an empty path can be input and returned
	**/
	public static function promptDir(m:String, defaultVal:String, ?allowEmpty:Bool) : String {
		var retval : String = "";
		while(true) {
			print(m);
			if(!allowEmpty) {
				if(defaultVal.length > 0) {
					print(" ["+defaultVal+"] >");
				}
				else {
					print(" >");
				}
			}
			var input = readTrimmed();
			if(input.length == 0 && (defaultVal.length > 0 || allowEmpty))
				return defaultVal;
			if(input.length == 0)
				continue;
			if(input.length > 1 && input.charAt(input.length) == "/")
				input = input.substr(0, input.length-1);
			return input;
		}
		return retval;
	}

	/**
		Prompts for a directory to create if it does not exist. If allowEmpty is true,
		no directory will be created if there is no input.
	**/
	public static function promptDirMake(m:String, defaultVal:String, ?allowEmpty:Bool) : String {
		while(true) {
			var dir = promptDir(m, defaultVal, allowEmpty);
			if(dir.length == 0) {
				if(allowEmpty == true)
					return dir;
				continue;
			}
			if(neko.FileSystem.exists(dir) && neko.FileSystem.isDirectory(dir))
				return dir;
			if(neko.FileSystem.exists(dir)) {
				print(dir + " exists, but is not a directory. Try again.");
				continue;
			}
			if(promptYesNo("The directory "+dir+" does not exist. Create?", false)) {
				try {
					neko.FileSystem.createDirectory(dir);
				}
				catch(e:Dynamic) {
					print("ERROR: Unable to create directory "+dir+"\n");
					continue;
				}
			}
			else
				continue;
			return dir;
		}
		return "";
	}

	/**
		Returns the neko ndll paths as an array
	**/
	#if neko
	public static function nekoNdllDirs() : Array<String> {
		var h = new Hash<Bool>();
		if(neko.Sys.systemName() != "Windows") {
			var paths = [
				"/usr/neko/lib",
				"/usr/lib/neko",
				"/usr/local/lib/neko",
				"/usr/local/neko/lib"
			];
			for(p in paths)
				if(neko.FileSystem.isDirectory(p))
					h.set(p, true);
		}

		var s = neko.Sys.getEnv("NEKOPATH").split(":");
		if(s.length == 0) {
			if(neko.Sys.systemName() == "Windows")
				s = ["c:\\neko"];
		}
		for(p in s)
			h.set(p, true);
		var a = new Array<String>();
		for(i in h.keys())
			a.push(i);
		return a;
	}
	#end

	/**
		Returns the executablePath, cleaned so that there are no
		double slashes in the result.
	**/
	public static function executablePath() : String {
		var parts = neko.Sys.executablePath().split("/");
		var s = new StringBuf();
		for(i in 0...parts.length-1) {
			if(parts[i].length == 0)
				continue;
			s.add("/");
			s.add(parts[i]);
		}
		return s.toString();
	}

	static function __init__() {
		stdin = neko.io.File.stdin();
		stdout = neko.io.File.stdout();
	}
}

