package net.rezmason.hypertype.core;

import lime.math.Rectangle;
import lime.math.Matrix4;

enum LayoutValue {
    REL(value:Float);
    ABS(value:Float);
    ZERO;
}

typedef Properties = {
    @:optional var left:LayoutValue;
    @:optional var right:LayoutValue;
    @:optional var width:LayoutValue;
    @:optional var top:LayoutValue;
    @:optional var bottom:LayoutValue;
    @:optional var height:LayoutValue;

    @:optional var align:Align;
    @:optional var verticalAlign:VerticalAlign;
    @:optional var scaleMode:ScaleMode;
}

class BoundingBox {

    static var UNIT_RECT:Rectangle = new Rectangle(0, 0, 1, 1);
    static var DEFAULT_ALIGN:Align = LEFT;
    static var DEFAULT_VERTICAL_ALIGN:VerticalAlign = TOP;
    static var DEFAULT_SCALE_MODE:ScaleMode = NO_SCALE;

    public var rect(default, null):Rectangle = UNIT_RECT.clone();
    public var transform(default, null):Matrix4 = new Matrix4();
    public var contentTransform(default, null):Matrix4 = new Matrix4();
    public var scale(default, null):Float = 1;
    public var left:Null<LayoutValue>;
    public var right:Null<LayoutValue>;
    public var width:Null<LayoutValue>;
    public var top:Null<LayoutValue>;
    public var bottom:Null<LayoutValue>;
    public var height:Null<LayoutValue>;

    public var align:Align = DEFAULT_ALIGN;
    public var verticalAlign:VerticalAlign = DEFAULT_VERTICAL_ALIGN;
    public var scaleMode:ScaleMode = DEFAULT_SCALE_MODE;

    public function new() {}

    public function solve(parent:BoundingBox) {
        var parentRect = (parent == null) ? UNIT_RECT : parent.rect;
        
        // Resolve rect using layout values
        rect.copyFrom(UNIT_RECT);
        if (left != null) rect.left = parentRect.left + derive(parentRect.width, left);
        if (right != null) rect.right = parentRect.right - derive(parentRect.width, right);
        if (width != null) rect.width = derive(parentRect.width, width);
        if (top != null) rect.top = parentRect.top + derive(parentRect.height, top);
        if (bottom != null) rect.bottom = parentRect.bottom - derive(parentRect.height, bottom);
        if (height != null) rect.height = derive(parentRect.height, height);

        // Create transform that places top left in world space
        transform.identity();
        transform.appendTranslation(rect.x - parentRect.x, rect.y - parentRect.y, 0);

        contentTransform.identity();

        // Scale the content according to scale mode
        var xScale:Float = Math.NaN;
        var yScale:Float = Math.NaN;
        switch (scaleMode) {
            case EXACT_FIT:
                xScale = rect.width;
                yScale = rect.height;
                scale = yScale;
            case NO_BORDER:
                scale = Math.max(rect.width, rect.height);
            case SHOW_ALL:
                scale = Math.min(rect.width, rect.height);
            case WIDTH_FIT:
                scale = rect.width;
            case HEIGHT_FIT:
                scale = rect.height;
            case NO_SCALE:
                scale = 1;
        }
        if (Math.isNaN(xScale)) {
            xScale = scale;
            yScale = scale;
        }
        contentTransform.appendScale(xScale, yScale, 1);

        // place the origin in local space
        var contentX = rect.width  * switch (        align) { case LEFT: 0; case CENTER: 0.5;  case RIGHT: 1; };
        var contentY = rect.height * switch (verticalAlign) { case  TOP: 0; case MIDDLE: 0.5; case BOTTOM: 1; };
        contentTransform.appendTranslation(contentX, contentY, 0);
    }

    public function set(properties:Properties) {
        left = properties.left;
        right = properties.right;
        width = properties.width;
        top = properties.top;
        bottom = properties.bottom;
        height = properties.height;

        align = (properties.align == null) ? DEFAULT_ALIGN : properties.align;
        verticalAlign = (properties.verticalAlign == null) ? DEFAULT_VERTICAL_ALIGN : properties.verticalAlign;
        scaleMode = (properties.scaleMode == null) ? DEFAULT_SCALE_MODE : properties.scaleMode;
    }

    inline function derive(inherited:Float, layoutValue:LayoutValue) {
        return switch (layoutValue) {
            case REL(value): value * inherited;
            case ABS(value): value;
            case ZERO: 0;
        }
    }
}
