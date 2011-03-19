package net.rezmason.scourge.js;

import easeljs.Container;
import easeljs.Shape;

class Well extends Container {
	
	private var background:Shape;
	
	public var rotateHint:Bool->Bool->Void;
	public var rotatePiece:Bool->Void;
	public var biteHint:Bool->Void;
	public var toggleBite:Void->Void;
	public var swapHint:Bool->Void;
	public var swapPiece:Void->Void;
	
	public function new():Void {
		
		super();
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 0, 0, Layout.WELL_WIDTH, Layout.WELL_WIDTH, Layout.BAR_CORNER_RADIUS);
		GUIFactory.fillContainer(this, [background]);
	}
	
}