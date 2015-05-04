package net.rezmason.utils.display;

import net.rezmason.utils.workers.BasicWorker;
import net.rezmason.utils.display.SDFTypes;

class SDFWorker extends BasicWorker<Work, SerializedBitmap> {
    override function process(data:Work):Null<SerializedBitmap> return SDF.process(data);
}
