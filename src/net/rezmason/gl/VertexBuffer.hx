package net.rezmason.gl;

#if flash
    typedef VertexBuffer = flash.display3D.VertexBuffer3D;
#else
    import openfl.gl.GL;
    import openfl.gl.GLBuffer;
    import net.rezmason.gl.Types;

    class VertexBuffer {

        @:allow(net.rezmason.gl) var buf:GLBuffer;
        public var footprint(default, null):Int;
        public var numVertices(default, null):Int;
        var array:VertexArray;

        public function new(numVertices:Int, footprint:Int):Void {
            this.footprint = footprint;
            this.numVertices = numVertices;
            buf = GL.createBuffer();
            array = new VertexArray(footprint * numVertices);
        }

        public inline function uploadFromVector(data:VertexArray, offset:Int, num:Int):Void {
            if (offset < 0 || offset > numVertices) {

            } else {
                if (offset + num > numVertices) num = numVertices - offset;

                if (num * footprint < data.length) data = data.subarray(0, num * footprint);

                array.set(data, offset);

                GL.bindBuffer(GL.ARRAY_BUFFER, buf);
                GL.bufferData(GL.ARRAY_BUFFER, array, GL.STATIC_DRAW);
            }
        }
    }
#end
