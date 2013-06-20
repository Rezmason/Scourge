package net.rezmason.gl;

#if flash
    typedef IndexBuffer = flash.display3D.IndexBuffer3D;
#else
    import openfl.gl.GL;
    import openfl.gl.GLBuffer;
    import openfl.utils.Int16Array;

    class IndexBuffer {

        @:allow(net.rezmason.gl) var buf:GLBuffer;
        public var numIndices(default, null):Int;
        var array:Int16Array;

        public function new(numIndices:Int):Void {
            this.numIndices = numIndices;
            buf = GL.createBuffer();
            array = new Int16Array(numIndices);
        }

        public inline function uploadFromVector(data:Array<Int>, offset:Int, num:Int):Void {
            if (offset < 0 || offset > numIndices) {

            } else {
                if (offset + num > numIndices) num = numIndices - offset;

                // TODO: SPEED THIS UP

                for (ike in offset...(offset + num)) {
                    array[ike] = data[ike];
                }

                GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
                GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, array, GL.STATIC_DRAW);
            }
        }
    }
#end
