package net.rezmason.gl;

typedef ReadbackData = #if js openfl.utils.UInt8Array #else flash.utils.ByteArray #end ;

typedef IndexArray = #if flash flash.Vector<UInt> #else openfl.utils.Int16Array #end ;
typedef VertexArray = #if flash flash.Vector<Float> #else openfl.utils.Float32Array #end;
