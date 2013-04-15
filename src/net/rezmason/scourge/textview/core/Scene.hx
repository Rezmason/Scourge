package net.rezmason.scourge.textview.core;

import nme.geom.Matrix3D;

class Scene {

    public var cameraMat(default, null):Matrix3D;
    public var bodies(default, null):Array<Body>;

    public function new():Void {
        cameraMat = new Matrix3D();
        bodies = [];
    }
}

