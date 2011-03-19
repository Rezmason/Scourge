package net.rezmason.display;

import flash.display.Shape;

class Pie extends Shape {
	
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
		
		var points:Array<Float> = getArc(0, 0, radius, fraction * 360, 0, true);
		
		graphics.beginFill(foregroundColor);
		graphics.moveTo(points[0][0], points[0][1]);
		var ike:Int = 1;
		while (ike < points.length) {
			graphics.curveTo(points[ike][0], points[ike++][1], points[ike][0], points[ike++][1]);
		}
		graphics.endFill();
		
	}
	
	private function getArc(centerX:Float, centerY:Float, rad:Float, arc:Float, startAngle:Float, stayOnCircle:Boolean = false):Array<Float> {
		
		// Mad props to Ric Ewing: formequalsfunction.com
		
		// var declaration is expensive
		
		var returnValue:Array = [];
		var segs:int, segAngle:Float;
		var theta:Float, angle:Float, angleMid:Float;
		var ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float;
		var xOffset:Float = centerX, yOffset:Float = centerY;
	
		if (arc < 0) arc = 0;
		
		segs = arc * 0.02222 + 1;
		segAngle = arc / segs;
	
		theta = -segAngle * DEGREES_TO_RADIANS;
		angle = -startAngle * DEGREES_TO_RADIANS;
	
		ax = -Math.cos(angle) * rad;
		ay = -Math.sin(angle) * rad;
	
		if (stayOnCircle) {
			returnValue.push([centerX - ax, centerY - ay]);
			ax = 0;
			ay = 0;
		} else {
			returnValue.push([xOffset, yOffset]);
		}
	
		while (segs--) {
			angle += theta;
			angleMid = angle - (theta * 0.5);
			bx = ax + Math.cos(angle) * rad;
			by = ay + Math.sin(angle) * rad;
			cx = ax + Math.cos(angleMid) * (rad / Math.cos(theta / 2));
			cy = ay + Math.sin(angleMid) * (rad / Math.cos(theta / 2));
			returnValue.push([cx + xOffset, cy + yOffset], [bx + xOffset, by + yOffset]);
		}
	
		return returnValue;
	}
}