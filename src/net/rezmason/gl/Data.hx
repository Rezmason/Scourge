package net.rezmason.gl;

typedef ReadbackData = #if js openfl.utils.UInt8Array #elseif flash flash.utils.ByteArray #else openfl.utils.UInt8Array #end ;

typedef IndexArray = #if flash flash.Vector<UInt> #else openfl.utils.Int16Array #end ;
typedef VertexArray = #if flash flash.Vector<Float> #else openfl.utils.Float32Array #end ;
