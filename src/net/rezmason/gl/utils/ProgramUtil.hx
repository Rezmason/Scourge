package net.rezmason.gl.utils;

import net.rezmason.gl.Data;
import net.rezmason.gl.GLTypes;
import net.rezmason.gl.utils.Util;

#if flash
    import flash.display3D.Context3DCompareMode;
#else
    import openfl.gl.GL;
#end


class ProgramUtil extends Util {

    public inline function loadProgram(vertSource:String, fragSource:String, onLoaded:Program->Void):Void {
        var program:Program = new Program(context);
        program.load(vertSource, fragSource, function() onLoaded(program));
    }

    public inline function setProgram(program:Program):Void {
        #if flash program.prog.attach();
        #else GL.useProgram(program.prog);
        #end
    }

    public inline function setBlendFactors(sourceFactor:BlendFactor, destinationFactor:BlendFactor):Void {
        #if flash
            context.setBlendFactors(sourceFactor, destinationFactor);
        #else
            GL.enable(GL.BLEND);
            GL.blendFunc(sourceFactor, destinationFactor);
        #end
    }

    public inline function setDepthTest(enabled:Bool):Void {
        #if flash
            context.setDepthTest(enabled, Context3DCompareMode.LESS);
        #else
            if (enabled) GL.enable(GL.DEPTH_TEST);
            else GL.disable(GL.DEPTH_TEST);
        #end
    }

    public inline function enableExtension(extName:String):Void {
        #if !flash
            GL.getExtension(extName);
        #end
    }
}
