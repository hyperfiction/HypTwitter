package system.io;

#if php
typedef Process = php.io.Process;
#elseif neko
typedef Process = neko.io.Process;
#end