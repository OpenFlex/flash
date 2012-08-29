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
	
	import flash.filters.BlurFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import JsCaller;
	import State;
	import UploadNextEvent;
	import flash.events.Event;
	import flash.display.Sprite;

	public class FileItem extends Sprite{
		private var file_name:String;
		private var file_reference:FileReference;
		private var _this:FileItem;
		private var _settings:Object;
		private var _state:int;
		private var _eventObj:Object;
		
		private var jsCaller:JsCaller;
		
		public function FileItem(file_name:String,file_reference:FileReference,settings:Object){
			_this = this;
			_this.file_name = file_name;
			_this.file_reference = file_reference;
			_this._settings = settings;
			jsCaller = new JsCaller(settings.movieName);
		}
		public function getFileName():String{
			return _this.file_name;
		}
		/*取消上传*/
		public function cancelUpload(){
			switch(_state){
				case State.FILE_STATE_FILE_LOAD :
					_this._remove_file_load_event(_this._eventObj);
					break;
				case State.FILE_STATE_LOADER :
					_this._remove_loader_event(_this._eventObj);
					break;
				case State.FILE_STATE_UPLOAD :
					_this._remove_urlLoader_event(_this._eventObj);
					break;
				case State.FILE_STATE_CANCEL :
					break;
			}
		}
		/*开始上传*/
		public function startUpload(){
			//在打开本地图片之前响应，给用户更好的体验
			jsCaller.uploadStart(_this.file_name);
			_this._state = State.FILE_STATE_FILE_LOAD;
			_this._eventObj = _this.file_reference;
			_this.file_reference.addEventListener(Event.COMPLETE, _this._handle_file_load_complete);
			_this.file_reference.addEventListener(IOErrorEvent.IO_ERROR, _this._handle_file_load_error);
			
			_this.file_reference.load();
		}
		/*压缩图片*/
		private function _resizeImage(fileData:ByteArray){
			var loader:Loader = new Loader();
			_this._state = State.FILE_STATE_LOADER;
			_this._eventObj = loader;
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _this._handle_loader_complete);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _this._handle_loader_error);
				
			loader.loadBytes(fileData);trace('oldSize:'+fileData.length);
		}
		/*上传图片*/
		private function _uploadFile(fileData:ByteArray){
			var _urlLoader = new URLLoader();
			var request:URLRequest = new URLRequest(_settings.uploadUrl);
			
			_this._state = State.FILE_STATE_UPLOAD;
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
				_remove_urlLoader_event(_urlLoader);
				jsCaller.errorMsg(State.ERROR_LOAD_FILE,'不能加载本地图片');
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
		private function _remove_file_load_event(t:Object){
			t.removeEventListener(Event.COMPLETE, _this._handle_file_load_complete);
			t.removeEventListener(IOErrorEvent.IO_ERROR, _this._handle_file_load_error);
		}
		/*加载本地图片完成事件*/
		private function _handle_file_load_complete(e:Event){trace('_handle_file_load_complete');
			_this._remove_file_load_event(e.target);
			
			_this._resizeImage(e.target.data);
		}
		/*加载本地图片错误*/
		private function _handle_file_load_error(e:IOErrorEvent){trace('_handle_file_load_error');
			_this._remove_file_load_event(e.target);
			jsCaller.errorMsg(State.ERROR_LOAD_FILE,'加载本地图片时出现错误');
		}
		/*==========================*/
		/*删除加载本地图片数据事件*/
		private function _remove_loader_event(t:Object){
			t.removeEventListener(Event.COMPLETE, _this._handle_loader_complete);
			t.removeEventListener(IOErrorEvent.IO_ERROR, _this._handle_loader_error);
		}
		/*loader加载本地图片数据完成事件*/
		private function _handle_loader_complete(e:Event){trace('_handle_loader_complete'+_this.file_reference.data.length);
			_this._remove_loader_event(e.target);
			//当文件的大小太小时不进行压缩处理
			if(_this._settings.noCompressUnderSize > _this.file_reference.size){
				_this._uploadFile(_this.file_reference.data);
			}else{
				var loader:Loader = Loader(e.target.loader);

				var contentType:String = loader.contentLoaderInfo.contentType;
				var _oldWidth = loader.width,
					_oldHeight = loader.height,
					_toWidth = _settings.thumbnailWidth,
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
			
				trace(newWidth,newHeight,loader.width,loader.height);
			
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
				var uploadBytes:ByteArray = new JPGEncoder(_settings.thumbnailQuality).encode(bmp);
				bmp.dispose();
				_this._uploadFile(uploadBytes);//调用上传方法
			}
		}
		/*loader加载错误事件*/
		private function _handle_loader_error(e:IOErrorEvent){trace('_handle_loader_error');
			_this._remove_loader_event(e.target);
		}
		/*==========================*/
		/*删除上传事件*/
		private function _remove_urlLoader_event(t:Object){
			t.removeEventListener(Event.COMPLETE, _this._handle_urlloader_complete);
           	t.removeEventListener(Event.OPEN, _this._handle_urlloader_open);
           	t.removeEventListener(ProgressEvent.PROGRESS, _this._handle_urlloader_progress);
           	t.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _this._handle_urlloader_security_error);
           	t.removeEventListener(HTTPStatusEvent.HTTP_STATUS, _this._handle_urlloader_httpstatus);
           	t.removeEventListener(IOErrorEvent.IO_ERROR, _this._hand_urlloader_io_error);
		}
		/*上传完成*/
		private function _handle_urlloader_complete(e:Event){trace('_handle_urlloader_complete '+URLLoader(e.target).data);
			_this._remove_urlLoader_event(e.target);
			_this.dispatchEvent(new UploadNextEvent(UploadNextEvent.COMPLETE,_this.file_name,URLLoader(e.target).data));
		}
		/*准备上传*/
		private function _handle_urlloader_open(e:Event){trace('_handle_urlloader_open');
			
		}
		/*上传过程*/
		private function _handle_urlloader_progress(e:ProgressEvent){trace('_handle_urlloader_progress');
			jsCaller.uploadProgress(_this.file_name,e.bytesLoaded/e.bytesTotal);
		}
		/*上传安全出错*/
		private function _handle_urlloader_security_error(e:Event){trace('_handle_urlloader_security_error');			
			_this._remove_urlLoader_event(e.target);
			jsCaller.errorMsg(State.ERROR_UPLOAD_FILE_SECURITY,'上传时出现错误');
		}
		/*httpstatus改变*/
		private function _handle_urlloader_httpstatus(e:Event){trace('_handle_urlloader_httpstatus');
			
		}
		/*io错误*/
		private function _hand_urlloader_io_error(e:Event){trace('_hand_urlloader_io_error');
			_this._remove_urlLoader_event(e.target);
			jsCaller.errorMsg(State.ERROR_UPLOAD_FILE_IO,'上传时出现错误');
		}
	}
}
