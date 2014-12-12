package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;

class Camera {

    inline static function DEFAULT_VIEW_RECT():Rectangle return new Rectangle(0, 0, 1, 1);
    
    public var transform(default, null):Matrix3D;
    public var mode:CameraMode;
    public var rect(default, set):Rectangle;
    
    var vanishingPoint:Point;

    var stageWidth:Int;
    var stageHeight:Int;

    var projection:Matrix3D;

    public function new():Void {
        stageWidth = 0;
        stageHeight = 0;
        mode = SHOW_ALL;
        rect = DEFAULT_VIEW_RECT();
        projection = makeProjection();
        vanishingPoint = new Point();
        transform = new Matrix3D();
    }

    public function resize(stageWidth:Int, stageHeight:Int):Void {

        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;
        var rectRatioRatio:Float = (rect.width / rect.height) * (stageWidth / stageHeight);

        transform.identity();

        switch (mode) {
            case EXACT_FIT:
                // Distort the aspect ratio to fit the body in the rectangle
                transform.appendScale(1, 1, 1);
            case NO_BORDER:
                // Scale the body uniformly to match the dimension of the largest side of the screen
                if (rectRatioRatio > 1) transform.appendScale(1, rectRatioRatio, 1);
                else transform.appendScale(1 / rectRatioRatio, 1, 1);
            case NO_SCALE:
                // Perform no scaling logic
                transform.appendScale(rect.width / stageWidth, rect.height / stageHeight, 1);
            case SHOW_ALL:
                // Scale the body uniformly to match the dimension of the smallest side of the screen
                if (rectRatioRatio < 1) transform.appendScale(1, rectRatioRatio, 1);
                else transform.appendScale(1 / rectRatioRatio, 1, 1);
            case WIDTH_FIT:
                // Scale the body uniformly to match the width of the screen
                transform.appendScale(1, rectRatioRatio, 1);
            case HEIGHT_FIT:
                // Scale the body uniformly to match the height of the screen
                transform.appendScale(1 / rectRatioRatio, 1, 1);
        }

        transform.appendScale(rect.width * 2, rect.height * 2, 1);
        transform.appendTranslation(rect.x * 2 + rect.width - 1, -(rect.y * 2 + rect.height - 1), 0);
        transform.appendTranslation(0, 0, 1); // Set the camera back one unit
        transform.append(projection); // Apply perspective

        vanishingPoint.x = (rect.left + rect.right) * 0.5;
        vanishingPoint.y = (rect.top + rect.bottom) * 0.5;

        applyVP(0, 0);
    }

    inline function applyVP(x:Float, y:Float):Void {
        var rawData:Vector<Float> = transform.rawData;
        rawData[8] =  ((x + vanishingPoint.x) * 2 - 1);
        rawData[9] = -((y + vanishingPoint.y) * 2 - 1);
        transform.rawData = rawData;
    }

    inline function makeProjection():Matrix3D {
        var mat:Matrix3D = new Matrix3D();
        var rawData:Vector<Float> = mat.rawData;
        rawData[10] =  2;
        rawData[11] =  1;
        rawData[14] = -2;
        rawData[15] =  0;
        mat.rawData = rawData;
        return mat;
    }

    inline function set_rect(val:Rectangle):Rectangle {
        if (val == null) val = DEFAULT_VIEW_RECT();
        if (val.width <= 0 || val.height <= 0) throw 'Camera rects cannot be null.';
        rect = val;
        if (transform != null) resize(stageWidth, stageHeight);
        return val;
    }
}
