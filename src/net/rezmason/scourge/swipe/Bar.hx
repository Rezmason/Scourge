package net.rezmason.scourge.swipe;

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Quart;

using net.kawa.tween.KTween;
using net.rezmason.flash.display.FastDraw;

class Bar extends SwipeBox {

	private var _width:Float;
	private var _height:Float;
	private var originalRects:Array<Rectangle>;
	private var tween:{value:Float};
	private var tweenJob:KTJob;
	private var swipe:Swipe;
	public var autoLiftChildren(default, setAutoLiftChildren):Bool;

	public function new():Void {
		super();
		tween = {value:0.0};
		autoLiftChildren = false;
	}

	public function liftChild(child:SwipeBox):Void {
		if (child.parent == this) addChild(child);
	}

	public function dropChild(child:SwipeBox):Void {
		if (child.parent == this) addChildAt(child, 0);
	}

	public override function resize(__width:Float, __height:Float):Void {
		_width = __width;
		_height = __height;
		var swipeHeight:Float = (_height - Layout.SWIPE_OVERLAP) / numChildren + Layout.SWIPE_OVERLAP;
		clear().drawBox(0x222222, 1, 0, 0, _width, _height);
		for (i in 0...numChildren) {
			var child:SwipeBox = cast getChildAt(i);
			if (child != null) child.resize(_width, swipeHeight);
		}
		arrangeY(Layout.SWIPE_OVERLAP);
	}

	public function expandFromSwipe(_swipe:Swipe):Void {
		if (tweenJob != null) tweenJob.complete();
		swipe = _swipe;
		pack(cast swipe.relatedObject);
		resize(_width, _height);
		generateOriginalRects();
		tweenJob = tween.fromTo(0.2, {value:0}, {value:1}, Quart.easeOut, endExpand);
		tweenJob.onChange = updateTween;
		updateTween();
	}

	public function collapseToSwipe(_swipe:Swipe):Void {
		if (tweenJob != null) tweenJob.complete();
		swipe = _swipe;
		generateOriginalRects();
		tweenJob = tween.fromTo(0.2, {value:1}, {value:0}, Quart.easeOut, endCollapse);
		tweenJob.onChange = updateTween;
		updateTween();
	}

	private function updateTween():Void {
		for (i in 0...numChildren) {
			var child:SwipeBox = cast getChildAt(i);
			var originalRect:Rectangle = originalRects[i];
			var rect:Rectangle = child.box;

			var val:Float = tween.value;
			var inv:Float = 1 - tween.value;

			rect.y      = originalRect.y      * val + swipe.y      * inv;
			rect.height = originalRect.height * val + swipe.height * inv;

			child.box = rect;
			child.alpha = val;
		}
	}

	private function endExpand():Void {
		swipe = null;
	}

	private function endCollapse():Void {
		swipe = null;
		for (i in 0...numChildren) {
			var child:SwipeBox = cast getChildAt(i);
			child.box = originalRects[i];
			child.alpha = 1;
		}
		empty();
	}

	private function generateOriginalRects():Void {
		originalRects = [];
		for (i in 0...numChildren) {
			var child:SwipeBox = cast getChildAt(i);
			originalRects.push(child.box);
		}
	}

	private function setAutoLiftChildren(value:Bool):Bool {
		if (value == autoLiftChildren) return value;
		autoLiftChildren = value;
		if (value) {
			addEventListener(MouseEvent.MOUSE_OVER, autoLift, true);
		} else {
			removeEventListener(MouseEvent.MOUSE_OVER, autoLift, true);
		}

		return value;
	}

	private function autoLift(event:Event):Void {
		var target:DisplayObject = event.target;
		if (target == this) return;

		while (target.parent != this) target = target.parent;

		liftChild(cast target);
	}

}
