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

enum System {
	Windows;
	Linux;
	Mac;
}

enum Platform {
	NEKO;
	PHP;
	JS;
	CPP;
	FLASH(ver : Int);
}

class Sys {
	public static var system(default, null) : System;
	public static var platform(default, null) : Platform;

	public static var browserName(default, null) : String;
	public static var browserVersion(default, null) : String;
	public static var browserPlatform(default, null) : String;
	public static var hasCookies(default, null) : Bool;
	public static var userAgent(default, null) : String;
	public static var userLanguage(default, null) : String;

	public static function systemName() : String {
		return switch(system) {
		case Windows: "Windows";
		case Linux: "Linux";
		case Mac: "Mac";
		}
	}

	static function __init__() {
		var sname : String = null;
		#if (neko || cpp)
			platform = NEKO;
			sname = neko.Sys.systemName();
			#if cpp
				platform = CPP;
			#end
		#elseif php
			sname = php.Sys.systemName();
		#elseif js
			platform = JS;
			var n = untyped __js__("navigator");
			browserName = n.appName; // Netscape
			browserVersion = n.appVersion; // 5.0 (X11; en-US)
			browserPlatform = n.platform; // Linux i686
			hasCookies = n.cookieEnabled;
			userAgent = n.userAgent; // Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.14) Gecko/20080420 Firefox/2.0.0.14
			userLanguage = n.userLanguage;

			var pl = browserPlatform.toLowerCase();
			if(pl.indexOf("linux") >= 0)
				system = Linux;
			else if(pl.indexOf("mac") >= 0)
				system = Mac;
			else
				system = Windows;
		#elseif flash
			var vs = flash.system.Capabilities.version;
			var pltVer = vs.split(" ");
			if(pltVer.length > 1) {
				var a = pltVer[1].split(",");
				platform = FLASH(Std.parseInt(a[0]));
			} else {
				platform = FLASH(0);
			}

			var ss = flash.system.Capabilities.os;
			if(StringTools.startsWith(ss.toLowerCase(), "windows"))
				system = Windows;
			else if(StringTools.startsWith(ss.toLowerCase(), "linux"))
				system = Linux;
			else
				system = Mac;
		#else
		#error
		#end

		if(sname != null) {
			system = switch(sname.toLowerCase()) {
			case "linux": Linux;
			case "mac": Mac;
			default: Windows;
			}
		}

	}
}


/*
Javascript navigator object:
    * appCodeName - The name of the browser's code such as "Mozilla".
    * appMinorVersion - The minor version number of the browser.
    * appName - The name of the browser such as "Microsoft Internet Explorer" or "Netscape Navigator".
    * appVersion - The version of the browser which may include a compatability value and operating system name.
    * cookieEnabled - A boolean value of true or false depending on whether cookies are enabled in the browser.
    * cpuClass - The type of CPU which may be "x86"
    * mimeTypes - An array of MIME type descriptive strings that are supported by the browser.
    * onLine - A boolean value of true or false.
    * opsProfile
    * platform - A description of the operating system platform.
    * plugins - An array of plug-ins supported by the browser and installed on the browser.
    * systemLanguage - The language being used such as "en-us".
    * userAgent - In my case it is "Mozilla/4.0 (compatible; MSIE 4.01; Windows 95)" which describes the browser associated user agent header.
    * userLanguage - The languge the user is using such as "en-us".
    * userProfile
*/