package yuiparse;

import haxe.Http;
import neko.FileSystem;
import neko.Lib;
import neko.Sys;
import neko.io.File;

import hxjson2.JSON;

import yuiparse.YUIProject;
import yuiparse.YUIClass;

using Lambda;
using Reflect;

class YUIDoc2haXeExtern {
	
	public static inline var argKeys = ["-source", "-dest", "-footer", "-verbose"];
	
	private var loader:Http;
	private var source:String; // target JSON
	private var dest:String; // target directory
	private var footer:String; // String to go at the bottom of the externs
	private var verbose:String; // Whether or not to shout progress
	private var isVerbose:Bool;
	
	private var sysargs:Array<String>;
	
	private var yuiProjects:Array<YUIProject>;
	private var yuiClasses:Array<YUIClass>;
	
	
	public static function main():Void {
		new YUIDoc2haXeExtern();
	}
	
	public function new():Void {
		
		var args:Array<String> = Sys.args();
		var ike:Int = 0;
		while (ike < args.length) {
			if (argKeys.has(args[ike])) setField(args[ike].substr(1), args[ike + 1]);
			ike += 2;
		}
		
		isVerbose = (verbose == "true" || verbose == "1");
		
		// Check to see if argument is missing
		if (source == null) {
			Lib.println("Missing argument '-source'");
			return;
		}
		
		if (dest == null) dest = Sys.getCwd();
		
		if (source.indexOf("://") != -1) {
			// source is a URL
			loader = new Http(source);
			loader.onData = processJSON;
			loader.onError = processError;
			if (isVerbose) Lib.println("Loading " + source + " ...");
			loader.request(false);
		} else {
			// source is a local file
		    try {
				if (isVerbose) Lib.println("Reading " + source + " ...");
				processJSON(File.getContent(source));
			} catch( message : String ) {
				processError(message);
			}
		}
	}
	
	private function processJSON(data:String):Void {
		
		var json:Dynamic;
		yuiProjects = [];
		yuiClasses = [];
		
		try {
			if (isVerbose) Lib.println("Decoding JSON ...");
			json = JSON.decode(data, true);
		} catch( message : String ) {
		    Lib.println("Could not parse the JSON file: " + message);
			return;
		}
		
		if (isVerbose) Lib.println("Translating YUIDoc objects into haXe externs ...");
		
		var classes:Dynamic = json.field("classmap");
		var modules:Dynamic = json.field("modules");
		
		for (className in classes.fields()) yuiClasses.push(new YUIClass(classes.field(className)));
		for (yuiClass in yuiClasses) yuiClass.resolveDependencies(yuiClasses);
		for (moduleName in modules.fields()) yuiProjects.push(new YUIProject(modules.field(moduleName), yuiClasses, json.field("version")));
		
		if (isVerbose) {
			var str:String = yuiProjects.length + " projects found:\n";
			for (yuiProject in yuiProjects) {
				str += "\t" + yuiProject.json.field("name") + " contains " + yuiProject.yuiClasses.length + " classes:\n";
				for (yuiClass in yuiProject.yuiClasses) str += "\t\t" + yuiClass.json.field("name") + "\n";
			}
			Lib.print(str);
		}
		
		// check if dest exists
		if (!FileSystem.exists(dest)) FileSystem.createDirectory(dest);
		
		if (isVerbose) Lib.println("Writing externs projects to " + dest + " ...");
		for (yuiProject in yuiProjects) yuiProject.export(dest, footer);
	}
	
	private function processError(message:String):Void {
		Lib.println("Could not load the JSON file: " + message);
	}
}