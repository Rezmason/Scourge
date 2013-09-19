package swipe;

import flash.display.Shape;
import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Quart;

import swipe.SwipeButton;

using net.kawa.tween.KTween;
using utils.display.FastDraw;

typedef GrabCallback = Swipe->Void;
typedef DropCallback = Swipe->Void;
typedef DragCallback = Swipe->Float->Void;
typedef HintCallback = Swipe->Bool->Void;

typedef SwipeInitObject = {
	var grab:GrabCallback;
	var drop:DropCallback;
	var drag:DragCallback;
	var hint:HintCallback;
}

class Swipe extends SwipeBox {

	private static var SWIPE_CAPTION_FORMAT:TextFormat = new TextFormat("_sans", 40, 0xFFFFFF, true);

	private var caption:String;
	public var relatedObject(default, null):Dynamic;
	public var grabCallback:GrabCallback;
	public var dropCallback:DropCallback;
	public var dragCallback:DragCallback;
	public var hintCallback:HintCallback;
	public var percent(default, null):Float;
	private var hinting:Bool;
	private var thumbWidth:Float;
	private var trackWidth:Float;
	private var _height:Float;

	private var lastPercent:Float;

	// composition

	private var dragThumb:SwipeButton;
	private var dragTrack:Shape;
	private var captionText:TextField;

	private var snapJob:KTJob;
	private var fadeJob:KTJob;

	private var dragX:Float;
	private var dragged:Bool;

	private var startX:Float;

	private var captionRect:Rectangle;

	public function new(__caption:String, __content:ContentType, __relatedObject:Dynamic, initObject:SwipeInitObject):Void {

		super();

		dragThumb = new SwipeButton(__content);
		dragTrack = new Shape();
		captionText = __caption.toTextField(SWIPE_CAPTION_FORMAT);

		pack([dragTrack, captionText, dragThumb]);

		captionRect = new Rectangle();

		percent = 0.0;
		lastPercent = 0.0;
		thumbWidth = 0;
		trackWidth = 0;
		_height = 0;
		hinting = false;
		dragged = false;

		dragTrack.drawGradientBox([0xFFFFFF, 0xFFFFFF], [0.1, 0.8], [0x0, 0xDD], 0, 0, 0, 1, 1);
		dragThumb.addEventListener(MouseEvent.MOUSE_DOWN, beginDrag);
		dragThumb.addEventListener(MouseEvent.ROLL_OVER, showHint);
		dragThumb.addEventListener(MouseEvent.ROLL_OUT, hideHint);
		dragThumb.addEventListener(MouseEvent.CLICK, evaluateClick);

		caption = __caption;
		relatedObject = __relatedObject;
		grabCallback = initObject.grab;
		dropCallback = initObject.drop;
		dragCallback = initObject.drag;
		hintCallback = initObject.hint;
	}

	public override function resize(__thumbWidth:Float, __height:Float):Void {
		thumbWidth = __thumbWidth;
		_height = __height;
		redraw();
	}

	public function resizeTrack(__trackWidth:Float):Void {
		trackWidth = __trackWidth;
		updatePosition(false);
	}

	public function hide():Void {
		disableDrag();
		if (fadeJob != null) fadeJob.complete();
		fadeJob = to(0.5, {alpha:0, visible:false});
	}

	public function show(?thenDragBack:Bool):Void {
		if (fadeJob != null) fadeJob.complete();
		visible = true;
		fadeJob = to(0.25, {alpha:1}, Quart.easeOut, enableDrag);
		if (thenDragBack) {
			fadeJob.onComplete = collapseDrag;
		}
	}

	private function beginDrag(event:Event):Void {
		startX = dragThumb.x;
		dragX = dragThumb.mouseX;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, updateDrag);
		stage.addEventListener(MouseEvent.MOUSE_UP, endDrag);
		stage.addEventListener(Event.MOUSE_LEAVE, endDrag);
		updatePosition();
	}

	private function updateDrag(?event:Event):Void {
		percent = Math.max(0, startX + mouseX - dragX) / (trackWidth - thumbWidth);
		dragged = true;
		if (percent >= 1) {
			endDrag();
		} else {
			updatePosition();
		}
	}

	private function endDrag(?event:Event):Void {
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateDrag);
		stage.removeEventListener(MouseEvent.MOUSE_UP, endDrag);
		stage.removeEventListener(Event.MOUSE_LEAVE, endDrag);
		if (percent >= 1) {
			percent = 1;
			updatePosition();
			hide();
		} else {
			collapseDrag();
		}
	}

	private function collapseDrag():Void {
		disableDrag();
		snapJob = to(0.25, {percent:0}, Quart.easeOut, endCollapseDrag);
		snapJob.onChange = updatePosition;
	}

	private function endCollapseDrag():Void {
		enableDrag();
		if (hinting) hideHint();
	}

	private function expandDrag():Void {
		disableDrag();
		snapJob = to(0.25, {percent:1}, Quart.easeOut, endExpandDrag);
		snapJob.onChange = updatePosition;
	}

	private function endExpandDrag():Void {
		enableDrag();
		if (hinting) hideHint();
		hide();
	}

	private function disableDrag():Void { mouseChildren = false; }
	private function enableDrag():Void { mouseChildren = true; }

	private function showHint(?event:Event):Void {
		if (hinting) return;
		hinting = true;
		if (hintCallback != null) hintCallback(this, hinting);
	}

	private function hideHint(?event:Event):Void {
		if (event != null && !mouseChildren) return;
		if (!hinting) return;
		hinting = false;
		if (hintCallback != null) hintCallback(this, hinting);
	}

	private function evaluateClick(?event:Event):Void {
		if (!dragged) {
			expandDrag();
		}
		dragged = false;
	}

	private function redraw():Void {
		// update sizes of things

		dragThumb.resize(thumbWidth, _height);
		dragTrack.height = _height;

		updatePosition(false);

	}

	private function updatePosition(?report:Bool = true):Void {
		// update x position of thumb
		dragTrack.width = dragThumb.x = percent * (trackWidth - thumbWidth);

		captionText.y = (_height - captionText.height) * 0.5;
		captionText.x = dragThumb.x - captionText.width - captionText.height;

		if (report) {
			if ((percent == 0 || lastPercent != percent) && dragCallback != null) dragCallback(this, percent);
			lastPercent == percent;
		}
	}
}
