package net.kawa.tween;

import haxe.Timer;

import net.kawa.tween.easing.Quad;

using Reflect;

typedef Ease = Float->Float;

/**
 * KTJob
 * Tween job calss for the KTween
 * @author Yusuke Kawasaki
 * @version 1.0.1
 */
class KTJob {
	/**
	 * Name of the tween job.
	 */
	public var name:String;
	/**
	 * The length of the tween in seconds.
	 */
	public var duration:Float;
	/**
	 * The target object to tween.
	 */
	public var target:Dynamic;
	/**
	 * The object which contains the first (beginning) status in each property.
	 * In case of null, the current propeties would be copied from the target object.
	 */
	public var from:Dynamic;
	/**
	 * The object which contains the last (ending) status in each property.
	 * In case of null, the current propeties would be copied from the target object.
	 */
	public var to:Dynamic;
	/**
	 * The easing equation function.
	 */
	public var ease:Float->Float;
	/**
	 * True after the job was finished including completed, canceled and aborted.
	 */
	public var finished:Bool;
	/**
	 * Set true to round the result value to the nearest integer number.
	 */
	public var round:Bool;
	/**
	 * Set true to repeat the tween from the beginning after finished.
	 */
	public var repeat:Bool;
	/**
	 * Set true to repeat the tween reverse back from the ending after finished.
	 * repeat property must be true.
	 */
	public var yoyo:Bool;
	/**
	 * The callback function invoked when the tween job has just started.<br/>
	 * Note this would not work with KTween's static methods,
	 * ex. <code>KTween.fromTo()</code>,
	 * as these methods start a job at the same time.
	 */
	public var onInit:Dynamic;
	/**
	 * The callback function invoked when the value chaned.
	 */
	public var onChange:Dynamic;
	/**
	 * The callback function invoked when the tween job has just completed.<br/>
	 * Note this would be invoked before the Flash Player renders the object
	 * at the final position.
	 */
	public var onComplete:Dynamic;
	/**
	 * The callback function invoked when the tween job is closing.<br/>
	 * Note this would be invoked at the next <code>ENTER_FRAME</code> event of onComplete.
	 */
	public var onClose:Dynamic;
	/**
	 * The callback function invoked when the tween job is canceled.
	 */
	public var onCancel:Dynamic;
	/**
	 * Arguments for onInit callback function.
	 */
	public var onInitParams:Array<Dynamic>;
	/**
	 * Arguments for onChange callback function.
	 */
	public var onChangeParams:Array<Dynamic>;
	/**
	 * Arguments for onComplete callback function.
	 */
	public var onCompleteParams:Array<Dynamic>;
	/**
	 * Arguments for onClose callback function.
	 */
	public var onCloseParams:Array<Dynamic>;
	/**
	 * Arguments for onCancel callback function.
	 */
	public var onCancelParams:Array<Dynamic>;
	/**
	 * The next tween job instance managed by KTManager. Do not modify this.
	 * @see net.kawa.tween.KTManager
	 */
	public var next:KTJob;
	private var reverse:Bool;
	private var initialized:Bool;
	private var canceled:Bool;
	private var pausing:Bool;
	private var startTime:Float;
	private var lastTime:Float;
	private var firstProp:_KTProperty;

	/**
	 * Constructs a new KTJob instance.
	 *
	 * @param target 	The object whose properties will be tweened.
	 **/
	public function new(_target:Dynamic):Void {

		duration = 1.0;
		ease = Quad.easeOut;
		finished = false;
		round = false;
		repeat = false;
		yoyo = false;
		reverse = false;
		initialized = false;
		canceled = false;
		pausing = false;

		target = _target;
	}

	/**
	 * Initializes from/to values of the tween job.
	 * @param curTime The current time in milliseconds given by getTimer() method. Optional.
	 * @see flash.utils#getTimer()
	 */
	public function init(curTime:Float = -1):Void {
		if (initialized) return;
		if (finished) return;
		if (canceled) return;
		if (pausing) return;

		// get current time
		if (curTime < 0) {
			curTime = Timer.stamp();
		}
		startTime = curTime;

		setupValues();
		initialized = true;

		// activated
		if (onInit.isFunction()) {
			onInit.apply(onInit, onInitParams);
		}
	}

	private function setupValues():Void {
		var first:Dynamic = (from != null) ? from : target;
		var last:Dynamic = (to != null) ? to : target;
		var keys:Array<String> = Reflect.fields(to != null ? to : from);
		if (keys == null || keys.length == 0) return;

		var p:_KTProperty;
		var lastProp:_KTProperty = null;
		for (key in keys) {
			var firstVal:Dynamic = first.field(key);
			var lastVal:Dynamic = last.field(key);
			if (firstVal == lastVal) continue; // skip this
			p = new _KTProperty(key, firstVal, lastVal);
			if (firstProp == null) {
				firstProp = p;
			} else {
				lastProp.next = p;
			}
			lastProp = p;
		}
		if (from != null) {
			applyFirstValues();
		}
	}

