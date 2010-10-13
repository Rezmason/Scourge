package net.rezmason.scourge;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.GradientType;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.events.IEventDispatcher;
import flash.events.MouseEvent;
import flash.Lib;

class GUIFactory {
	
	public static function makeButton(clazz:Class<DisplayObject>, hitClazz:Class<DisplayObject>, ?scale:Float = 1, ?angle:Float = 0, ?flip:Bool = false):SimpleButton {
		var returnVal:SimpleButton = new SimpleButton();
		returnVal.upState = returnVal.downState = Type.createEmptyInstance(clazz);
		returnVal.overState = Type.createEmptyInstance(clazz);
		returnVal.upState.alpha = 0.5;
		returnVal.hitTestState = Type.createEmptyInstance(hitClazz);
		returnVal.tabEnabled = false;
		returnVal.rotation = angle;
		returnVal.scaleX = returnVal.scaleY = scale;
		if (flip) returnVal.scaleY *= -1;
		return returnVal;
	}
	
	public static function wireUp(target:IEventDispatcher, ?onRollOver:Dynamic, ?onRollOut:Dynamic, ?onClick:Dynamic):Void {
		if (onRollOver) target.addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		if (onRollOut) target.addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		if (onClick) target.addEventListener(MouseEvent.CLICK, onClick);
	}
	
	public static function makeHead(size:Float):Shape {
		var shp:Shape = new Shape();
		var gMat:Matrix = new Matrix();
		shp.visible = false;
		gMat.createGradientBox(size * 2, size * 2, 0, -size, -size);
		shp.graphics.beginGradientFill(GradientType.RADIAL, [0xFFFFFF, 0xFFFFFF], [0.5, 0], [0x80, 0xFF], gMat);
		shp.graphics.drawCircle(0, 0, size);
		shp.graphics.endFill();
		shp.graphics.lineStyle(4, 0xFFFFFF);
		shp.graphics.beginFill(0x222222);
		shp.graphics.drawCircle(0, 0, size * 0.5);
		shp.graphics.endFill();
		shp.blendMode = BlendMode.ADD;
		return shp;
	}
	
	public static function makeBitmapShape(bitmap:BitmapData, ?scale:Float = 1, ?smooth:Bool = true):Shape {
		var shp:Shape = new Shape();
		var mat:Matrix = new Matrix();
		mat.scale(scale, scale);
		shp.graphics.beginBitmapFill(bitmap, mat, false, smooth);
		shp.graphics.drawRect(0, 0, bitmap.width * scale, bitmap.height * scale);
		shp.graphics.endFill();
		return shp;
	}
	
	public static function makeCT(color:Int, ?alpha:Float = 1.0):ColorTransform {
		var ct:ColorTransform = new ColorTransform();
		ct.redMultiplier = ((color >> 16) & 0xFF) / 0xFF;
		ct.greenMultiplier = ((color >>  8) & 0xFF) / 0xFF;
		ct.blueMultiplier = ((color >> 0) & 0xFF) / 0xFF;
		ct.alphaMultiplier = alpha;
		return ct;
	}
	
	public static function gray(value:Int):UInt {
		value = value % 0xFF;
		return 0xFF000000 | (value << 16) | (value << 8) | value;
	}
}