package net.rezmason.hypertype.core;

import lime.math.Rectangle;

enum LayoutValue {
    Proportion(value:Float);
    Unit(value:Float);
    Zero;
}

class BoundingBox {

    static var DEFAULT_RECT:Rectangle = new Rectangle(0, 0, 1, 1);
    public var output(default, null):Rectangle = DEFAULT_RECT.clone();
    public var left:Null<LayoutValue>;
    public var right:Null<LayoutValue>;
    public var width:Null<LayoutValue>;
    public var top:Null<LayoutValue>;
    public var bottom:Null<LayoutValue>;
    public var height:Null<LayoutValue>;

    public function new() {}

    public function solve(parentOutput:Rectangle) {
        if (parentOutput == null) parentOutput = DEFAULT_RECT;
        output.copyFrom(DEFAULT_RECT);
        if (left != null) output.left = parentOutput.left + derive(parentOutput.width, left);
        if (right != null) output.right = parentOutput.right - derive(parentOutput.width, right);
        if (width != null) output.width = derive(parentOutput.width, width);
        if (top != null) output.top = parentOutput.top + derive(parentOutput.height, top);
        if (bottom != null) output.bottom = parentOutput.bottom - derive(parentOutput.height, bottom);
        if (height != null) output.height = derive(parentOutput.height, height);
    }

    inline function derive(inherited:Float, layoutValue:LayoutValue) {
        return switch (layoutValue) {
            case Proportion(value): value * inherited;
            case Unit(value): value;
            case Zero: 0;
        }
    }
}
