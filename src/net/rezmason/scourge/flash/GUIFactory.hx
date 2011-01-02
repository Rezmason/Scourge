package net.rezmason.scourge.flash;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.GradientType;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.IEventDispatcher;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.Lib;

class GUIFactory {
	
	// QUESTION FOR THE LIST: How do I determine whether an instance extends a class?
	// QUESTION FOR THE LIST: How might I merge types? var n:Dynamic<Class1, Class2>
	
	public static var MISO:String = "miso";
	private static var __miso:Font = null;
	
	private static var numTeeth:Int = 0;
	
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
	
	public static function makeHead(size:Float, ?ct:ColorTransform):Shape {
		var shp:Shape = new Shape();
		var gMat:Matrix = new Matrix();
		gMat.createGradientBox(size * 2, size * 2, 0, -size, -size);
		shp.graphics.beginGradientFill(GradientType.RADIAL, [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF], [1, 0.5, 0.15, 0], [0xA0, 0xA8, 0xC0, 0xFF], gMat);
		shp.graphics.drawCircle(0, 0, size);
		shp.graphics.endFill();
		shp.graphics.beginFill(0x111111);
		shp.graphics.drawCircle(0, 0, size * 0.425);
		shp.graphics.endFill();
		shp.visible = false;
		shp.blendMode = BlendMode.ADD;
		shp.cacheAsBitmap = true;
		if (ct != null) shp.transform.colorTransform = ct;
		return shp;
	}
	
	public static function makeTooth(?size:Null<Float>):Sprite {
		if (size == null) size = 15;
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
	
	public static function makePointer():Sprite {
		return new ScourgeLib_MousePointer();
	}
	
	public static function drawSolidRect(targ:Dynamic, color:Int, alpha:Float, x:Float, y:Float, width:Float, height:Float, ?cornerRadius:Float = 0):Dynamic {
		targ.graphics.beginFill(color, alpha);
		targ.graphics.drawRoundRect(x, y, width, height, cornerRadius, cornerRadius);
		targ.graphics.endFill();
		return targ;
	}
	
	public static function makeBitmapShape(bitmap:BitmapData, ?scale:Float = 1, ?smooth:Bool = true, ?ct:ColorTransform):Shape {
		var shp:Shape = new Shape();
		var mat:Matrix = new Matrix();
		mat.scale(scale, scale);
		shp.graphics.beginBitmapFill(bitmap, mat, false, smooth);
		shp.graphics.drawRect(0, 0, bitmap.width * scale, bitmap.height * scale);
		shp.graphics.endFill();
		if (ct != null) shp.transform.colorTransform = ct;
		return shp;
	}
	
	public static function makeContainer(children:Array<Dynamic>):Sprite {
		return fillSprite(new Sprite(), children);
	}
	
	public static function fillSprite(sprite:Sprite, children:Array<Dynamic>):Sprite {
		children = children.copy();
		while (children.length > 0) sprite.addChildAt(children.pop(), 0);
		return sprite;
	}
	
	public static function makeCT(color:Int, ?alpha:Float = 1.0):ColorTransform {
		var ct:ColorTransform = new ColorTransform();
		ct.redMultiplier = ((color >> 16) & 0xFF) / 0xFF;
		ct.greenMultiplier = ((color >>  8) & 0xFF) / 0xFF;
		ct.blueMultiplier = ((color >> 0) & 0xFF) / 0xFF;
		ct.alphaMultiplier = alpha;
		return ct;
	}
	
	public static function makeTextBox(?w:Float = 0, ?h:Float = 0, ?fontName:String = "_sans", 
			?fontSize:Float = 12, ?color:Int = 0xFFFFFF, ?rightAlign:Bool = false, ?multiline:Bool = false):TextField {
		var textBox:TextField = new TextField();
		//textBox.border = true;
		//textBox.borderColor = 0xFFFFFF;
		
		if (fontName == MISO) {
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
	
	public static function gray(value:Int):UInt {
		value = value % 0xFF;
		return 0xFF000000 | (value << 16) | (value << 8) | value;
	}
}