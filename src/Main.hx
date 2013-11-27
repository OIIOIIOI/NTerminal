package ;

import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import haxe.Timer;

/**
 * ...
 * @author 01101101
 */

class Main extends Sprite {
	
	var inited:Bool;
	
	public static function main () {
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
	
	public function new () {
		super();
		addEventListener(Event.ADDED_TO_STAGE, addedHandler);
	}
	
	function addedHandler (e:Event) {
		removeEventListener(Event.ADDED_TO_STAGE, addedHandler);
		stage.addEventListener(Event.RESIZE, resizeHandler);
		#if ios
		Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	function resizeHandler (e:Event) {
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init () {
		if (inited) return;
		inited = true;
		
		// Create and show the terminal
		var t:NTerminal = new NTerminal();
		addChild(t);
		
		// You can send commands directly from the source code
		t.send(NTerminal.CMD_HELP);
		// For example, to automatically start the plug with your app ID
		//t.send(NTerminal.CMD_START + " YOUR_APP_ID");
	}
	
}
