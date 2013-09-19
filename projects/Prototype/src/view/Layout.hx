package view;

import net.kawa.tween.easing.Elastic;
import net.kawa.tween.easing.Quad;

class Layout {

	public static var UNIT_REZ:Float = 10;

	public static var WELL_WIDTH:Float = 180;
	public static var WELL_BORDER:Float = 10;
	public static var BAR_MARGIN:Float = 10;
	public static var BAR_WIDTH:Float = WELL_WIDTH + BAR_MARGIN;
	public static var BAR_HEIGHT:Float = 600;
	public static var BAR_CORNER_RADIUS:Float = 40;

	public static var GRID_BORDER:Float = 0.6;
	public static var TIMER_PANEL_HEIGHT:Float = 40;
	public static var STAT_PANEL_HEIGHT:Float = Layout.BAR_HEIGHT - 4 * Layout.BAR_MARGIN - Layout.WELL_WIDTH - Layout.TIMER_PANEL_HEIGHT;
	public static var PIECE_SCALE:Float = WELL_WIDTH * 0.18 / UNIT_REZ;
	public static var PIECE_BLOCK_BORDER:Float = 0.05;

	public static var QUICK:Float = 0.1; // 0.1
	public static var GRID_SNAP_RATE:Float = 0.25; // 0.25
	public static var POUNCE:Float -> Float = Quad.easeOut;
	public static var SLIDE:Float -> Float = Quad.easeInOut;
	public static var ZIGZAG:Float -> Float = Elastic.easeOut;

	public static var FADE_BITMAP_REZ:Int = Std.int(40 * UNIT_REZ);
	public static var BODY_PADDING:Float = 0.3;
}
