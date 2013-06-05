package net.rezmason.gl;

typedef UniformLocation = openfl.gl.GLUniformLocation;

#if js
    typedef ReadbackData = openfl.utils.UInt8Array;
#else
    typedef ReadbackData = flash.utils.ByteArray;
#end
