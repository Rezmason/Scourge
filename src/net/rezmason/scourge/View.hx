package net.rezmason.scourge;

import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Container;
import net.rezmason.hypertype.ui.BorderBox;

class View {

    public var container(default, null):Container;
    public var board(default, null):Body;
    public var loupe(default, null):BorderBox;
    public var piece(default, null):Body;
    public var bite(default, null):Body;

    public var boardScale:Float;

    public function new():Void {
        container = new Container();
        board = new Body();
        loupe = new BorderBox();
        loupe.glyphWidth = 0.5;
        piece = new Body();
        bite = new Body();
        boardScale = 1;

        container.addChild(board);
        container.addChild(loupe.body);
        container.addChild(piece);
        container.addChild(bite);
    }
}
    
