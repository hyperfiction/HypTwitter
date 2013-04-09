package system.io;

#if php
typedef File = php.io.File;
#elseif neko
typedef File = neko.io.File;
#end