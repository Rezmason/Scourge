package net.rezmason.gl;

typedef AttribsLocation = #if flash Int #else Int #end ;
typedef UniformLocation = #if flash Int #else openfl.gl.GLUniformLocation #end ;

typedef ReadbackData = #if js openfl.utils.UInt8Array #else flash.utils.ByteArray #end ;

typedef IndexArray = #if flash flash.Vector<UInt> #else openfl.utils.Int16Array #end ;
typedef VertexArray = #if flash flash.Vector<Float> #else openfl.utils.Float32Array #end;
