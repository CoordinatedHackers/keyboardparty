CPP=c++
CPPFLAGS+=\
	-std=c++11\
	-stdlib=libc++\
	-Wall\
	-Wpedantic\
	-Werror

lights: lights.cpp
	$(CPP) -framework Foundation -framework IOKit -framework AudioToolbox $(CPPFLAGS) -o $@ $<
