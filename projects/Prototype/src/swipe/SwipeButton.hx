package swipe;

import flash.display.Sprite;
import flash.display.Shape;
import flash.display.DisplayObject;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

using utils.display.FastDraw;

class SwipeButton extends SwipeBox {

	private static var BRIGHT_CT:ColorTransform = new ColorTransform(1.1, 1.1, 1.1);
	private static var PLAIN_CT:ColorTransform = new ColorTransform();
	private static var CAPTION_FORMAT:TextFormat = new TextFormat("_sans", 40, 0x444444, true, null, null, null, null, TextFormatAlign.CENTER);

	private var background:Shape;
	public var clickCallback(default, null):Void->Void;
	public var content(default, set):ContentType;
	private var contentDO:DisplayObject;
	private var container:Sprite;

	public function new(__contentType:ContentType, ?__clickCallback:Void->Void):Void {
		super();
		background = new Shape();
		addChild(background);
		container = new Sprite();
		addChild(container);
		content = __contentType;
		clickCallback = __clickCallback;
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.ROLL_OVER, brighten);
		addEventListener(MouseEvent.ROLL_OUT,  darken);
		mouseChildren = false;
	}

	override public function resize(w:Float, h:Float):Void {
		var margin:Float = Layout.SWIPE_OVERLAP;
		background.clear().drawBox(0xCCCCCC, 1.0, 0, 0, w, h).drawBox(0xAAAAAA, 1.0, margin, margin, w - margin * 2, h - margin * 2);

		adjustContainer();
	}

	override private function get_box():Rectangle {
		return new Rectangle(x, y, background.width, background.height);
	}

	override private function set_box(value:Rectangle):Rectangle {
		x = value.x;
		y = value.y;
		resize(value.width, value.height);
		return value;
	}

	private function brighten(event:Event):Void {
		background.transform.colorTransform = BRIGHT_CT;
	}

	private function darken(event:Event):Void {
		background.transform.colorTransform = PLAIN_CT;
	}

	private function set_content(val:ContentType):ContentType {
		if (container.numChildren > 0) container.removeChildAt(0);

		if (val == null) {
			content = null;
			return null;
		}

		switch (val) {
			case CAPTION(text):
				contentDO = text.toTextField(CAPTION_FORMAT);
			case ICON(dobj):
				contentDO = dobj;
		}

		if (contentDO != null) container.addChild(contentDO);

		adjustContainer();

		content = val;
		return content;
	}

	private function onClick(event:Event):Void {
		if (clickCallback != null) clickCallback();
	}

	private function adjustContainer():Void {
		removeChild(container);
		var bounds:Rectangle = getBounds(this);
		var containerBounds:Rectangle = container.getBounds(container);
		container.x = (bounds.left + bounds.right  - containerBounds.left - containerBounds.right ) * 0.5;
		container.y = (bounds.top  + bounds.bottom - containerBounds.top  - containerBounds.bottom) * 0.5;
		addChild(container);
	}
}
