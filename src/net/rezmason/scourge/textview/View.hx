package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.ui.BorderBox;

class View {

    public var body(default, null):Body;
    public var board(default, null):Body;
    public var loupe(default, null):BorderBox;
    public var piece(default, null):Body;
    public var bite(default, null):Body;

    public function new():Void {
        body = new Body();
        board = new Body();
        loupe = new BorderBox();
        loupe.glyphWidth = 0.05;
        piece = new Body();
        bite = new Body();

        body.addChild(board);
        body.addChild(loupe.body);
        body.addChild(piece);
        body.addChild(bite);
    }
}
