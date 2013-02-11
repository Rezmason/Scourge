package net.rezmason.scourge.textview;

import nme.display.Sprite;

class CharSprite {

    public var sprite:Sprite;
    public var billboard:Billboard2D;x

    public function new(sprite:Sprite, billboard:Billboard2D):Void {
        this.sprite = sprite;
        this.billboard = billboard;
    }
}
