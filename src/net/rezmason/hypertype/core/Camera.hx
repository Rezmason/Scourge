package net.rezmason.hypertype.core;

import lime.math.Matrix4;
import lime.math.Vector2;

class Camera {

    public var transform(default, null):Matrix4 = new Matrix4();
    public var screenSize(default, null):Vector2 = new Vector2();
    var projection:Matrix4;

    public function new():Void projection = makeProjection();

    public function resize(width:Float, height:Float):Void {
        transform.identity();
        transform.appendScale(2 / width, -2 / height, 1); // Screen space, please
        transform.appendTranslation(-1, 1, 1); // Set the camera back one unit
        transform.append(projection); // Apply perspective
        screenSize.x = width;
        screenSize.y = height;
    }

    inline function makeProjection():Matrix4 {
        var mat:Matrix4 = new Matrix4();
        mat.set(10,  2);
        mat.set(11,  1);
        mat.set(14, -2);
        mat.set(15,  0);
        return mat;
    }
}
