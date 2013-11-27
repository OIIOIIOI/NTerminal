package ;

import com.nuggeta.network.Message;
import com.nuggeta.ngdl.nobjects.CreateGameResponse;
import com.nuggeta.ngdl.nobjects.CreateGameStatus;
import com.nuggeta.ngdl.nobjects.GetGamesResponse;
import com.nuggeta.ngdl.nobjects.GetGamesStatus;
import com.nuggeta.ngdl.nobjects.NGame;
import com.nuggeta.ngdl.nobjects.NuggetaQuery;
import com.nuggeta.ngdl.nobjects.SessionExpired;
import com.nuggeta.ngdl.nobjects.StartResponse;
import com.nuggeta.ngdl.nobjects.StartStatus;
import com.nuggeta.ngdl.nobjects.StopGameResponse;
import com.nuggeta.ngdl.nobjects.StopGameStatus;
import com.nuggeta.NuggetaPlug;
import com.nuggeta.util.NList;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.ui.Keyboard;

/**
 * ...
 * @author 01101101
 */

class NTerminal extends Sprite {
	// Available commands
	static inline public var CMD_HELP:String = "help";
	static inline public var CMD_START:String = "start";
	static inline public var CMD_GETGAMES:String = "getgames";
	static inline public var CMD_CREATEGAME:String = "creategame";
	static inline public var CMD_STOPGAME:String = "stopgame";
	static inline public var CMD_STOPALLGAMES:String = "stopallgames";
	// Log colors
	static inline public var COL_USER:String = "#FFFFFF";
	static inline public var COL_DEFAULT:String = "#457C9A";
	static inline public var COL_SUCCESS:String = "#93C763";
	static inline public var COL_WARN:String = "#FFCD22";
	static inline public var COL_ERROR:String = "#F85054";
	// Default messages
	static inline public var MSG_PARAM_NUMBER:String = "Invalid number of parameters";
	static inline public var MSG_NO_PARAM_REQ:String = "No parameter required";
	static inline public var MSG_NO_PLUG:String = "Use 'start [APP_ID]' to start the plug first";
	
	var background:Sprite;
	var textfield:TextField;
	var input:TextField;
	var history:Array<String>;
	var histIndex:Int;
	var action:String;
	
	public function new () {
		super();
		
		background = new Sprite();
		background.graphics.beginFill(0x2C4152);
		background.graphics.drawRect(0, 0, 300, 300);
		background.graphics.endFill();
		
		textfield = new TextField();
		textfield.defaultTextFormat = new TextFormat("Lucida Console", 12);
		textfield.width = textfield.height = 300;
		textfield.selectable = true;
		textfield.multiline = true;
		textfield.wordWrap = true;
		
		print("Terminal is ready", COL_SUCCESS);
		history = new Array<String>();
		histIndex = history.length;
		
		addEventListener(Event.ADDED_TO_STAGE, addedHandler);
	}
	
	private function addedHandler (e:Event) {
		removeEventListener(Event.ADDED_TO_STAGE, addedHandler);
		
		background.graphics.clear();
		background.graphics.beginFill(0x2C4152);
		background.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight - 30);
		background.graphics.endFill();
		background.graphics.beginFill(0x293134);
		background.graphics.drawRect(0, stage.stageHeight - 30, stage.stageWidth, 30);
		background.graphics.endFill();
		addChild(background);
		
		textfield.width = stage.stageWidth;
		textfield.height = stage.stageHeight - 30;
		addChild(textfield);
		
