package  {
	import flash.net.FileReference;
	import flash.display.Loader;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.*;
	
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLRequestHeader;
	
	import flash.utils.Endian;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import flash.filters.BlurFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import JsCaller;
	import State;
	import UploadNextEvent;
	import JpgEncoderEvent;
	import CancelEvent;
	import flash.events.Event;
	import flash.display.Sprite;

	public class FileItem extends Sprite{
		private var file_name:String;
		private var file_reference:FileReference;
		private var _this:FileItem;
		private var _settings:Object;
		private var _state:int;
		private var _eventObj:Object;
		
		private var _file_loader:Loader;
		private var _url_loader:URLLoader;
		private var _jpg_encoder:JPGEncoder;
		
		private var _timer:Timer;
		private var _timer_handle:Function;
		
		private var jsCaller:JsCaller;
		
		public function FileItem(file_name:String,file_reference:FileReference,settings:Object){
			_this = this;
			_this.file_name = file_name;
			_this.file_reference = file_reference;
			_this._settings = settings;
			jsCaller = new JsCaller(settings.movieName);
		}
		/*调用js里错误通知*/
		private function errorMsg(state:Number,msg:String){
			_this.jsCaller.errorMsg(state,msg,_this.file_name);
			_this.dispatchEvent(new UploadNextEvent(UploadNextEvent.ERROR,_this.file_name,msg));
		}
		/*得到文件名*/
		public function getFileName():String{
			return _this.file_name;
		}
		/*取消上传*/
		public function cancelUpload(isCancelAll:Boolean=false){
			_this._cancelUploadRemoveEvent();
			_this.dispatchEvent(new CancelEvent(CancelEvent.COMPLETE,_this.file_name,isCancelAll));
		}
		/*取消所有事件(不通知取消完成)*/
		private function _cancelUploadRemoveEvent(){
			_this._state = State.FILE_STATE_CANCEL;
			_this._remove_file_load_event();
			_this._remove_loader_event();
			_this._remove_urlLoader_event();
			_this._remove_encode_event();
		}
		/*开始上传*/
		public function startUpload(){
			//在打开本地图片之前响应，给用户更好的体验
			jsCaller.uploadStart(_this.file_name);
			_this._state = State.FILE_STATE_LOADING_FILE;
			_this._eventObj = _this.file_reference;
			_this.file_reference.addEventListener(Event.COMPLETE, _this._handle_file_load_complete);
			_this.file_reference.addEventListener(IOErrorEvent.IO_ERROR, _this._handle_file_load_error);
			
			
			if(_this._settings.loadDelay > 0){
				_this._setTimeout(_handle_delay_load,_this._settings.loadDelay);
			}
			_this.file_reference.load();
		}
		/*清除超时*/
		private function _clearTimeout(){
			if(_this._timer){
				_this._timer.removeEventListener(TimerEvent.TIMER_COMPLETE,_this._timer_handle);
			}
		}
		/*超时*/
		private function _setTimeout(handle:Function,delay:Number){			
			_this._timer = new Timer(delay,1);
			_this._timer_handle = handle;
			_this._timer.addEventListener(TimerEvent.TIMER_COMPLETE,handle);
			_this._timer.start();
		}
		/*加载超时*/
		private function _handle_delay_load(e:TimerEvent){
			if(_this._state == State.FILE_STATE_LOADING_FILE || _this._state == State.FILE_STATE_LOADING_DATA){
				_this._cancelUploadRemoveEvent();
				_this.errorMsg(State.ERROR_TIMEOUT_LOAD_DATA,'文件加载超时');
			}
		}
		/*压缩图片*/
		private function _resizeImage(fileData:ByteArray){
			_this._state = State.FILE_STATE_LOADING_DATA;
			_this._remove_loader_event();
			var _fileLoader = _this._file_loader = new Loader();
			
			_fileLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, _this._handle_loader_complete);
			_fileLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _this._handle_loader_error);
			
			if(_this._settings.loadDelay){
				_this._setTimeout(_handle_delay_load,_this._settings.loadDelay);
			}
			_fileLoader.loadBytes(fileData);
		}
		/*上传图片*/
		private function _uploadFile(fileData:ByteArray,isCompressed:Boolean=true){
			_this._state = State.FILE_STATE_UPLOADING;//正在上传
			var request:URLRequest = new URLRequest(_settings.uploadUrl);
			if(!isCompressed){
				var file_reference = _this.file_reference;
				//file_reference.addEventListener(Event.COMPLETE, _this._handle_urlloader_complete);
				file_reference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, _this._handle_filereference_upload_complete);
            	file_reference.addEventListener(Event.OPEN, _this._handle_urlloader_open);
           	 	file_reference.addEventListener(ProgressEvent.PROGRESS, _this._handle_urlloader_progress);
           	 	file_reference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _this._handle_urlloader_security_error);
            	file_reference.addEventListener(HTTPStatusEvent.HTTP_STATUS, _this._handle_urlloader_httpstatus);
            	file_reference.addEventListener(IOErrorEvent.IO_ERROR, _this._hand_urlloader_io_error);
				
				file_reference.upload(request,_this._settings.fileName);
				return;
			}
			_this._remove_urlLoader_event();
			var _urlLoader = _this._url_loader = new URLLoader();
			
			_this._eventObj = _urlLoader;
			
			request.method = URLRequestMethod.POST;
			var postData:ByteArray = new ByteArray();
			postData.endian = Endian.BIG_ENDIAN;
			postData = BOUNDARY(postData);
			postData = LINEBREAK(postData);
			
			postData = writeStringToByte(postData,'Content-Disposition: form-data; name="'+_this._settings.fileName+'"; filename="'+_this.file_reference.name+'"');
			postData = LINEBREAK(postData);
			postData = writeStringToByte(postData,'Content-Type: application/octet-stream');
			postData = LINEBREAK(postData);
			postData = LINEBREAK(postData);
			postData.writeBytes(fileData,0,fileData.length);
			postData = LINEBREAK(postData);
			postData = BOUNDARY(postData);
			postData = DOUBLEDASH(postData);
			
			request.data = postData;
			request.requestHeaders.push(new URLRequestHeader('Content-Type', 'multipart/form-data; boundary=' + getBoundary()));
			
			
           	_urlLoader.addEventListener(Event.COMPLETE, _this._handle_urlloader_complete);
            _urlLoader.addEventListener(Event.OPEN, _this._handle_urlloader_open);
            _urlLoader.addEventListener(ProgressEvent.PROGRESS, _this._handle_urlloader_progress);
            _urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _this._handle_urlloader_security_error);
            _urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, _this._handle_urlloader_httpstatus);
            _urlLoader.addEventListener(IOErrorEvent.IO_ERROR, _this._hand_urlloader_io_error);
			
			try {
                _urlLoader.load(request);
            } catch (error:Error) {
				_remove_urlLoader_event();
				_this.errorMsg(State.ERROR_LOAD_FILE,'文件上传时出现错误');
                trace("Unable to load requested document.");
            }
		}
		/********* 上传报头用 start *********/
		private static var _boundary:String;
		private function getBoundary():String
		{
			if (_boundary == null) {
				_boundary = '';
				for (var i:int = 0; i < 0x20; i++ ) {
					_boundary += String.fromCharCode( int( 97 + Math.random() * 25 ) );
				}
			}
			return _boundary;
		}
		private function BOUNDARY(p:ByteArray):ByteArray
		{
			var l:int = getBoundary().length;
			p = DOUBLEDASH(p);
			for (var i:int = 0; i < l; i++ ) {
				p.writeByte( _boundary.charCodeAt( i ) );
			}
			return p;
		}

		private function LINEBREAK(p:ByteArray):ByteArray
		{
			p.writeShort(0x0d0a);
			return p;
		}
		private function DOUBLEDASH(p:ByteArray):ByteArray
		{
			p.writeShort(0x2d2d);
			return p;
		}
		private function writeStringToByte(p:ByteArray,s:String):ByteArray{
			for ( var i = 0; i < s.length; i++ ) {
				p.writeByte( s.charCodeAt(i) );
			}
			return p;
		}
		/********* 上传报头用 end *********/
		/********** 事件绑定 *********/
		private function _remove_file_load_event(){
			if(_this.file_reference){
				_this.file_reference.removeEventListener(Event.COMPLETE, _this._handle_file_load_complete);
				_this.file_reference.removeEventListener(IOErrorEvent.IO_ERROR, _this._handle_file_load_error);
			}
			//把超时清除
			_this._clearTimeout();
		}
		/*加载本地图片完成事件*/
		private function _handle_file_load_complete(e:Event){trace('_handle_file_load_complete');
			_this._remove_file_load_event();
			
			_this._resizeImage(e.target.data);
		}
		/*加载本地图片错误*/
		private function _handle_file_load_error(e:IOErrorEvent){trace('_handle_file_load_error');
			_this._remove_file_load_event();
			_this.errorMsg(State.ERROR_LOAD_FILE,'加载本地图片时出现错误');
		}
		/*==========================*/
		/*删除加载本地图片数据事件*/
		private function _remove_loader_event(){
			var t = _this._file_loader;
			if(t){
				t.removeEventListener(Event.COMPLETE, _this._handle_loader_complete);
				t.removeEventListener(IOErrorEvent.IO_ERROR, _this._handle_loader_error);
				t = null;
			}
			//清除超时
			_this._clearTimeout();
		}
		/*loader加载本地图片数据完成事件*/
		private function _handle_loader_complete(e:Event){trace('_handle_loader_complete');
			_this._state = State.FILE_STATE_UPLOAD_PREPARING;
			_this._remove_loader_event();
			var loader:Loader = Loader(e.target.loader);
			var _oldWidth = loader.width,
				_oldHeight = loader.height;
			
			var error_state:Number,
				error_message:String;
			if(_oldWidth * _oldHeight > 16000000){
				error_state = State.ERROR_MAX_SIZE;
				error_message = '图片尺寸过大，请尝试缩小尺寸后再上传';
			}else if(_oldWidth > _oldHeight){
				if(_oldWidth < _settings.minWidth){
					error_state = State.ERROR_MIN_WIDTH;
					error_message = '图片尺寸太小，图片宽不能小于'+_settings.minWidth+'像素';
				}
			}else{
				if(_oldHeight < _settings.minHeight){
					error_state = State.ERROR_MIN_HEIGHT;
					error_message = '图片尺寸太小，图片高不能小于'+_settings.minHeight+'像素';
				}
			}
			if(error_state && error_message){
				_this._cancelUploadRemoveEvent();
				_this.errorMsg(error_state,error_message);
				return;
			}
			//当文件的大小太小时不进行压缩处理
			if(_this._settings.noCompressUnderSize > _this.file_reference.size){
				_this._uploadFile(_this.file_reference.data,false);
			}else{
				try{
					var contentType:String = loader.contentLoaderInfo.contentType;
					var _toWidth = _settings.thumbnailWidth,
						_toHeight = _settings.thumbnailHeight;
				
					var newWidth = _oldWidth,
						newHeight = _oldHeight;
					if(_oldWidth > _toWidth || _oldHeight > _toHeight){
						var _r_h = _toHeight/_oldHeight,
							_r_w = _toWidth/_oldWidth;
						if(_r_h > _r_w){
							newWidth = _toWidth;
							newHeight = _oldHeight * _r_w;
						}else{
							newWidth = _oldWidth * _r_h;
							newHeight = _toHeight;
						}
					}
			
					var bmp:BitmapData = Bitmap(loader.content).bitmapData;
			
					if (newWidth < _oldWidth || newHeight < _oldHeight) {
						var blurMultiplier:Number = 1.15; // 1.25;
						var blurXValue:Number = Math.max(1, bmp.width / newWidth) * blurMultiplier;
						var blurYValue:Number = Math.max(1, bmp.height / newHeight) * blurMultiplier;
				
						var blurFilter:BlurFilter = new BlurFilter(blurXValue, blurYValue, int(BitmapFilterQuality.LOW));
					
						bmp.applyFilter(bmp, new Rectangle(0, 0, bmp.width, bmp.height), new Point(0, 0), blurFilter);
					
						var matrix:Matrix = new Matrix();
						matrix.identity();
						matrix.createBox(newWidth / bmp.width, newHeight / bmp.height);
				
						var resizedBmp = new BitmapData(newWidth, newHeight, true, 0x000000);
						resizedBmp.draw(bmp, matrix, null, null, null, true);
				
						bmp.dispose();
						bmp = resizedBmp;
					}
					_this._state = State.FILE_STATE_COMPRESSING;//正在压缩
					var _jpgEncoder = _this._jpg_encoder = new JPGEncoder(_settings.thumbnailQuality);
					_jpgEncoder.addEventListener(JpgEncoderEvent.COMPLETE,_handle_encode_complete);
					_jpgEncoder.addEventListener(JpgEncoderEvent.START,_handle_encode_start);
				
					_jpgEncoder.encode(bmp);
					bmp.dispose();
				}catch(e:Error){
					_this._cancelUploadRemoveEvent();
					_this.errorMsg(State.ERROR_LOAD_FILE,'处理本地图片失败');
				}
			}
		}
		/*loader加载错误事件*/
		private function _handle_loader_error(e:IOErrorEvent){trace('_handle_loader_error');
			_this._remove_loader_event();
		}
		/*==========================*/
		/*删除压缩事件*/
		private function _remove_encode_event(){
			var t = _this._jpg_encoder;
			if(t){
				t.removeEventListener(JpgEncoderEvent.COMPLETE,_handle_encode_complete);
				t.removeEventListener(JpgEncoderEvent.START,_handle_encode_start);
				t = null;
			}
		}
		/*压缩完成*/
		private function _handle_encode_complete(e:JpgEncoderEvent){
			//压缩完成通知
			jsCaller.afterCompress(_this.file_name);
			//调用上传方法
			_this._uploadFile(e.encodeByte);
		}
		/*压缩开始*/
		private function _handle_encode_start(e:JpgEncoderEvent){
			//压缩前通知
			jsCaller.beforeCompress(_this.file_name);
		}
		/*删除上传事件*/
		private function _remove_urlLoader_event(t:Object=null){
			t = t || _this._url_loader;
			if(t){
				t.removeEventListener(Event.COMPLETE, _this._handle_urlloader_complete);
				t.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, _this._handle_filereference_upload_complete);
           		t.removeEventListener(Event.OPEN, _this._handle_urlloader_open);
           		t.removeEventListener(ProgressEvent.PROGRESS, _this._handle_urlloader_progress);
           		t.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _this._handle_urlloader_security_error);
           		t.removeEventListener(HTTPStatusEvent.HTTP_STATUS, _this._handle_urlloader_httpstatus);
           		t.removeEventListener(IOErrorEvent.IO_ERROR, _this._hand_urlloader_io_error);
				t = null;
			}
		}
		/*没有压缩上传完成*/
		private function _handle_filereference_upload_complete(e:DataEvent){trace('_handle_filereference_upload_complete '+e.data);
			_this._state = State.FILE_STATE_UPLOADED;//上传完成
			_this._remove_urlLoader_event();
			_this.dispatchEvent(new UploadNextEvent(UploadNextEvent.COMPLETE,_this.file_name,e.data));
		}
		/*压缩后上传完成*/
		private function _handle_urlloader_complete(e:Event){trace('_handle_urlloader_complete '+URLLoader(e.target).data);
			_this._state = State.FILE_STATE_UPLOADED;//上传完成
			_this._remove_urlLoader_event();
			_this.dispatchEvent(new UploadNextEvent(UploadNextEvent.COMPLETE,_this.file_name,URLLoader(e.target).data));
		}
		/*准备上传*/
		private function _handle_urlloader_open(e:Event){trace('_handle_urlloader_open');
			_this.jsCaller.uploadProgress(_this.file_name,0);
		}
		/*上传过程*/
		private function _handle_urlloader_progress(e:ProgressEvent){trace('_handle_urlloader_progress');
			var numLoaded:Number = e.bytesLoaded < 0 ? 0 : e.bytesLoaded,
				numTotal:Number = e.bytesTotal < 0 ? 0 : e.bytesTotal,
				percent:Number = 0;
			try{
				percent = numLoaded / numTotal;
			}catch(e:Error){
				
			}
			jsCaller.log(_this.file_name,numLoaded,numTotal,percent);
			jsCaller.uploadProgress(_this.file_name,percent);
		}
		/*上传安全出错*/
		private function _handle_urlloader_security_error(e:Event){trace('_handle_urlloader_security_error');			
			_this._remove_urlLoader_event();
			_this.errorMsg(State.ERROR_UPLOAD_FILE_SECURITY,'上传时出现安全错误');
		}
		/*httpstatus改变*/
		private function _handle_urlloader_httpstatus(e:Event){trace('_handle_urlloader_httpstatus');
		}
		/*io错误*/
		private function _hand_urlloader_io_error(e:Event){trace('_hand_urlloader_io_error');
			_this._remove_urlLoader_event();
			_this.errorMsg(State.ERROR_UPLOAD_FILE_IO,'上传时出现IO错误');
		}
	}
}
