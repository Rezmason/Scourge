package net.rezmason.gl;

typedef ReadbackData = #if js lime.utils.UInt8Array #elseif flash flash.utils.ByteArray #else lime.utils.UInt8Array #end ;

typedef IndexArray = #if flash flash.Vector<UInt> #else lime.utils.Int16Array #end ;
typedef VertexArray = #if flash flash.Vector<Float> #else lime.utils.Float32Array #end ;
