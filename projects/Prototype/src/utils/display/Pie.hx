package utils.display;

import flash.display.Shape;

class Pie extends Shape {

	private inline static function DEGREES_TO_RADIANS():Float return Math.PI / 180;

	public var foregroundColor:Int;
	public var backgroundColor:Int;
	public var fraction:Float;
	public var radius:Float;

	public function new(_radius:Float, _foregroundColor:Int, _backgroundColor:Int):Void {
		super();
		radius = _radius;
		foregroundColor = _foregroundColor;
		backgroundColor = _backgroundColor;
	}

	public function redraw():Void {
		graphics.clear();
		graphics.beginFill(backgroundColor);
		graphics.drawCircle(0, 0, radius);
		graphics.endFill();

		var points:Array<Array<Float>> = getArc(0, 0, radius + 0.5, fraction * 360, 0, true);

		graphics.beginFill(foregroundColor);
		graphics.moveTo(0, 0);
		graphics.lineTo(points[0][0], points[0][1]);
		var ike:Int = 1;
		while (ike < points.length) {
			graphics.curveTo(points[ike][0], points[ike++][1], points[ike][0], points[ike++][1]);
		}
		graphics.endFill();

	}

	private function getArc(centerX:Float, centerY:Float, rad:Float, arc:Float, startAngle:Float, stayOnCircle:Bool = false):Array<Array<Float>> {

		// Mad props to Ric Ewing: formequalsfunction.com

		// var declaration is expensive

		var returnValue:Array<Array<Float>> = [];
		var segs:Int;
		var segAngle:Float;
		var theta:Float;
		var angle:Float;
		var angleMid:Float;
		var ax:Float;
		var ay:Float;
		var bx:Float;
		var by:Float;
		var cx:Float;
		var cy:Float;
		var xOffset:Float = centerX;
		var yOffset:Float = centerY;

		if (arc < 0) arc = 0;

		segs = Std.int(arc * 0.02222 + 1);
		segAngle = arc / segs;

		theta = -segAngle * DEGREES_TO_RADIANS();
		angle = -startAngle * DEGREES_TO_RADIANS();

		ax = -Math.cos(angle) * rad;
		ay = -Math.sin(angle) * rad;

		if (stayOnCircle) {
			returnValue.push([centerX - ax, centerY - ay]);
			ax = 0;
			ay = 0;
		} else {
			returnValue.push([xOffset, yOffset]);
		}

		while (segs-- != 0) {
			angle += theta;
			angleMid = angle - (theta * 0.5);
			bx = ax + Math.cos(angle) * rad;
			by = ay + Math.sin(angle) * rad;
			cx = ax + Math.cos(angleMid) * (rad / Math.cos(theta / 2));
			cy = ay + Math.sin(angleMid) * (rad / Math.cos(theta / 2));
			returnValue.push([cx + xOffset, cy + yOffset]);
			returnValue.push([bx + xOffset, by + yOffset]);
		}

		return returnValue;
	}
}
