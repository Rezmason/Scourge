package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;

class Camera {

    inline static function DEFAULT_VIEW_RECT():Rectangle return new Rectangle(0, 0, 1, 1);
    
    public var transform(default, null):Matrix3D;
    public var scaleMode(default, set):CameraScaleMode;
    public var glyphScaleMode(default, set):CameraGlyphScaleMode;
    public var rect(default, set):Rectangle;
    public var glyphScale(default, null):Float;

    var scaleX:Float;
    var scaleY:Float;
    
    var vanishingPoint:Point;

    var stageWidth:Int;
    var stageHeight:Int;

    var projection:Matrix3D;

    public function new():Void {
        stageWidth = 0;
        stageHeight = 0;
        glyphScale = 0;
        scaleX = 1;
        scaleY = 1;
        transform = new Matrix3D();
        projection = makeProjection();
        vanishingPoint = new Point();
        
        rect = DEFAULT_VIEW_RECT();
        scaleMode = SHOW_ALL;
        glyphScaleMode = SCALE_WITH_WIDTH;
    }

    public function resize(stageWidth:Int, stageHeight:Int):Void {

        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;

        if (scaleMode != null) {
            scaleX = 1;
            scaleY = 1;
            var rectRatioRatio:Float = (rect.width / rect.height) * (stageWidth / stageHeight);
            
            switch (scaleMode) {
                case EXACT_FIT:
                    // Distort the aspect ratio to fit the body in the rectangle
                case NO_BORDER:
                    // Scale the body uniformly to match the dimension of the largest side of the screen
                    if (rectRatioRatio > 1) scaleY = rectRatioRatio;
                    else scaleX = 1 / rectRatioRatio;
                case NO_SCALE:
                    // Perform no scaling logic
                    scaleX = rect.width / stageWidth;
                    scaleY = rect.height / stageHeight;
                case SHOW_ALL:
                    // Scale the body uniformly to match the dimension of the smallest side of the screen
                    if (rectRatioRatio < 1) {
                        scaleX = 1;
                        scaleY = rectRatioRatio;
                    } else {
                        scaleX = 1 / rectRatioRatio;
                        scaleY = 1;
                    }
                case WIDTH_FIT:
                    // Scale the body uniformly to match the width of the screen
                    scaleX = 1;
                    scaleY = rectRatioRatio;
                case HEIGHT_FIT:
                    // Scale the body uniformly to match the height of the screen
                    scaleX = 1 / rectRatioRatio;
                    scaleY = 1;
            }
        }
        
        transform.identity();
        transform.appendScale(scaleX, scaleY, 1);
        transform.appendScale(rect.width * 2, rect.height * 2, 1);
        transform.appendTranslation(rect.x * 2 + rect.width - 1, -(rect.y * 2 + rect.height - 1), 0);
        transform.appendTranslation(0, 0, 1); // Set the camera back one unit
        transform.append(projection); // Apply perspective

        vanishingPoint.x = (rect.left + rect.right) * 0.5;
        vanishingPoint.y = (rect.top + rect.bottom) * 0.5;
        applyVP(0, 0);

        if (glyphScaleMode != null) glyphScale = switch (glyphScaleMode) {
            case SCALE_WITH_WIDTH: scaleX;
            case SCALE_WITH_HEIGHT: scaleY;
            case SCALE_WITH_MIN: Math.min(scaleX, scaleY);
            case SCALE_WITH_MAX: Math.max(scaleX, scaleY);
            case SCALE_NONE: 1;
        }
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
        resize(stageWidth, stageHeight);
        return val;
    }

    inline function set_scaleMode(mode:CameraScaleMode):CameraScaleMode {
        if (mode == null) mode = SHOW_ALL;
        scaleMode = mode;
        resize(stageWidth, stageHeight);
        return scaleMode;
    }

    inline function set_glyphScaleMode(mode:CameraGlyphScaleMode):CameraGlyphScaleMode {
        if (glyphScaleMode == null) glyphScaleMode = SCALE_WITH_WIDTH;
        glyphScaleMode = mode;
        resize(stageWidth, stageHeight);
        return glyphScaleMode;
    }
}
