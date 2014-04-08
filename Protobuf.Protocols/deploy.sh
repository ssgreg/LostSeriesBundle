#!/bin/bashdateTranslate

echo "Building py&cpp files"
~/Documents/Sandbox/Home/Frameworks/protobuf-2.5.0/protobuf/bin/protoc --cpp_out=../LostSeries/Protobuf.Generated/Protobuf.Generated --python_out=../LostSeriesServer/ LostSeriesProtocol.proto
