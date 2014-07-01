package net.kawa.tween;

import haxe.Timer;

/**
 * Tween job manager class
 * @author Yusuke Kawasaki
 * @version 1.0.1
 * @see net.kawa.tween.KTJob
 */
class KTManager {
	private var pulse:Timer;
	private var running:Bool;
	private var firstJob:KTJob;
	private var lastJob:KTJob;
	private var firstAdded:KTJob;
	private var lastAdded:KTJob;
	private var ms:Int;

	/**
	 * Constructs a new KTManager instance.
	 **/
	public function new(?framerate:Float = 60):Void {	
		running = false;
		ms = Std.int(1000 / framerate);
	}

	/**
	 * Regists a new tween job to the job queue.
	 *
	 * @param job 		A job to be added to queue.
	 * @param delay 	Delay until job started in seconds.
	 **/
	public function queue(job:KTJob, delay:Float = 0):Void {
		if (delay > 0) {
			var that:KTManager = this;
			var closure:Void -> Void = function ():Void {				
				that.queue(job);		
			};
			Timer.delay(closure, Std.int(delay * 1000));
			return;
		}
		job.init();
		if (lastAdded != null) {
			lastAdded.next = job;
		} else {
			firstAdded = job;
		}
		lastAdded = job;

		if (!running) awake();
	}

	private function awake():Void {
		if (running) return;
		pulse = new Timer(ms);
		pulse.run = tick;
		running = true;
	}

	private function sleep():Void {
		pulse.stop();
		running = false;
	}

	private function tick():Void {
		// check new jobs added
		if (firstAdded != null) {
			mergeList();
		}
		
		// check all jobs done
		if (firstJob == null) {
			sleep();
			return;
		}
		
		var curTime:Float = Timer.stamp();
		var prev:KTJob = null;
		var job:KTJob = firstJob;
		while (job != null) {
			if (job.finished) {
				if (prev == null) {
					firstJob = job.next;
				} else {
					prev.next = job.next;
				}
				if (job.next == null) {
					lastJob = prev;
				}
				job.close();
			} else {
				job.step(curTime);
				prev = job;
			}
			
			job = job.next;
		}
	}

	/**
	 * Terminates all tween jobs immediately.
	 * @see net.kawa.tween.KTJob#abort()
	 */
	public function abort():Void {
		mergeList();
		var job:KTJob = firstJob;
		while (job != null) {
			job.abort();
			job = job.next;
		}
	}

	/**
	 * Stops and rollbacks to the first (beginning) status of all tween jobs.
	 * @see net.kawa.tween.KTJob#cancel()
	 */
	public function cancel():Void {
		mergeList();
		var job:KTJob;
		var job:KTJob = firstJob;
		while (job != null) {
			job.cancel();
			job = job.next;
		}
	}

	/**
	 * Forces to finish all tween jobs.
	 * @see net.kawa.tween.KTJob#complete()
	 */
	public function complete():Void {
		mergeList();
		var job:KTJob = firstJob;
		while (job != null) {
			job.complete();
			job = job.next;
		}
	}

	/**
	 * Pauses all tween jobs.
	 * @see net.kawa.tween.KTJob#pause()
	 */
	public function pause():Void {
		mergeList();
		var job:KTJob = firstJob;
		while (job != null) {
			job.pause();
			job = job.next;
		}
	}

	/**
	 * Proceeds with all tween jobs paused.
	 * @see net.kawa.tween.KTJob#resume()
	 */
	public function resume():Void {
		// mergeList(); // this isn't needed
		var job:KTJob = firstJob;
		while (job != null) {
			job.resume();
			job = job.next;
		}
	}

	private function mergeList():Void {
		if (firstAdded == null) return;
		if (lastJob != null) {
			lastJob.next = firstAdded;	
		} else {
			firstJob = firstAdded;
		}
		lastJob = lastAdded;
		firstAdded = null;
		lastAdded = null;
	}
}
