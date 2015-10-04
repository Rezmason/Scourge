package net.rezmason.scourge.controller;

import net.rezmason.scourge.textview.View;
import net.rezmason.scourge.textview.ui.BorderBox;
import net.rezmason.utils.santa.Present;
import net.rezmason.utils.Zig;

class MoveMediator {

    public var moveChosenSignal(default, null):Zig<Int->String->Int->Void> = new Zig();
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

    public function enableHumanMoves() {
        trace('ENABLE HUMAN MOVES');
    }
}
