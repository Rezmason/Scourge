package yuiparse;

using Lambda;
using Reflect;

class YUIClass {
	
	public var dependenciesResolved:Bool;
	public var json:Dynamic<Dynamic>;
	public var inheritedProperties:Array<String>;
	public var inheritedMethods:Array<String>;
	public var inheritedEvents:Array<String>;
	
	private inline static var aLen:Int = "Array[".length;
	
	private var _classlist:Array<String>;
	private static var types:Hash<String>;
	
	public function new(_json:Dynamic<Dynamic>):Void {
		
		if (types == null) {
			types = new Hash<String>();
			types.set("Number", "Float");
			types.set("Boolean", "Bool");
			types.set("Array", "Array<Dynamic>");
			types.set("Function", "Dynamic");
			types.set("Object", "Dynamic");
			types.set("String", "String");
		}
		
		dependenciesResolved = true;
		
		var guess:String;
		json = _json;
		
		// clean up potential typos from documentation before we get going
		var bad:Bool;
		
		if (json.hasField("properties")) {
			var properties:Dynamic = json.field("properties");
			var badProperties:Array<String> = [];
			for (propertyID in properties.fields()) {
				var property:Dynamic = properties.field(propertyID);
				bad = false;
				guess = property.field("guessedname");
				bad = bad || (guess != null && guess.length > 0 && guess.indexOf("_") == -1 && propertyID != guess);
				if (bad) badProperties.push(propertyID);
			}
			for (propertyID in badProperties) {
				var property:Dynamic = properties.field(propertyID);
				properties.deleteField(propertyID);
				properties.setField(property.field("guessedname"), property);
			}
		}
		
		if (json.hasField("methods")) {
			var methods:Dynamic = json.field("methods");
			var badMethods:Array<String> = [];
			for (methodID in methods.fields()) {
				var method:Dynamic = methods.field(methodID);
				bad = false;
				bad = bad || (methodID.indexOf("\n") != -1);
				guess = method.field("guessedname");
				bad = bad || (guess != null && guess.length > 0 && guess.indexOf("_") == -1 && methodID != guess);
				if (bad) badMethods.push(methodID);
			}
			for (methodID in badMethods) {
				var method:Dynamic = methods.field(methodID);
				methods.deleteField(methodID);
				methods.setField(method.field("guessedname"), method);
			}
		}
		
		if (json.hasField("events")) {
			var events:Dynamic = json.field("events");
			var badEvents:Array<String> = [];
			for (eventID in events.fields()) {
				var event:Dynamic = events.field(eventID);
				bad = false;
				//bad = bad || (eventID.indexOf("\n") != -1);
				guess = event.field("guessedname");
				bad = bad || (guess != null && guess.length > 0 && guess.indexOf("_") == -1 && eventID != guess);
				if (bad) badEvents.push(event);
			}
		}
		
		if (!json.hasField("superclass")) {
			inheritedMethods = [];
			inheritedProperties = [];
			inheritedEvents = [];
			populateInheritedTraits();
		} else {
			dependenciesResolved = false;
		}
	}
	
	public function resolveDependencies(yuiClasses:Array<YUIClass>):Void {
		if (dependenciesResolved) return;
		for (yuiClass in yuiClasses) {
			if (json.field("superclass") == yuiClass.json.field("name")) {
				yuiClass.resolveDependencies(yuiClasses);
				if (json.hasField("properties")) for (inheritedProperty in yuiClass.inheritedProperties) json.field("properties").deleteField(inheritedProperty);
				if (json.hasField("methods")) for (inheritedMethod in yuiClass.inheritedMethods) json.field("methods").deleteField(inheritedMethod);
				if (json.hasField("events")) for (inheritedEvent in yuiClass.inheritedEvents) json.field("events").deleteField(inheritedEvent);
				
				inheritedProperties = yuiClass.inheritedProperties.copy();
				inheritedMethods = yuiClass.inheritedMethods.copy();
				inheritedEvents = yuiClass.inheritedEvents.copy();
				dependenciesResolved = true;
				populateInheritedTraits();
				break;
			}
		}
	}
	
	public function populateInheritedTraits():Void {
		if (json.hasField("properties")) inheritedProperties = inheritedProperties.concat(json.field("properties").fields());
		if (json.hasField("methods")) inheritedMethods = inheritedMethods.concat(json.field("methods").fields());
		if (json.hasField("events")) inheritedEvents = inheritedEvents.concat(json.field("events").fields());
	}
	
	public function export(packageName:String, classlist:Array<String>):String {
		var str:String = "package " + packageName + ";\n\n";
		_classlist = classlist;
		str += "extern class " + json.field("name");
		if (json.hasField("superclass")) str += " extends " + json.field("superclass");
		str += " {\n" + listConstructor() + listProperties() + listMethods() + listEvents() + "\n}\n";
		return str;
	}
	
