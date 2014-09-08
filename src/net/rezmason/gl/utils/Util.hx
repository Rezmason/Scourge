package net.rezmason.gl.utils;

import net.rezmason.gl.GLTypes;

class Util {
    var context:Context;
    var view:View;

    @:allow(net.rezmason.gl.utils.UtilitySet)
    function new(view:View, context:Context):Void {
        this.view = view;
        this.context = context;
    }
}
