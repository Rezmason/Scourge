package net.kawa.tween;

extern class KTween {
	static var jobClass : Class<Dynamic>;
	static function abort() : Void;
	static function cancel() : Void;
	static function complete() : Void;
	static function from(target : Dynamic, duration : Float, from : Dynamic, ?ease : Dynamic, ?_callback : Dynamic) : KTJob;
	static function fromTo(target : Dynamic, duration : Float, from : Dynamic, to : Dynamic, ?ease : Dynamic, ?_callback : Dynamic) : KTJob;
	static function pause() : Void;
	static function queue(job : KTJob, ?delay : Float) : Void;
	static function resume() : Void;
	static function to(target : Dynamic, duration : Float, to : Dynamic, ?ease : Dynamic, ?_callback : Dynamic) : KTJob;
}