		input = new TextField();
		input.defaultTextFormat = new TextFormat("Lucida Console", 13, 0xFFFFFF);
		input.multiline = false;
		input.type = TextFieldType.INPUT;
		input.width = stage.stageWidth - 8;
		input.height = 20;
		input.x = 4;
		input.y = stage.stageHeight - 24;
		addChild(input);
		input.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		input.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		
		stage.focus = input;
	}
	
	private function keyDownHandler (e:KeyboardEvent) {
		// Send command
		if ((e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.NUMPAD_ENTER) && input.text != "") {
			send(input.text);
			input.text = "";
		}
		// Navigate through command history
		else if (e.keyCode == Keyboard.UP && histIndex > 0) {
			histIndex--;
			input.text = history[histIndex];
		}
		else if (e.keyCode == Keyboard.DOWN && histIndex < history.length) {
			histIndex++;
			if (histIndex < history.length)	input.text = history[histIndex];
			else							input.text = "";
		}
	}
	
	private function keyUpHandler (e:KeyboardEvent) {
		if (e.keyCode == Keyboard.UP || e.keyCode == Keyboard.DOWN) {
			// Put the caret back at the end
			input.setSelection(input.text.length, input.text.length);
		}
	}
	
	public function send (cmd:String) {
		if (cmd == "")	return;
		// Print user command
		print(cmd, COL_USER);
		// Add command to history if different from the last one
		if (cmd != history[history.length - 1])	history.push(cmd);
		histIndex = history.length;
		
		// Parse and execute command
		var array:Array<String> = cmd.split(" ");
		action = array.shift().toLowerCase();
		switch (action) {
			case CMD_HELP:
				print("Available commands: help, start, getGames, createGame, stopGame, stopAllGames");
			case CMD_START:
				cmdStart(array);
			case CMD_GETGAMES:
				cmdGetGames(array);
			case CMD_CREATEGAME:
				cmdCreateGame(array);
			case CMD_STOPGAME:
				cmdStopGame(array);
			case CMD_STOPALLGAMES:
				cmdStopAllGames(array);
			default:
				print("Unknown command", COL_WARN);
		}
	}
	
	public function print (s:String, c:String = COL_DEFAULT) {
		textfield.htmlText += "<font color='" + c + "'>" + s + "</font>";
		textfield.scrollV = textfield.maxScrollV;
	}
	
	// ------- COMMANDS -------
	
	var plug:NuggetaPlug;
	
	function cmdStart (params:Array<String>) {
		if (params.length != 1) {
			print(MSG_PARAM_NUMBER + ": start [APP_ID]", COL_WARN);
			return;
		}
		if (plug != null) {
			print("The plug has already been started", COL_WARN);
			return;
		}
		print("Creating plug with Game ID " + params[0]);
		plug = new NuggetaPlug("nuggeta://" + params[0]);
		print("Adding pump loop");
		addEventListener(Event.ENTER_FRAME, pump);
		print("Starting plug");
		plug.start();
	}
	
	function cmdGetGames (params:Array<String>) {
		if (plug == null) {
			print(MSG_NO_PLUG, COL_WARN);
			return;
		}
		if (params.length > 0) {
			print(MSG_NO_PARAM_REQ + ": getGames", COL_WARN);
			return;
		}
		print("Requesting games list");
		var q:NuggetaQuery = new NuggetaQuery();
		q.setStart(0);
		q.setLimit(10);
		plug.getGames(q);
	}
	
	function cmdCreateGame (params:Array<String>) {
		if (plug == null) {
			print(MSG_NO_PLUG, COL_WARN);
			return;
		}
		if (params.length > 0) {
			print(MSG_NO_PARAM_REQ + ": createGame", COL_WARN);
			return;
		}
		print("Creating new game");
		plug.createGame();
	}
	
	function cmdStopGame (params:Array<String>) {
		if (plug == null) {
			print(MSG_NO_PLUG, COL_WARN);
			return;
		}
		if (params.length != 1) {
			print(MSG_PARAM_NUMBER + ": stopGame [GAME_ID]", COL_WARN);
			return;
		}
		print("Stopping game " + params[0]);
		plug.stopGame(params[0]);
	}
	
	function cmdStopAllGames (params:Array<String>) {
		if (plug == null) {
			print(MSG_NO_PLUG, COL_WARN);
			return;
		}
		if (params.length > 0) {
			print(MSG_NO_PARAM_REQ + ": stopAllGames", COL_WARN);
			return;
		}
		cmdGetGames([]);
	}
	
	// ------- PUMP -------
	
	function pump (e:Event) {
		var messages:NList<Message> = plug.pump();
		for (i in 0...messages.size()) {
			var m:Message = messages.get(i);
			if (Std.is(m, StartResponse))			startResponseHandler(cast m);
			else if (Std.is(m, GetGamesResponse))	getGamesResponseHandler(cast m);
			else if (Std.is(m, CreateGameResponse))	createGameResponseHandler(cast m);
			else if (Std.is(m, StopGameResponse))	stopGameResponseHandler(cast m);
			else if (Std.is(m, SessionExpired))		sessionExpiredHandler(cast m);
			else									print("Unhandled message: " + m, COL_WARN);
		}
	}
	
	// ------- RESPONSE HANDLERS -------
	
	function startResponseHandler (sr:StartResponse) {
		// Read status
		var s:StartStatus = sr.getStartStatus();
		if (s == StartStatus.FAILED ||
			s == StartStatus.REFUSED) {
			print(s.toString(), COL_ERROR);
			print("Stopping pump loop");
			removeEventListener(Event.ENTER_FRAME, pump);
			print("Deleting plug");
			plug = null;
			return;
		}
		else if (s == StartStatus.READY) {
			print("Successfully started plug", COL_SUCCESS);
		}
		else if (s == StartStatus.WARNED) {
			print(s.toString(), COL_WARN);
		}
	}
	
	function getGamesResponseHandler (ggr:GetGamesResponse) {
		// Read status
		var s:GetGamesStatus = ggr.getGetGamesStatus();
		if (s == GetGamesStatus.INTERNAL_ERROR ||
			s == GetGamesStatus.INVALID_QUERY) {
			print(s.toString(), COL_ERROR);
			return;
		}
		else if (s == GetGamesStatus.SUCCESS) {
			var games:NList<NGame> = ggr.getGames();
			print("Found " + games.size() + " game(s)", COL_SUCCESS);
			for (i in 0...games.size()) {
				var g:NGame = games.get(i);
				// If getGames was called from another command (for example stopAllGames),
				// execute the corresponding action instead of printing the list
				switch (action) {
					case CMD_STOPALLGAMES:
						plug.stopGame(g.getId());
					default:
						print("[" + i + "] " + g.getPlayers().size() + " player(s) | " + g.getId());
				}
			}
		}
	}
	
	function createGameResponseHandler (cgr:CreateGameResponse) {
		// Read status
		var s:CreateGameStatus = cgr.getCreateGameStatus();
		if (s == CreateGameStatus.INTERNAL_ERROR ||
			s == CreateGameStatus.INVALID_CALL) {
			print(s.toString(), COL_ERROR);
			return;
		}
		else if (s == CreateGameStatus.SUCCESS) {
			print("Successfully created game " + cgr.getGameId(), COL_SUCCESS);
		}
	}
	
	function stopGameResponseHandler (sgr:StopGameResponse) {
		// Read status
		var s:StopGameStatus = sgr.getStopGameStatus();
		if (s == StopGameStatus.ALREADY_STOPPED ||
			s == StopGameStatus.INTERNAL_ERROR ||
			s == StopGameStatus.INVALID_CALL ||
			s == StopGameStatus.UNKNOWN_GAME) {
			print(s.toString(), COL_ERROR);
			return;
		}
		else if (s == StopGameStatus.STOPPED) {
			print("Successfully stopped game " + sgr.getGameId(), COL_SUCCESS);
		}
	}
	
	function sessionExpiredHandler (se:SessionExpired) {
		print("Session has expired", COL_ERROR);
		print("Stopping pump loop");
		removeEventListener(Event.ENTER_FRAME, pump);
		print("Deleting plug");
		plug = null;
	}
	
}










