package net.kawa.tween;

extern class KTJob extends flash.events.EventDispatcher {
	var duration : Float;
	var ease : Dynamic;
	var finished : Bool;
	var from : Dynamic;
	var name : String;
	var next : KTJob;
	var onCancel : Dynamic;
	var onCancelParams : Array<Dynamic>;
	var onChange : Dynamic;
	var onChangeParams : Array<Dynamic>;
	var onClose : Dynamic;
	var onCloseParams : Array<Dynamic>;
	var onComplete : Dynamic;
	var onCompleteParams : Array<Dynamic>;
	var onInit : Dynamic;
	var onInitParams : Array<Dynamic>;
	var repeat : Bool;
	var round : Bool;
	var target : Dynamic;
	var to : Dynamic;
	var yoyo : Bool;
	function new(target : Dynamic) : Void;
	function abort() : Void;
	function cancel() : Void;
	function close() : Void;
	function complete() : Void;
	function init(?curTime : Float) : Void;
	function pause() : Void;
	function resume() : Void;
	function step(?curTime : Float) : Void;
	private function clearnup() : Void;
}
