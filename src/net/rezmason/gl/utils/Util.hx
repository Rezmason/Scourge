package net.rezmason.gl.utils;

typedef Context = #if flash flash.display3D.Context3D #else Class<openfl.gl.GL> #end ;
typedef View = #if flash flash.display.Stage #else openfl.display.OpenGLView #end ;

class Util {
    var context:Context;
    var view:View;

    @:allow(net.rezmason.gl.utils.UtilitySet)
    function new(view:View, context:Context):Void {
        this.view = view;
        this.context = context;
    }
}
