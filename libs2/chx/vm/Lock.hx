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

package chx.vm;

/**
	A lock class that works on all platforms. Serialization of locks will
	leave them in an undefined state, so they should be replaced.
	@author Russell Weir
**/
class Lock {
	#if (neko || cpp)
	var lock : Dynamic;
	#else
	var lock : Int;
	#end

	/**
		When a lock is created it is returned in the locked state already. You may
		want to immediately release it if it is a class member.
		[lock = new chx.vm.Lock();
		lock.release();]
	**/
	public function new() {
		#if (neko || cpp)
			lock = lock_create();
		#else
			lock = 1;
		#end
	}

	/**
		Wait for the lock for the specified number of milliseconds.
		@param waitMs milliseconds to wait, 500 being 500 ms. (1/2 second)
	**/
	public function wait( waitMs : Null<Int> = null ) : Bool {
		#if (neko || cpp)
			var w : Float = waitMs;
			return lock_wait(lock, (w / 1000));
		#else
			var checktime = true;
			var limit = 0.0;
			if(waitMs == null)
				checktime = false;
			if(checktime)
				limit = Date.now().getTime() + waitMs;
			while(lock > 0) {
				if(checktime && Date.now().getTime() >= limit)
					return false;
			}
			lock++;
			return true;
		#end
	}

	public function release() {
		#if (neko || cpp)
			lock_release(lock);
		#else
			lock--;
		#end
	}


	#if (neko || cpp)
	static var lock_create = chx.Lib.load("std","lock_create",0);
	static var lock_release = chx.Lib.load("std","lock_release",1);
	static var lock_wait = chx.Lib.load("std","lock_wait",2);
	#end
}
