# We need to make our build directory for all of our temp files.
rm -r build
mkdir build

#Enter the build Directory
cd build

#Now we initiate cmake in this dir
cmake ..

#Next we build the source files!
make

#Next we copy the executable to our root project file.
cp ./src/birdie ../birdie
