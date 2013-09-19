package view;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.GradientType;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.IEventDispatcher;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

using Reflect;
using Type;

class GUIFactory {

	private inline static function DEGREES_TO_RADIANS():Float return Math.PI / 180;

	public static var MISO_FONT:String = "miso";
	private static var __miso:Font = null;

	private static var numTeeth:Int = 0;

	public inline static function makeButton(clazz:Class<DisplayObject>, hitClazz:Class<DisplayObject>, ?scale:Float = 1, ?angle:Float = 0, ?flip:Bool = false):SimpleButton {

		var returnVal:SimpleButton = new SimpleButton();
		returnVal.upState = returnVal.downState = clazz.createEmptyInstance();
		returnVal.overState = clazz.createEmptyInstance();
		returnVal.upState.alpha = 0.5;
		returnVal.hitTestState = hitClazz.createEmptyInstance();
		returnVal.tabEnabled = false;
		returnVal.rotation = angle;
		returnVal.scaleX = returnVal.scaleY = scale;
		if (flip) returnVal.scaleY *= -1;
		return returnVal;
	}

	public inline static function wireUp(target:IEventDispatcher, ?onRollOver:Dynamic, ?onRollOut:Dynamic, ?onClick:Dynamic):Void {
		if (onRollOver != null) target.addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		if (onRollOut != null) target.addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		if (onClick != null) target.addEventListener(MouseEvent.CLICK, onClick);
	}

	public inline static function makeHead(size:Float):Shape {
		var shp:Shape = new Shape();
		var gMat:Matrix = new Matrix();
		gMat.createGradientBox(size * 2, size * 2, 0, -size, -size);
		shp.graphics.beginGradientFill(GradientType.RADIAL, [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF], [1, 0.5, 0.15, 0], [0xA0, 0xA8, 0xC0, 0xFF], gMat);
		shp.graphics.drawCircle(0, 0, size);
		shp.graphics.endFill();
		shp.graphics.beginFill(0x111111);
		shp.graphics.drawCircle(0, 0, size * 0.375);
		shp.graphics.endFill();
		shp.visible = false;
		shp.blendMode = BlendMode.ADD;
		shp.cacheAsBitmap = true;
		return shp;
	}

	public inline static function makeTooth(size:Float):Sprite {
		var tooth:Sprite = new Sprite();
		tooth.graphics.beginFill(0x888888);
		tooth.graphics.moveTo(0, -size / 2);
		tooth.graphics.lineTo(size / 2, 0);
		tooth.graphics.lineTo(0, size / 2);
		tooth.graphics.lineTo(-size / 2, 0);
		tooth.graphics.lineTo(0, -size / 2);
		tooth.graphics.endFill();
		tooth.name = "tooth" + numTeeth;
		tooth.blendMode = BlendMode.ADD;
		numTeeth++;
		return tooth;
	}

	public inline static function makePointer():Sprite {
		return new ScourgeLib_MousePointer();
	}

	public inline static function drawSolidRect(shp:Shape, color:Int, alpha:Float, x:Float, y:Float, width:Float, height:Float, ?cornerRadius:Float = 0):Shape {
		shp.graphics.beginFill(color, alpha);
		shp.graphics.drawRoundRect(x, y, width, height, cornerRadius, cornerRadius);
		shp.graphics.endFill();
		return shp;
	}

	public inline static function drawSolidPoly(shp:Shape, color:Int, alpha:Float, sides:Int, centerX:Float, centerY:Float, radius:Float, ?angle:Float = 0, ?cornerRadius:Float = 0):Shape {
		var points:Array<Float> = []; // x, y, angle
		var corners:Array<Float> = []; // x, y, angle
		angle = angle * DEGREES_TO_RADIANS();

		// get all the corners
		for (ike in 0...sides) {
			var a:Float = angle + Math.PI * 2 * ike / sides;
			corners.push(radius * Math.cos(a));
			corners.push(radius * Math.sin(a));
			corners.push(a);
		}

		var ike:Int = 0;

		shp.graphics.beginFill(color, alpha);
		shp.graphics.moveTo(corners[ike] + centerX, corners[ike + 1] + centerY);
		ike += 3;
		while (ike < corners.length) {
			shp.graphics.lineTo(corners[ike] + centerX, corners[ike + 1] + centerY);
			ike += 3;
		}
		shp.graphics.endFill();

		return shp;
	}

	public inline static function drawSolidCircle(shp:Shape, color:Int, alpha:Float, x:Float, y:Float, radius:Float):Shape {
		return drawSolidRect(shp, color, alpha, x, y, radius, radius, radius);
	}

	public inline static function drawBitmapToShape(shp:Shape, bitmap:BitmapData, ?scale:Float = 1, ?smooth:Bool = true, ?cornerRadius:Float = 0):Shape {
		var mat:Matrix = new Matrix();
		mat.scale(scale, scale);
		shp.graphics.beginBitmapFill(bitmap, mat, false, smooth);
		if (!(cornerRadius == cornerRadius)) cornerRadius = 0;
		shp.graphics.drawRoundRect(0, 0, bitmap.width * scale, bitmap.height * scale, cornerRadius, cornerRadius);
		shp.graphics.endFill();
		return shp;
	}

	public inline static function makeContainer(children:Array<Dynamic>):Sprite {
		return fillSprite(new Sprite(), children);
	}

	public inline static function fillSprite(sprite:Sprite, children:Array<Dynamic>):Sprite {
		children = children.copy();
		while (children.length > 0) sprite.addChildAt(children.pop(), 0);
		return sprite;
	}

	public inline static function makeCT(color:Int, ?alpha:Float = 1.0):ColorTransform {
		var ct:ColorTransform = new ColorTransform();
		ct.redMultiplier = ((color >> 16) & 0xFF) / 0xFF;
		ct.greenMultiplier = ((color >>  8) & 0xFF) / 0xFF;
		ct.blueMultiplier = ((color >> 0) & 0xFF) / 0xFF;
		ct.alphaMultiplier = alpha;
		return ct;
	}

	public inline static function makeTextBox(?w:Float = 0, ?h:Float = 0, ?fontName:String = "_sans",
			?fontSize:Float = 12, ?color:Int = 0xFFFFFF, ?rightAlign:Bool = false, ?multiline:Bool = false):TextField {
		var textBox:TextField = new TextField();
		//textBox.border = true; textBox.borderColor = 0xFFFFFF;

		if (fontName == MISO_FONT) {
			if (__miso == null) {
				Font.registerFont(ScourgeLib_MISO);
				__miso = new ScourgeLib_MISO();
			}
			fontName = __miso.fontName;
		}

		if (w > 0) textBox.width = w;
		if (h > 0) textBox.height = h;
		var format:TextFormat = new TextFormat(fontName, fontSize, color);
		if (rightAlign) format.align = TextFormatAlign.RIGHT;
		textBox.defaultTextFormat = format;
		textBox.mouseEnabled = false;
		textBox.selectable = false;
		textBox.embedFonts = fontName.charAt(0) != "_";
		textBox.multiline = multiline;
		textBox.blendMode = BlendMode.LAYER;

		return textBox;
	}


	private inline static function getArc(centerX:Float, centerY:Float, rad:Float, arc:Float, startAngle:Float, stayOnCircle:Bool = false):Array<Array<Float>> {

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
