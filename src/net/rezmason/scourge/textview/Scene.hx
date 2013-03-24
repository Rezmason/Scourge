package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;

class Scene {

    public var cameraMat(default, null):Matrix3D;
    public var models(default, null):Array<Model>;

    public function new():Void {
        cameraMat = new Matrix3D();
        models = [];
    }
}

