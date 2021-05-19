# Mpkcc

Mpkcc (mapnik cross compiled) is a bash script that automates the cross-compilation process of the [mapnik](https://github.com/mapnik/mapnik) c++ library for other cpu architectures than x86_64 PC.

Mpkcc currently supports the following features.

|  | version |
| ------ | ------ |
| Mapnik | 5.0.2 |
| Platform | Android |
| NDK | 21e |
| API | min. 21 |
| Arch | arm,arm64,x86,x86_64 |

# What is Mapnik?

Mapnik is the open source C++ library that you can use to develop a map applications.
It's better known as the the openstreetmap.org render engine.

To cross-compile the library you have two options:

- install dependencies, clone the repo and run the script (tested only on Debian 10)

```bash
#required dependencies

apt-get update -q -y && \
        apt-get upgrade -q -y && \
        apt-get install -q -y binutils wget make git ssh unzip python gcc g++

./mpkcc.sh --api=<minimum 21> --arch=<android hardware platform: x86_64|x86|arm|arm64>
 ```

- or download the actual binary version from the Releases section.

Now, you can add the path to the include and library folder to your CMAKE file in Android Studio:

```CMAKE
add_library(mpkcc STATIC IMPORTED)
set_target_properties(mpkcc PROPERTIES IMPORTED_LOCATION
    <path to build directory>/mpkcc/output/mpkcc/lib/libmpkcc.a)
include_directories(<path to build directory>/output/mpkcc/include/)`
```
