package net.rezmason.hypertype.core;

import lime.math.Matrix4;
import lime.math.Vector2;
import lime.math.Vector4;
import lime.utils.Float32Array;

class Camera {

    public var transform(default, null):Matrix4;
    public var params(default, null):Vector4;
    var projection:Matrix4;

    public function new():Void {
        transform = new Matrix4();
        projection = makeProjection();
        params = new Vector4();
        params.x = 1;
    }

    public function resize(width:Float, height:Float):Void {
        transform.identity();
        transform.appendScale(2 / width, -2 / height, 1); // Screen space, please
        transform.appendTranslation(-1, 1, 1); // Set the camera back one unit
        transform.append(projection); // Apply perspective

        var rawData:Float32Array = transform;
        trace([for (ike in 0...16) rawData[ike]]);
        params.x = rawData[0] * 0.5;
    }

    inline function makeProjection():Matrix4 {
        var mat:Matrix4 = new Matrix4();
        var rawData:Float32Array = mat;
        rawData[10] =  2;
        rawData[11] =  1;
        rawData[14] = -2;
        rawData[15] =  0;
        mat = rawData;
        return mat;
    }
}
