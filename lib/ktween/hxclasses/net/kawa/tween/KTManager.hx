package net.kawa.tween;

extern class KTManager {
	function new() : Void;
	function abort() : Void;
	function cancel() : Void;
	function complete() : Void;
	function pause() : Void;
	function queue(job : KTJob, ?delay : Float) : Void;
	function resume() : Void;
}
