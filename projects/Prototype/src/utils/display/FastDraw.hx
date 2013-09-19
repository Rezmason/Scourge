package utils.display;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.display.GradientType;

import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import net.kawa.tween.KTJob;

using net.kawa.tween.KTween;
using Reflect;

typedef GraphicsDad = {
	var graphics(default, null):Graphics;
}

typedef Container = DisplayObjectContainer;

class FastDraw {

	private inline static function DEGREES_TO_RADIANS():Float return Math.PI / 180;

	public static inline function clear(dad:GraphicsDad):GraphicsDad {
		dad.graphics.clear();
		return dad;
	}

	public static inline function drawBox(dad:GraphicsDad, color:Int, alpha:Float, x:Float, y:Float, width:Float, height:Float):GraphicsDad {
		if (width * height != 0 && !Math.isNaN(width * height)) {
			var graphics:Graphics = dad.graphics;
			graphics.beginFill(color, alpha);
			graphics.drawRect(x, y, width, height);
			graphics.endFill();
		}
		return dad;
	}

	public static inline function drawGradientBox(dad:GraphicsDad, colors:Array<UInt>, alphas:Array<Float>, ratios:Array<Int>,
			angle:Float, x:Float, y:Float, width:Float, height:Float):GraphicsDad {
		if (width * height != 0 && !Math.isNaN(width * height)) {
			var graphics:Graphics = dad.graphics;
			var mat:Matrix = new Matrix();
			mat.createGradientBox(width, height, angle * DEGREES_TO_RADIANS());
			graphics.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, mat);
			graphics.drawRect(x, y, width, height);
			graphics.endFill();
		}
		return dad;
	}

	public static inline function pack(container:Container, children:Array<Dynamic>):Container {
		for (child in children) container.addChild(child);
		return container;
	}

	public static inline function empty(container:Container):Container {
		container.removeChildren();
		return container;
	}

	public static inline function arrangeY(container:Container, objects:Array<DisplayObject>, ?overlap:Float = 0):Container {
		var y:Float = 0;
		for (object in objects) {
			object.y = 0;
			var bounds:Rectangle = object.getBounds(container);
			if (bounds.height != 0) {
				object.y = y - bounds.y;
				y += bounds.bottom - overlap;
			}
		}
		return container;
	}

	public static inline function toTextField(str:String, format:TextFormat):TextField {
		var tf:TextField = new TextField();
		tf.defaultTextFormat = format;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.text = str;
		tf.selectable = tf.mouseEnabled = false;
		return tf;
	}
}
