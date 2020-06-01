mkdir -p build_osx && cd build_osx
cmake -GXcode ../
cd ..
cmake --build build_osx --config Release
mkdir -p plugin_js/Plugins/jswrap.bundle/Contents/MacOS/
cp build_osx/Release/xlua.bundle/Contents/MacOS/xlua plugin_js/Plugins/jswrap.bundle/Contents/MacOS/xlua

