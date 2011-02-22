package net.rezmason.scourge;

import net.kawa.tween.easing.Elastic;
import net.kawa.tween.easing.Quad;

class Layout {
	
	public static var UNIT_SIZE:Int = 20;
	public static var WELL_WIDTH:Float = 210;
	public static var WELL_BORDER:Float = 10;
	public static var BAR_WIDTH:Float = 230;
	public static var BAR_MARGIN:Float = (BAR_WIDTH - WELL_WIDTH) / 2;
	public static var BAR_HEIGHT:Float = 600;
	public static var GRID_BORDER:Int = 10;
	public static var GRID_MARGIN:Int = 20;
	public static var BAR_CORNER_RADIUS:Int = 40;
	public static var TIMER_HEIGHT:Float = 40;
	public static var STAT_PANEL_HEIGHT:Float = Layout.BAR_HEIGHT - 4 * Layout.BAR_MARGIN - Layout.WELL_WIDTH - Layout.TIMER_HEIGHT;
	
	public static var QUICK:Float = 0.1;
	public static var POUNCE:Float -> Float = Quad.easeOut;
	public static var SLIDE:Float -> Float = Quad.easeInOut;
	public static var ZIGZAG:Float -> Float = Elastic.easeOut;
}