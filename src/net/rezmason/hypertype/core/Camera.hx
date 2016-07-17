package net.rezmason.hypertype.core;

import lime.math.Matrix4;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.math.Vector4;
import lime.utils.Float32Array;

class Camera {

    inline static function DEFAULT_VIEW_RECT():Rectangle return new Rectangle(0, 0, 1, 1);
    
    public var transform(default, null):Matrix4;
    public var scaleMode(default, set):CameraScaleMode;
    public var glyphScaleMode(default, set):CameraGlyphScaleMode;
    public var rect(default, null):Rectangle;
    public var glyphScale(default, null):Float;
    public var params(default, null):Vector4;

    public var scaleX(default, null):Float;
    public var scaleY(default, null):Float;
    
    var vanishingPoint:Vector2;

    var stageWidth:Int;
    var stageHeight:Int;

    var projection:Matrix4;

    public function new():Void {
        stageWidth = 0;
        stageHeight = 0;
        glyphScale = 0;
        scaleX = 1;
        scaleY = 1;
        transform = new Matrix4();
        projection = makeProjection();
        vanishingPoint = new Vector2();
        params = new Vector4();
        params.x = glyphScale;
        
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
        transform.appendTranslation(rect.x * 2 + rect.width - 1, rect.y * 2 + rect.height - 1, 0);
        transform.appendTranslation(0, 0, 1); // Set the camera back one unit
        transform.appendScale(1, -1, 1);
        transform.append(projection); // Apply perspective

        vanishingPoint.x = (rect.left + rect.right) * 0.5;
        vanishingPoint.y = (rect.top + rect.bottom) * 0.5;
        applyVP(0, 0);

        if (glyphScaleMode != null) {
            glyphScale = switch (glyphScaleMode) {
                case SCALE_WITH_WIDTH: scaleX;
                case SCALE_WITH_HEIGHT: scaleY;
                case SCALE_WITH_MIN: Math.min(scaleX, scaleY);
                case SCALE_WITH_MAX: Math.max(scaleX, scaleY);
                case SCALE_NONE: 1;
            }
            params.x = glyphScale;
        }
    }

    inline function applyVP(x:Float, y:Float):Void {
        var rawData:Float32Array = transform;
        rawData[8] =  ((x + vanishingPoint.x) * 2 - 1);
        rawData[9] = -((y + vanishingPoint.y) * 2 - 1);
        transform = rawData;
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
