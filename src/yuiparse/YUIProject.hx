package yuiparse;

import neko.FileSystem;
import neko.io.File;
import neko.io.FileOutput;

using Lambda;
using Reflect;
using StringTools;

class YUIProject {
	
	public var json:Dynamic;
	
	public var yuiClasses:Array<YUIClass>;
	public var version:String;
	
	public function new(_json:Dynamic, _yuiClasses:Array<YUIClass>, _version:String):Void {
		yuiClasses = [];
		version = _version;
		json = _json;
		
		var classlist:Array<String> = json.field("classlist");
		
		for (yuiClass in _yuiClasses) {
			if (classlist.has(yuiClass.json.field("name")) && yuiClass.json.field("innerClasses") == null) {
				yuiClasses.push(yuiClass);
			}
		}
	}
	
	public function export(directory:String, ?footer:String):Void {
		var name:String = json.field("name");
		var packageName:String = ~/[ -:]/g.replace(name.toLowerCase(), "_");
		var description:String = json.field("description");
		
		var header:String = ["/*", name, description, "v" + version, "*/", ""].join("\n\n");
		
		if (footer == null) footer = "exported with YUIDoc2haXeExtern";
		
		if (!directory.endsWith("/")) directory += "/";
		
		var dirname:String = directory + packageName;
		if(!FileSystem.exists(dirname)) neko.FileSystem.createDirectory(dirname);
		
		for (yuiClass in yuiClasses) {
			var path:String = directory + [packageName, yuiClass.json.name + ".hx"].join("/");
			var fout:FileOutput = File.write(path, false);
			fout.writeString(header + yuiClass.export(packageName, json.classlist) + "\n/* " + footer + " */\n");
			fout.close();
		}
	}
}