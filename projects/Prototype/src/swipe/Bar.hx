package swipe;

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Quart;

using net.kawa.tween.KTween;
using utils.display.FastDraw;

class Bar extends SwipeBox {

	private var _width:Float;
	private var _height:Float;
	private var originalRects:Array<Rectangle>;
	private var tween:{value:Float};
	private var tweenJob:KTJob;
	private var swipe:Swipe;
	public var autoLiftChildren(default, set):Bool;
	public var contents(get, set):Array<SwipeBox>;
	private var _contents:Array<SwipeBox>;

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
		if (_contents != null) {
			var numContents:Int = _contents.length;
			var numUnits:Float = 0;
			for (child in _contents) numUnits += child.unitHeight;
			var swipeHeight:Float = (_height - Layout.SWIPE_OVERLAP) / numUnits;
			for (child in _contents) child.resize(_width, swipeHeight * child.unitHeight + Layout.SWIPE_OVERLAP);
			arrangeY(cast _contents, Layout.SWIPE_OVERLAP);
		}
		clear().drawBox(0x222222, 1, 0, 0, _width, _height);
	}

	public function expandFromSwipe(_swipe:Swipe):Void {
		if (tweenJob != null) tweenJob.complete();
		swipe = _swipe;
		contents = cast swipe.relatedObject;
		if (_contents != null) {
			generateOriginalRects();
			tweenJob = tween.fromTo(0.2, {value:0}, {value:1}, Quart.easeOut, endExpand);
			tweenJob.onChange = updateTween;
			updateTween();
		}
	}

	public function collapseToSwipe(_swipe:Swipe):Void {
		if (tweenJob != null) tweenJob.complete();
		swipe = _swipe;
		if (_contents != null) {
			generateOriginalRects();
			tweenJob = tween.fromTo(0.2, {value:1}, {value:0}, Quart.easeOut, endCollapse);
			tweenJob.onChange = updateTween;
			updateTween();
		}
	}

	private function updateTween():Void {
		if (_contents != null) {
			for (i in 0..._contents.length) {
				var originalRect:Rectangle = originalRects[i];
				var child:SwipeBox = _contents[i];
				var rect:Rectangle = child.box;

				var val:Float = tween.value;
				var inv:Float = 1 - tween.value;

				if (rect != null && originalRect != null) {
					rect.y      = originalRect.y      * val + swipe.y      * inv;
					rect.height = originalRect.height * val + swipe.height * inv;
					child.box = rect;
				}

				child.alpha = val;
			}
		}
	}

	private function endExpand():Void {
		swipe = null;
	}

	private function endCollapse():Void {
		swipe = null;
		if (_contents != null) {
			for (i in 0..._contents.length) {
				var child:SwipeBox = _contents[i];
				child.box = originalRects[i];
				child.alpha = 1;
			}
		}
		contents = null;
	}

	private function generateOriginalRects():Void {
		originalRects = [];
		for (child in _contents) originalRects.push(child.box);
	}

	private function set_autoLiftChildren(value:Bool):Bool {
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

	private function get_contents():Array<SwipeBox> { return _contents == null ? null : _contents.copy(); }

	private function set_contents(value:Array<SwipeBox>):Array<SwipeBox> {
		if (value != _contents) {
			if (_contents != null) for (child in _contents) removeChild(child);
			_contents = value;
			if (_contents != null) for (child in _contents) addChild(child);
		}
		resize(_width, _height);
		return _contents;
	}
}
