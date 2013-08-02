HAXE=haxe
HAXECPP=haxelib run hxcpp
NMML=build.nmml
TARGETS:=$(shell cd src && ls *.hx | sed 's/.hx//g')
DEBUG=-debug
COMMON=-cp ../../ -cp src $(DEBUG)

all:
	@echo Targets: `echo $(TARGETS)|sed 's/.hx / | /g'` "| clean"

$(TARGETS):
	$(HAXE) $(COMMON) $(FLAGS) -neko test.n -main $@
#	$(HAXE) $(COMMON) $(FLAGS) -swf test8.swf -swf-version 8 -main $@
#	$(HAXE) $(COMMON) $(FLAGS) -swf test9.swf -swf-version 9 -main $@
#	$(HAXE) $(COMMON) $(FLAGS) -js test.js -main $@
	$(HAXE) $(COMMON) $(FLAGS) -cpp cpp-native -main $@

.PHONY clean:
	rm -f test.js
	rm -f test8.swf
	rm -f test9.swf
	rm -rf cpp-openssl
	rm -rf cpp-native
	rm -f test.n