	private function listProperties():String {
		if (!json.hasField("properties")) return "";
		var str:String;
		var listing:Array<String> = [];
		var properties:Dynamic = json.field("properties");
		for (propertyID in properties.fields()) {
			var property:Dynamic = properties.field(propertyID);
			var shortcut:Bool = property.hasField("description") && cast(property.field("description"), String).toLowerCase().indexOf("shortcut") != -1;
			if (!shortcut && (property.hasField("protected") || property.hasField("private"))) continue;
			str = "";
			if (json.hasField("methods") && json.field("methods").field(propertyID)) str += "//";
			if (property.hasField("static")) str += "static ";
			//if (property.hasField("description")) str += "/**\n" + property.field("description") + "\n**/\n";
			str += "var " + propertyID + ":" + translateType(property.field("type")) + ";";
			if (shortcut) str += " /* shortcut function */";
			str += "\n";
			listing.push(str);
		}
		listing.sort(alphabeticalSort);
		str = "\n" + "// PROPERTIES\n\n" + listing.join("");
		return ~/\n/g.replace(str, "\n\t");
	}
	
	private function listMethods():String {
		if (!json.hasField("methods")) return "";
		var str:String;
		var listing:Array<String> = [];
		var methods:Dynamic = json.field("methods");
		for (methodID in methods.fields()) {
			var method:Dynamic = methods.field(methodID);
			var shortcut:Bool = method.hasField("description") && cast(method.field("description"), String).toLowerCase().indexOf("shortcut") != -1;
			if (!shortcut && (method.hasField("protected") || method.hasField("private"))) continue;
			str = "";
			if (method.hasField("static")) str += "static ";
			//if (method.hasField("description")) str += "/**\n" + method.field("description") + "\n**/\n";
			str += "function " + methodID + "(" + listParams(method.field("params")) + "):" + translateReturnType(method.field("return")) + ";";
			if (shortcut) str += " /* shortcut function */";
			str += "\n";
			listing.push(str);
		}
		listing.sort(alphabeticalSort);
		str = "\n" + "// METHODS\n\n" + listing.join("");
		return ~/\n/g.replace(str, "\n\t");
	}
	
	private function listEvents():String {
		if (!json.hasField("events")) return "";
		var str:String;
		var listing:Array<String> = [];
		var events:Dynamic = json.field("events");
		for (eventID in events.fields()) {
			var event:Dynamic = events.field(eventID);
			str = "";
			if (json.hasField("methods") && json.field("methods").field(eventID)) str += "//";
			//if (event.hasField("description")) str += "/**\n" + event.description + "\n**/\n";
			str += "var " + eventID + ":" + listParams(event.field("params"), true) + "-> Dynamic;\n";
			listing.push(str);
		}
		listing.sort(alphabeticalSort);
		str = "\n" + "// EVENTS\n\n" + listing.join("");
		return ~/\n/g.replace(str, "\n\t");
	}
	
	private function listConstructor():String {
		if (!json.hasField("constructors")) return "";
		var str:String = "\n";
		var constructor:Dynamic = json.field("constructors")[0];
		if (constructor.hasField("description")) str += "/**\n" + constructor.field("description") + "\n**/\n";
		str += "\n" + "// CONSTRUCTOR\n\n";
		str += "function new(" + listParams(constructor.field("params")) + "):Void;\n";
		return ~/\n/g.replace(str, "\n\t");
	}
	
	private function listParams(params:Array<Dynamic>, ?asFuncDef:Bool = false):String {
		if (params == null) return "";
		var str:String = "";
		var paramStrings:Array<String> = [];
		for (param in params) {
			var paramName:String = param.field("name");
			var paramType:String = param.field("type");
			if (asFuncDef) {
				paramStrings.push(" " + translateType(paramType) + " /* " + paramName + " */ ");
			} else {
				var optional:Bool = false;
				var desc:String = param.field("description");
				if (desc != null) {
					desc = desc.toLowerCase();
					optional = optional || desc.indexOf("default val") != -1;
					optional = optional || desc.indexOf("default is") != -1;
					optional = optional || desc.indexOf("optional") != -1;
				}	
				paramStrings.push((optional ? "?" : "") + paramName + ":" + translateType(paramType));
			}
		}
		str += paramStrings.join(asFuncDef ? "->" : ", ");
		return str;
	}
	
	private function translateType(type:String):String {
		if (type == null || type.length == 0) return "Dynamic";
		if (type.indexOf("|") > -1) return "Dynamic /* " + type + " */";
		if (type.indexOf("Array[") == 0) {
			return "Array<" + translateType(type.substr(aLen, type.lastIndexOf("]") - aLen)) + ">";
		}
		if (types.get(type) != null) return types.get(type);
		if (_classlist.indexOf(type) == -1) return "Dynamic /* " + type + " */";
		return type;
	}
	
	private function translateReturnType(ret:Dynamic):String {
		return (ret != null) ? translateType(ret.type) : "Void";
	}
	
	private static function alphabeticalSort(x:String, y:String):Int {
        if (x < y) return -1;
        if (x > y) return 1;
        return 0;
	}
}