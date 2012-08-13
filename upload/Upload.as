package  {	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import flash.events.*;
	
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.FileFilter;	
	
	import flash.utils.ByteArray;
	
	import flash.system.Security;
	
	import FileItem;
	import FlashCaller;
	import UploadNextEvent;
	
	public class Upload extends MovieClip{
		private var _settings = {
			'thumbnailWidth': 1000,					//缩略图宽度
			'thumbnailHeight' : 1000,				//缩略图高度
			'thumbnailQuality' : 80,				//压缩品质 1~100
			'movieName' : 'fdx_upload',				//js传进来的初始化对象名
			'fileType' : '*.jpg;*.gif;*.png',		//默认文件类型
			'allowFileSize' : 6*1024*1024,			//允许上传的最大文件大小,默认6M
			'noCompressUnderSize' : 1*1024*1024,	//当文件大小小于这个值时也不会压缩尺寸，默认300k
			'allowFileNum' : 6,						//本次会话允许上传的最大数量
			'fileName' : 'imagefile',				//上传图片时的字段名
			'uploadUrl' : 'http://www.fan.com/show/ajax/upload.fan',//上传路径
			'extraParam' : null						//上传
		};
		private var _fileFilterArr:Array;		
		private var _fileBrowserMany:FileReferenceList = new FileReferenceList();
		
		/*统计不同状态的文件数*/
		private var _waittingFiles:Array = new Array();
		private var _uploadingFiles:Array = new Array();
		private var _uploadedFiles:Array = new Array();
		private var _failedFiles:Array = new Array();
		private var _currentFile:FileItem;
		
		private var button:Sprite;
		private var jsCaller:JsCaller;
		private var flashCaller:FlashCaller;
		//用于事件中调用
		private var _self:Upload;
		
		public function Upload() {
			Security.allowDomain("*");	// Allow uploading to any domain
			Security.allowInsecureDomain("*");	// Allow uploading from HTTP to HTTPS and HTTPS to HTTP
			
			_self = this;
			_self.initSettings(root.loaderInfo.parameters);
			_self._initStage();
			
			_self.jsCaller = new JsCaller(_self._settings.movieName);
			_self.flashCaller = new FlashCaller(_self._settings.movieName,_self);
			_self.flashCaller.registerCallback();
		}
		public function getSettings():Object{
			return _self._settings;
		}
		/*取消上传*/
		public function cancelUpload(fileName:String){
			var _waitingFiles = _self._waittingFiles;
			for(var i = 0;i<_waitingFiles;i++){
				var _f = _waitingFiles[i];
				if(fileName == null || fileName == _f.getFileName()){
					_f.cancelUpload();
					_waitingFiles.splice(i,1);
					i--;
				}
			}
			//通知取消成功
			_self.jsCaller.uploadCancelSuccess(fileName);
		}
		/*初始化配置	*/
		public function initSettings(args:Object){
			var settings = _self.getSettings();
			args.width && (settings.width = args.width);
			args.height && (settings.height = args.height);
			args.thumbnailHeight && (settings.thumbnailHeight = args.thumbnailHeight);
			args.thumbnailQuality && (settings.thumbnailQuality = args.thumbnailQuality);
			args.thumbnailWidth && (settings.thumbnailWidth = args.thumbnailWidth);
			args.movieName && (settings.movieName = args.movieName);
			args.fileType && (settings.fileType = args.fileType);
			args.allowFileNum && (settings.allowFileNum = args.allowFileNum);
			args.uploadUrl && (settings.uploadUrl = args.uploadUrl);
			
			if(args.allowFileSize){
				var reg:RegExp = /(\d+)\s*([kmg]?)/;//默认为m  
				var _re = reg.exec(args.allowFileSize.toLocaleLowerCase())
				if(_re != null){
					var p:int = 1;
					switch (_re[2]){
						case '' :
						case 'm' :
							p = 1024*1024;
							break;
						case 'k' :
							break;
						case 'g' :
							p = 1024*1024*1024;
							break;
					}
					settings.allowFileSize = int(_re[1])*p;
				}
			}
			
			//通知初始化参数成功
			//jsCaller.initSettingSuccess();
		}
		/*初始化舞台*/
		private function _initStage(){
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var btn = new Sprite();
			this.button = btn;
			btn.graphics.beginFill(0xFFF,0);
			btn.graphics.drawRect(0,0,1000,1000);
			btn.graphics.endFill();
			btn.useHandCursor = true;
			btn.buttonMode = true;
			btn.mouseChildren = false;

			stage.addChild(btn);
			
			btn.addEventListener(MouseEvent.CLICK,this._handle_btn_click);
			btn.addEventListener(MouseEvent.MOUSE_OVER,this._handle_btn_enter);
			btn.addEventListener(MouseEvent.MOUSE_OUT,this._handle_btn_leave);
			
			this._fileBrowserMany.addEventListener(Event.SELECT, this._handle_browser_select);
			this._fileBrowserMany.addEventListener(Event.CANCEL,  this._handle_browser_cancel);
			
		}
		
		/*得到文件的过滤类型*/
		private function _getFileFilter():Array{
			if(_self._fileFilterArr == null){
				var fileType = _self._settings.fileType;
				var fileTypeArr:Array = fileType.split(';');
				_self._fileFilterArr = new Array();
				_self._fileFilterArr.push(new FileFilter(fileType, fileType));
				if(fileTypeArr.length > 1){
					for(var i=0,j=fileTypeArr.length;i<j;i++){
						var type = fileTypeArr[i];
						_self._fileFilterArr.push(new FileFilter(type, type));
					}
				}
			}
			
			return _self._fileFilterArr;
		}
		/*分析上传的文件*/
		private function _analyse_files(file_reference_list:Array){
			var _settings = _self._settings;
			var remainNum = _settings.allowFileNum - _self._uploadedFiles.length - _self._uploadingFiles.length;
			//超过最大数量
			if(file_reference_list.length > remainNum){
				_self.jsCaller.toMaxNum(remainNum);
				return;
			}
			//有大文件
			var a_size = _settings.allowFileSize;
			var irregularFileArr = new Array();;
			var jsFiles = new Array();
			for(var i=0,j=file_reference_list.length;i<j;i++){
				var file = file_reference_list[i];
				if(file.size > a_size){
					irregularFileArr.push(file.name);
				}
				_self._waittingFiles.push(new FileItem(i,file,_settings));
				jsFiles.push({'index':i,'name':file.name,'totalSize':file.size});
			}
			if(irregularFileArr.length > 0){
				_self.jsCaller.toMaxSize(irregularFileArr.join(','));
				return;
			}
			jsCaller.getFiles(jsFiles);//通知js用户选择的文件信息
			_self._nextUpload();
		}
		private function _nextUpload(){
			if(_self._waittingFiles.length==0){
				jsCaller.uploadCompleteAll();
			}else{
				_self._currentFile = _self._waittingFiles.shift();
				_self._currentFile.addEventListener(UploadNextEvent.COMPLETE,_self._handle_upload_complete);
				_self._currentFile.startUpload();
			}
		}
		/**************************** 绑定事件 start ****************************/
		private function _handle_upload_complete(e:UploadNextEvent){
			e.target.removeEventListener(UploadNextEvent.COMPLETE,_self._handle_upload_complete);
			jsCaller.uploadComplete(e.fileName,e.message);
			_self._nextUpload();
		}
		/*点击事件*/
		private function _handle_btn_click(e:MouseEvent){
			_self._fileBrowserMany.browse(_self._getFileFilter());
		}
		/*鼠标移上事件*/
		private function _handle_btn_enter(e:MouseEvent){
			_self.jsCaller.onMouseEnter();
		}
		/*鼠标移出事件*/
		private function _handle_btn_leave(e:MouseEvent){
			_self.jsCaller.onMouseLeave();
		}
		/*文件选择事件*/
		private function _handle_browser_select(e:Event){
			_self._analyse_files(_self._fileBrowserMany.fileList);
		}
		/*取消文件事件*/
		private function _handle_browser_cancel(e:Event){
			trace('_handle_browser_cancel');
		}
		
		
		
		/**************************** 绑定事件 end ****************************/
		
	}	
}
