package net.rezmason.scourge.js;

import easeljs.Container;
import easeljs.DisplayObject;
import easeljs.Shape;
import easeljs.Text;

import net.rezmason.scourge.Layout;
import net.rezmason.scourge.Player;

import net.kawa.tween.KTJob;
import net.kawa.tween.KTween;
import net.kawa.tween.easing.Quad;

class PlayerStat extends Container {
	
	//private static var DEAD_CT:ColorTransform = new ColorTransform(0.5, 0.5, 0.5);
	
	private var background:Shape;
	private var biteIcon1:Container;
	private var biteIcon2:Container;
	private var biteIcon3:Container;
	private var biteIcons:Container;
	private var txtName:Text;
	private var txtData:Text;
	//private var tint:ColorTransform;
	
	private var tintJob:KTJob;
	private var shiftJob:KTJob;
	private var alive:Bool;
	private var biteIcon:DisplayObject;
	
	public var uid:Int;
	
	public function new(_uid:Int, hgt:Float):Void {
		super();
	}
	
	
}