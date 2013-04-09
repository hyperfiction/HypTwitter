rm -rf "obj"
echo "compiling for armv6"
haxelib run hxcpp Build.xml -Diphoneos -DHXCPP_CLANG
echo "compiling for armv7"
haxelib run hxcpp Build.xml -Diphoneos -DHXCPP_ARMV7 -DHXCPP_CLANG
echo "compiling for simulator"
haxelib run hxcpp Build.xml -Diphonesim -DHXCPP_CLANG
echo "Copying sim"
cp ../ndll/iPhone/libHypTwitter.iphonesim.a ../bin-debug/ios/Test/lib/i386/libHypTwitter.a
echo "Copying sim debug"
cp ../ndll/iPhone/libHypTwitter.iphonesim.a ../bin-debug/ios/Test/lib/i386-debug/libHypTwitter.a
echo "Copying v6"
cp ../ndll/iPhone/libHypTwitter.iphoneos.a ../bin-debug/ios/Test/lib/armv6/libHypTwitter.a
echo "Copying v7"
cp ../ndll/iPhone/libHypTwitter.iphoneos-v7.a ../bin-debug/ios/Test/lib/armv7/libHypTwitter.a
echo "Copying v7 debug"
cp ../ndll/iPhone/libHypTwitter.iphoneos-v7.a ../bin-debug/ios/Test/lib/armv7-debug/libHypTwitter.a
echo "Done !"