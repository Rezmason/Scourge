package net.rezmason.scourge.controller;

import net.rezmason.scourge.textview.View;
import net.rezmason.scourge.textview.ui.BorderBox;
import net.rezmason.utils.santa.Present;

class MoveMediator {

    var num:Float = 0;
    var loupe:BorderBox;

    public function new() {
        var view:View = new Present(View);
        loupe = view.loupe;
        loupe.body.updateSignal.add(onUpdate);    
    }

    function onUpdate(delta) {
        num += delta;
        loupe.width  = (Math.sin(num * 2) * 0.5 + 0.5) * 0.5;
        loupe.height = (Math.sin(num * 3) * 0.5 + 0.5) * 0.5;
        loupe.redraw();
    }
}
