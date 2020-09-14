package as3.game {
	
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import as3.vk.*;
	import as3.vk.events.*;
	import as3.crypto.*;
	import as3.tolmasoft.*;
	import as3.greensock.*;
	import as3.greensock.easing.*;
	
	public class Preloader extends MovieClip {
		private var version:String = "2.3.272";
		private var preloader:prd = new prd();
		private var bg_mc:nmv = new nmv();
		private var ifc_mc:nmv = new nmv();
		private var upp_mc:nmv = new nmv();
		private var learn_mc:nmv = new nmv();
		private var error_mc:nmv = new nmv();
		public var flashVars:Object;
		public var VK:APIConnection;
		public var TS:Server;
		private var i:Number;
		private var gameSize:Number;
		private var loader:Loader = new Loader();
		private var loadBytes:Number = 0;
		private var totalBytes:Number = 0;
		private var loadPieces:Number = 0;
		private var loaderContext:LoaderContext = new LoaderContext();
		public var windowArr:Array = new Array();
		private var uinfo:Object;
		private var sl:Boolean = false;
		private var fps:FPS = new FPS();
		private var console:Console = new Console();
		public var time:MyTime;
		private var percs:Array = new Array(0);
		private var percs1:Array = new Array(0, 0);
		private var errArr:Array = new Array('Что-то тут не так...', 'Опаньки...', 'Ошибка', 'Не торопись');
		private var strFriends:String = '';
		private var cc:Boolean = false;
		private var correctTimer:uint;
		private var mybg:bgg = new bgg();
				
		public function Preloader() {
			this.addEventListener(Event.ADDED_TO_STAGE, init);
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");	
			
			preloader.bar_mc.color_mc.scaleX = 0;
		}
		public function init(e:Event) {
			addChild(mybg);
			addChild(preloader);
			addChild(bg_mc);
			addChild(ifc_mc);
			addChild(upp_mc);
			addChild(learn_mc);
			addChild(error_mc);
			addChild(fps);
			addChild(console);
						
			fps.y = 30;
			mybg.x = -1540; mybg.y = -715;
			
			newContext();
			startLoad();
			maskers();
			
			Udata.pre = this;
			Udata.bg_mc = bg_mc;
			Udata.up_mc = upp_mc;
			Udata.onError = onErrorTS;
						
			fps.visible = false;
			console.visible = false;
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, actionFPS);
			this.addEventListener(Event.ENTER_FRAME, right_control);
		}
		
		private function maskers(){
			var arr:Array = new Array(new MovieClip(), new MovieClip(), new MovieClip(), new MovieClip());
			for(var j=0; j < arr.length; j++){
				arr[j].graphics.beginFill(0x000000);
				arr[j].graphics.drawRect(0,0,760,730);
				arr[j].graphics.endFill();
				addChild(arr[j]);
			}
			bg_mc.mask = arr[0];
			upp_mc.mask = arr[1];
			ifc_mc.mask = arr[2];
			learn_mc.mask = arr[3];
		}
		
		private function actionFPS(e:KeyboardEvent):void{
			if(e.keyCode == 67 && e.shiftKey)console.visible = !console.visible;
			if(e.keyCode == 70 && e.shiftKey && flashVars['viewer_id'] == 112354918)fps.visible = !fps.visible;
			if(e.keyCode == 80 && e.shiftKey && cc)Udata.prtscr.startScreen(this.stage);
			if(e.keyCode == 77 && e.shiftKey && cc)Udata.iface.music();
			
			if(e.keyCode !== 80 || e.shiftKey)return;
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			stage.scaleMode = StageScaleMode.NO_SCALE;
		}
		
		private function startLoad(){
			flashVars = stage.loaderInfo.parameters as Object;
			loaderContext.checkPolicyFile = true;

			if (!flashVars.api_id) { 
				flashVars['api_id'] = 5771566; 
				flashVars['viewer_id'] = 112354918;
				flashVars['sid'] = "009fa472413ca5cd755663b7aa1c46da52bd98ddab650a1a9aa9bd8bd3a5be0e74adf4b28699c0171ca18"; 
				flashVars['secret'] = "dbe377f607"; 
				flashVars['auth_key'] = "1f0a1d4f28e487c0e7d3c2e38c2e7ef9"; 
				flashVars['referrer'] = "ad_kek"; 
				flashVars['api_result'] = '{"response":[94382944,124279635,126310066,142460777,157286035,164393868,174530461,219142020,239514008,313721683,324820464,346061152,372843846,376276943]}';
				flashVars['user_id'] = 0; 
			}else{
				loaderContext.securityDomain = SecurityDomain.currentDomain;
			}
			
			if(int(flashVars['api_id']) !== 7594030 && new Array(112354918,219142020,182129043).indexOf(int(flashVars['viewer_id'])) == -1)return;
						
			VK = new APIConnection();
			TS = new Server([flashVars['api_id'], flashVars['viewer_id'], flashVars['auth_key'], 'http://c72188.hostru11.fornex.host/xuli/']);
			
			Udata.TS = TS;
			Udata.VK = VK;
			
			addChild(TS);
			
			if(VK.eiConnectStatus == "WORKING"){
				firstAPI();
			}else{
				VK.addEventListener(CustomEvent.ON_EI_INIT_END, firstAPI);
			}
			
		}
		
		private function firstAPI(e = null){
			VK.api('utils.getServerTime', {}, onGT, onErrorVK);
		}
		
		private function tick(){
			VK.api('utils.getServerTime', {}, onG, onErrorVK);
		}
		private function onGT(data:Object):void{
			time = new MyTime(Number(data)+1);
			TS.php('getToken', {at:flashVars['access_token']}, onToken, onErrorTS);
			correctTimer = setInterval(tick, 200000);
		}
		private function onG(data:Object):void{
			MyTime.sTimer -= (Number(data)-MyTime.time)*1000;
		}
		
		private function onToken(data:Object):void{
			TS.token = data['token'];
			TS.php("getLinks", {}, onLinks, onErrorTS);
		}
		
		private function onLinks(data:Object):void{
			Udata.links = data;
			totalBytes = 0;
			for(i = 0; i < Udata.links.length; i++)totalBytes+=Number(Udata.links[i]['size']);
			loader.load(new URLRequest(Udata.links[loadPieces]['link']+'?'+MD5.hash(version)), loaderContext);
			loadPieces++;
						
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadPart);
			TS.php("getUI", {uid:flashVars['user_id'], ads:flashVars["referrer"].split('ad_')[1]}, onGetUI, onErrorTS);
			TS.php("getGT", {}, onGetGT, onErrorTS);
			JSON.parse(flashVars['api_result'])['response'].join (",").length > 0?TS.php("getFT", {users:flashVars['viewer_id']+","+String(JSON.parse(flashVars['api_result'])['response'].join (","))}, onGetFT, onErrorTS):TS.php("getFT", {users:flashVars['viewer_id']}, onGetFT, onErrorTS);
			TS.php("getLT", {}, onGetLT, onErrorTS);
			TS.php("getLcsI", {}, onGetLcsI, onErrorTS);
			TS.php("getW", {}, onGetW, onErrorTS);
			TS.php("getWrs", {}, onWrs, onErrorTS);
			TS.php("getBon", {}, onBon, onErrorTS);
			TS.php("getDon", {}, onDon, onErrorTS);
			TS.php("getWeap", {}, onGetWeap, onErrorTS);
			TS.php("getBS", {}, onGetBS, onErrorTS);
			TS.php("getML", {}, onGetML, onErrorTS);
			TS.php("getAch", {}, onGetAch, onErrorTS);
			TS.php("getMandat", {}, onGetMan, onErrorTS);
			TS.php("getTop20", {}, onGetTop20, onErrorTS);
			TS.php("getToys", {}, onToys, onErrorTS);
			
			sl = true;
		}
		
		private function onLoadPart(e:Event):void{
			PartDispatcher.push(loadPieces-1, MovieClip(loader.content));
			if(loadPieces < Udata.links.length){
				loader.load(new URLRequest(Udata.links[loadPieces]['link']), loaderContext);
				loadPieces++;
			}else{
				sl = false;
			}
		}
		
		public function progressCache(partion:Number, percent:Number){
			var prc:int = 0;
			percs[partion] = percent;
			for(var m:int = 0; m < percs.length; m++)prc += percs[m];
			prc /= percs.length;
			
			lPercent(1, prc);
			
			if(prc == 100)cc = true;
		}
		
		private function lPercent(partion:Number, percent:Number){
			var prc:int = 0;
			percs1[partion] = percent;
			for(var m:int = 0; m < percs1.length; m++)prc += percs1[m];
			prc /= percs1.length;
			
			preloader.tf_txt.text = prc+"%";
			preloader.bar_mc.color_mc.scaleX = prc/100;
		}
				
		private function onGetUI(data:Object):void{
			Udata.udata = data;
		}
		private function onGetGT(data:Object):void{
			Udata.top['top'] = data;
		}
				
		private function onGetFT(data:Object):void{
			var arr:Array = new Array();
			for(i = 0; i < data.length; i++)arr.push(data[i]['id']);
			
			Udata.top['friends'] = data;
			VK.api("users.get", {fields:"photo_50", user_ids:String(arr.join (","))}, onPH, onErrorVK);
		}
		
		private function onPH(data:Object):void{
			for(i = 0; i < data.length; i++)Udata.top['friends'][i]['photo'] = data[i]['photo_50'];  
		}
		
		private function onGetLT(data:Object):void{
			Udata.levels = data;
		}
		
		private function onGetLcsI(data:Object):void{
			Udata.locs = data;
		}
		
		private function onGetW(data:Object):void{
			Udata.works = data;
		}
		
		private function onGetML(data:Object):void{
			Udata.mlevels = data;
		}
		
		private function onGetBS(data:Object):void{
			Udata.bosses = data;
		}
		
		private function onGetWeap(data:Object):void{
			Udata.weapons = data;
		}
		
		private function onDon(data:Object):void{
			Udata.donat = data;
		}
		
		private function onBon(data:Object):void{
			Udata.bonuses = data;
		}
		
		private function onWrs(data:Object):void{
			Udata.wears = data;
		}
		
		private function onGetAch(data:Object):void{
			Udata.achives = data;
		}
		
		private function onGetMan(data:Object):void{
			Udata.mandats = data;
		}
		private function onGetTop20(data:Object):void{
			Udata.top20 = data;
		}
		private function onToys(data:Object):void{
			Udata.toys = data;
		}
		
		private function right_control(e:Event = null):void{
			if(!sl){
				if(cc){
					bg_mc.addChild(Udata.menu);
					ifc_mc.addChild(Udata.iface);
					learn_mc.addChild(Udata.learn);
					
					Udata.iface.Start();
					Udata.menu.Start();
					Udata.learn.Start();
			
					if(preloader.stage)preloader.parent.removeChild(preloader);
					this.removeEventListener(Event.ENTER_FRAME, right_control);
					
					TS.loading(new smk());
					return;
				}
				return;
			}
			loadBytes = 0;
			for(i = 0; i < loadPieces-1; i++)loadBytes += Number(Udata.links[i]['size']);
			loadBytes += loader.contentLoaderInfo.bytesLoaded;
			if((loadBytes/totalBytes) <= 1)lPercent(0, int((loadBytes/totalBytes)*100));
		}
		
		private function newContext(){
			stage.showDefaultContextMenu = false;
			var newContextMenu:ContextMenu = new ContextMenu();
			newContextMenu.hideBuiltInItems(); //Прячем лишнее
 	
			var itemNova:ContextMenuItem = new ContextMenuItem('Русская Мафия. v.'+version);
			var itemTS:ContextMenuItem = new ContextMenuItem('Nikolas Game ©');
 	
			itemTS.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,onTS);
 	
			newContextMenu.customItems.push(itemNova, itemTS);
			contextMenu = newContextMenu;
		}
		
		private function onTS(e:ContextMenuEvent = null):void{
			navigateToURL(new URLRequest("https://vk.com/Id00030"), "_blank");
		}
		
		private function onErrorVK(data:Object):void{
			newError();
			windowArr[windowArr.length-1].win.info_txt.text = "Ошибка серверов ВКонтакте. Код ошибки: "+int(data['error_code'])+". Обратитесь к администрации приложения для решения проблемы.";
		}
		public function onErrorTS(data:Object):void{
			newError();
			windowArr[windowArr.length-1].win.info_txt.text = Base64.decode(data['text']);
		}
		
		public function newError(){
			windowArr.push(new resw());
			windowArr[windowArr.length-1].win.title_txt.text = errArr[int(Math.random()*errArr.length)];
			windowArr[windowArr.length-1].win.x = -100;
			TweenLite.to(windowArr[windowArr.length-1].win, 0.3, {x:232});
			if(!windowArr[windowArr.length-1].stage)error_mc.addChild(windowArr[windowArr.length-1]);
			windowArr[windowArr.length-1].win.button_mc.addEventListener(MouseEvent.CLICK, endError);
		}
		
		private function endError(e:MouseEvent):void{
			var index:Number = windowArr.indexOf(e.currentTarget.parent.parent);
			TweenLite.to(windowArr[index].win, 0.3, {x:810, onComplete:f});
			
			windowArr[index].win.button_mc.removeEventListener(MouseEvent.CLICK, endError);
			
			function f(){
				if(windowArr[index].stage)windowArr[index].parent.removeChild(windowArr[index]);
				windowArr.splice(index, 1);
			}
		}

	}}
