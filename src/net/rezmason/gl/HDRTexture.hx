package net.rezmason.gl;

#if flash
    import net.rezmason.utils.HalfFloatUtil;
#else
    import lime.utils.Float32Array;
#end

class HDRTexture extends DataTexture {
    public function new(width:Int, height:Int, floats:Array<Float>):Void {
        var data = null;
        #if flash 
            data = HalfFloatUtil.createHalfFloatBytes(floats);
        #else 
            data = new Float32Array(width * height * 4);
            data.set(floats);
        #end
        super(width, height, FLOAT, data);
    }
}
