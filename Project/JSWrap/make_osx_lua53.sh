mkdir -p build_osx && cd build_osx
cmake -GXcode ../
cd ..
cmake --build build_osx --config Release
mkdir -p plugin_js/Plugins/jswrap.bundle/Contents/MacOS/
cp build_osx/Release/jswrap.bundle/Contents/MacOS/jswrap plugin_js/Plugins/jswrap.bundle/Contents/MacOS/jswrap