	private function applyFirstValues():Void {
		var p:_KTProperty = firstProp;
		while (p != null) {
			target.setField(p.key, p.from);
			p = p.next;
		}
		if (onChange.isFunction()) {
			onChange.apply(onChange, onChangeParams);
		}
	}

	private function applyFinalValues():Void {
		var p:_KTProperty = firstProp;
		while (p != null) {
			target.setField(p.key, p.to);
			p = p.next;
		}
		if (onChange.isFunction()) {
			onChange.apply(onChange, onChangeParams);
		}
	}

	/**
	 * Steps the sequence by every ticks invoked by ENTER_FRAME event.
	 * @param curTime The current time in milliseconds given by getTimer() method. Optional.
	 * @see flash.utils#getTimer()
	 */
	public function step(curTime:Float = -1):Void {
		if (finished) return;
		if (canceled) return;
		if (pausing) return;

		// get current time
		if (curTime < 0) {
			curTime = Timer.stamp();
		}

		// not started yet
		if (!initialized) {
			init(curTime);
			return;
		}

		// check invoked in the same time
		if (lastTime == curTime) return;
		lastTime = curTime;

		// check finished
		var secs:Float = (curTime - startTime);
		if (secs >= duration) {
			if (repeat) {
				if (yoyo) {
					reverse = !reverse;
				}
				secs -= duration;
				startTime = curTime - secs;
			} else {
				complete();
				return;
			}
		}

		// tweening
		var pos:Float = secs / duration;
		if (reverse) {
			pos = 1 - pos;
		}
		if (ease.isFunction()) {
			pos = ease(pos);
		}

		// update
		var p:_KTProperty = firstProp;
		if (round) {
			while (p != null) {
				target.setField(p.key, Math.round(p.from + p.diff * pos));
				p = p.next;
			}
		} else {
			while (p != null) {
				target.setField(p.key, p.from + p.diff * pos);
				p = p.next;
			}
		}
		if (onChange.isFunction()) {
			onChange.apply(onChange, onChangeParams);
		}
	}

	/**
	 * Forces to finish the tween job.
	 */
	public function complete():Void {
		if (!initialized) return;
		if (finished) return;
		if (canceled) return;
		// if (!to) return;
		if (!target) return;

		applyFinalValues();

		finished = true;
		if (onComplete.isFunction()) {
			onComplete.apply(onComplete, onCompleteParams);
		}
	}

	/**
	 * Stops and rollbacks to the first (beginning) status of the tween job.
	 */
	public function cancel():Void {
		if (!initialized) return;
		if (canceled) return;
		// if (!from) return;
		if (!target) return;

		applyFirstValues();

		finished = true;
		canceled = true;
		if (onCancel.isFunction()) {
			onCancel.apply(onCancel, onCancelParams);
		}
	}

	/**
	 * Closes the tween job
	 */
	public function close():Void {
		if (!initialized) return;
		if (canceled) return;

		finished = true;
		if (onClose.isFunction()) {
			onClose.apply(onClose, onCloseParams);
		}
		clearnup();
	}

	/**
	 * @private
	 */
	private function clearnup():Void {
		onInit = null;
		onChange = null;
		onComplete = null;
		onCancel = null;
		onClose = null;
		onInitParams = null;
		onChangeParams = null;
		onCompleteParams = null;
		onCloseParams = null;
		onCancelParams = null;
		firstProp = null;
	}

	/**
	 * Terminates the tween job immediately.
	 */
	public function abort():Void {
		finished = true;
		canceled = true;
		clearnup();
	}

	/**
	 * Pauses the tween job.
	 */
	public function pause():Void {
		if (pausing) return;
		pausing = true;
		lastTime = Timer.stamp();
	}

	/**
	 * Proceeds with the tween jobs paused.
	 */
	public function resume():Void {
		if (!pausing) return;
		pausing = false;
		var curTime:Float = Timer.stamp();
		startTime = curTime - (lastTime - startTime);
		step(curTime);
	}
}


class _KTProperty {
	public var key:String;
	public var from:Float;
	public var to:Float;
	public var diff:Float;
	public var next:_KTProperty;

	public function new(_key:String, _from:Float, _to:Float, ?_next:_KTProperty):Void {
		key = _key;
		from = _from;
		to = _to;
		diff = _to - _from;
		next = _next;
	}
}
