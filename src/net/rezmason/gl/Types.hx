package net.rezmason.gl;

#if !flash
    typedef UniformLocation = openfl.gl.GLUniformLocation;
#end

#if js
    typedef ReadbackData = openfl.utils.UInt8Array;
#else
    typedef ReadbackData = flash.utils.ByteArray;
#end
