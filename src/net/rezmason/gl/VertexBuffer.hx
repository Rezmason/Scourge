package net.rezmason.gl;

#if flash
    typedef VertexBuffer = flash.display3D.VertexBuffer3D;
#else
    import openfl.gl.GL;
    import openfl.gl.GLBuffer;
    import openfl.utils.Float32Array;

    class VertexBuffer {

        @:allow(net.rezmason.gl) var buf:GLBuffer;
        public var footprint(default, null):Int;
        public var numVertices(default, null):Int;
        var array:Float32Array;

        public function new(numVertices:Int, footprint:Int):Void {
            this.footprint = footprint;
            this.numVertices = numVertices;
            buf = GL.createBuffer();
            array = new Float32Array(footprint * numVertices);
        }

        public inline function uploadFromVector(data:Array<Float>, offset:Int = 0, num:Int = 0):Void {
            if (offset < 0 || offset > numVertices) {

            } else {
                if (offset + num > numVertices) num = numVertices - offset;

                for (ike in (offset * footprint)...((offset + num) * footprint)) {
                    array[ike] = data[ike];
                }

                GL.bindBuffer(GL.ARRAY_BUFFER, buf);
                GL.bufferData(GL.ARRAY_BUFFER, array, GL.STATIC_DRAW);
            }
        }
    }
#end
