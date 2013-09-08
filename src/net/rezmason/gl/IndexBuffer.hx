package net.rezmason.gl;

#if flash
    typedef IndexBuffer = flash.display3D.IndexBuffer3D;
#else
    import openfl.gl.GL;
    import openfl.gl.GLBuffer;
    import net.rezmason.gl.Types;

    class IndexBuffer {

        @:allow(net.rezmason.gl) var buf:GLBuffer;
        public var numIndices(default, null):Int;
        var array:IndexArray;

        public function new(numIndices:Int):Void {
            this.numIndices = numIndices;
            buf = GL.createBuffer();
            array = new IndexArray(numIndices);
        }

        public inline function uploadFromVector(data:IndexArray, offset:Int, num:Int):Void {
            if (offset < 0 || offset > numIndices) {

            } else {
                if (offset + num > numIndices) num = numIndices - offset;

                #if js
                    if (num < data.length) data = data.subarray(0, num);
                    array.set(data, offset);
                #else
                    for (ike in 0...num) array[ike + offset] = data[ike];
                #end

                GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
                GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, array, GL.STATIC_DRAW);
            }
        }

        public inline function dispose():Void {
            array = null;
            numIndices = -1;
        }
    }
#end
