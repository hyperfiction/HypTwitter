package system.io;

#if php
typedef Path = php.io.Path;
#elseif neko
typedef Path = neko.io.Path;
#end