Mpkcc (mapnik cross compiled) script cross-compiles the mapnik c++ library for other cpu architectures than x86_64 (currently supports only the Android platform).

What is Mapnik?
Mapnik is the open source C++ library that you can use to develop a map applications.<br>
It's better known as the the openstreetmap.org render engine.

To cross-compile the library you have two options:

- clone the repo and run the script:

  ./mpkcc.sh --api=<minimum 21> --arch=<android hardware platform>

  android hardware platforms: x86_64, x86, arm, arm64

- or download the actual binary version from the Releases section.

Now you can add the path to the include and library folder into your CMAKE project in Android Studio:

`add_library(mpkcc STATIC IMPORTED)
set_target_properties(mpkcc PROPERTIES IMPORTED_LOCATION
    <path to build directory>/mpkcc//output/mpkcc/lib/libmpkcc.a)
    
include_directories(<path to build directory>/output/mpkcc/include/)`
