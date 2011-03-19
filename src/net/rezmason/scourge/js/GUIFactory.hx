package net.rezmason.scourge.js;

/*
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
*/

import easeljs.Container;
import easeljs.Graphics;
import easeljs.Shape;
	
class GUIFactory {
	
	public static var MISO:String = "miso";
	//private static var __miso:Font = null;
	
	private static var numTeeth:Int = 0;
	/*
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
	*/
	/*
	public static function wireUp(target:IEventDispatcher, ?onRollOver:Dynamic, ?onRollOut:Dynamic, ?onClick:Dynamic):Void {
		if (onRollOver) target.addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		if (onRollOut) target.addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		if (onClick) target.addEventListener(MouseEvent.CLICK, onClick);
	}
	*/
	/*
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
		if (ct != null) shp.transform.colorTransform = ct;
		return shp;
	}
	*/
	
	public static function makeTooth(?size:Null<Float>):Container {
		if (size == null) size = 15;
		var toothContainer:Container = new Container();
		var tooth:Shape = new Shape();
		toothContainer.addChild(tooth);
		tooth.graphics.beginFill(colorString(0x888888));
		tooth.graphics.moveTo(0, -size / 2);
		tooth.graphics.lineTo(size / 2, 0);
		tooth.graphics.lineTo(0, size / 2);
		tooth.graphics.lineTo(-size / 2, 0);
		tooth.graphics.lineTo(0, -size / 2);
		tooth.graphics.endFill();
		tooth.name = "tooth" + numTeeth;
		//tooth.blendMode = BlendMode.ADD;
		numTeeth++;
		return toothContainer;
	}
	/*
	public static function makePointer():Sprite {
		return new ScourgeLib_MousePointer();
	}
	*/
	public static function drawSolidRect(targ:Shape, color:Int, alpha:Float, x:Float, y:Float, width:Float, height:Float, ?cornerRadius:Float = 0):Shape {
		targ.graphics.beginFill(colorString(color, alpha)).drawRoundRect(x, y, width, height, cornerRadius / 2).endFill();
		return targ;
	}
	/*
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
	*/
	public static function makeContainer(children:Array<Dynamic>):Container {
		return fillContainer(new Container(), children);
	}
	public static function fillContainer(container:Container, children:Array<Dynamic>):Container {
		children = children.copy();
		while (children.length > 0) container.addChildAt(children.pop(), 0);
		return container;
	}
	/*
	public static function makeCT(color:Int, ?alpha:Float = 1.0):ColorTransform {
		var ct:ColorTransform = new ColorTransform();
		ct.redMultiplier = ((color >> 16) & 0xFF) / 0xFF;
		ct.greenMultiplier = ((color >>  8) & 0xFF) / 0xFF;
		ct.blueMultiplier = ((color >> 0) & 0xFF) / 0xFF;
		ct.alphaMultiplier = alpha;
		return ct;
	}
	*/
	/*
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
	*/
	public static function colorString(color:Int, ?alpha:Float = 1):String {
		var alphaInt:Int = 0;
		if (alpha != 1) {
			alphaInt = Std.int(alpha / 0xFF) << 24;
			color = color | alphaInt;
		}
		return "#" + StringTools.hex(color);
	}
}