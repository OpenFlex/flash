package  {	
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	import flash.events.*;
	import flash.events.MouseEvent;
	
	import flash.net.FileReferenceList;
	import flash.net.FileFilter;	
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLRequestHeader;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import flash.filters.BlurFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import JsCaller;
	import JPGEncoder;
	import flash.net.FileReference;
	
	public class Upload extends MovieClip {
		private var _width:int = 130;
		private var _height:int = 30;
		private var _thumbnailWidth:int = 600;
		private var _thumbnailHeight:int = 1000;
		private var _thumbnailQuality:int = 1;
		private var _movieName:String = 'fdx_upload';
		private var _fileType:String = '*.jpg;*.gif;*.png';
		private var _allowFileSize:Number = 6*1024*1024;//'6 M';
		private var _allowFileNum:int = 6;
		private var _fileName = 'Filedata';
		private var _uploadUrl = 'http://js.zk.com/php/upload.php';
		
		private var _fileFilterArr:Array;		
		private var _fileBrowserMany:FileReferenceList = new FileReferenceList();
		
		/*统计不同状态的文件数*/
		private var _waittingFiles:Array = new Array();
		private var _uploadingFiles:Array = new Array();
		private var _uploadedFiles:Array = new Array();
		private var _failedFiles:Array = new Array();
		private var _currentFile:FileReference;
		
		//报送分割符
		private var _boundary:String;
		private var _urlLoader:URLLoader;
		
		private var button:Sprite;
		
		private var jsCaller:JsCaller;
		//用于事件中调用
		private var _self:Upload;
		
		public function Upload() {
			_self = this;
			_self.init_settings();
			_self._initStage();
			_self.jsCaller = new JsCaller(_self._movieName);
		}
		public function cancelUpload(fileName:String){
			
		}
		/*初始化配置	*/
		private function init_settings(){
			var args = root.loaderInfo.parameters;
			args.width && (this._width = args.width);
			args.height && (this._height = args.height);
			args._thumbnailHeight && (this._thumbnailHeight = args._thumbnailHeight);
			args._thumbnailQuality && (this._thumbnailQuality = args._thumbnailQuality);
			args._thumbnailWidth && (this._thumbnailWidth = args._thumbnailWidth);
			args.movieName && (this._movieName = args.movieName);
			args.fileType && (this._fileType = args.fileType);
			args.allowFileNum && (this._allowFileNum = args.allowFileNum);
			
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
					this._allowFileSize = int(_re[1])*p;
				}
			}
		}
		/*初始化舞台*/
		private function _initStage(){
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
				var fileTypeArr:Array = _self._fileType.split(';');
				_self._fileFilterArr = new Array();
				_self._fileFilterArr.push(new FileFilter(_fileType, _fileType));
				for(var i=0,j=fileTypeArr.length;i<j;i++){
					var type = fileTypeArr[i];
					_self._fileFilterArr.push(new FileFilter(type, type));
				}
			}
			
			return _self._fileFilterArr;
		}
		private function _analyse_files(file_reference_list:Array){
			var remainNum = _self._allowFileNum - _self._waittingFiles.length - _self._uploadedFiles.length - _self._uploadingFiles.length;
			//超过最大数量
			if(file_reference_list.length > remainNum){
				_self.jsCaller.toMaxNum(remainNum);
				return;
			}
			//有大文件
			var a_size = _self._allowFileSize;
			var irregularFileArr = new Array();;
			/*for(var i=0,j=file_reference_list.length;i<j;i++){
				var file = file_reference_list[i];
				if(file.size > a_size){
					irregularFileArr.push(file.name);
				}
			}*/
			if(irregularFileArr.length > 0){
				_self.jsCaller.toMaxNum(irregularFileArr.join(','));
				return;
			}
			_self._waittingFiles = file_reference_list;
			
			_self._startUpload();
		}
		private function _startUpload(){
			if(_self._waittingFiles.length==){
				JsCaller.
				return;
			}
			_self._currentFile = _self._waittingFiles.shift();
			_self._currentFile.addEventListener(Event.COMPLETE, _self._handle_file_load_complete);
			_self._currentFile.addEventListener(IOErrorEvent.IO_ERROR, _self._handle_file_load_error);
			
			_self._currentFile.load();
		}
		/********* 上传报头用 start *********/
		public function getBoundary():String
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
		private function _uploadFile(fileData:ByteArray){
			var request:URLRequest = new URLRequest(_self._uploadUrl);
			
			request.method = URLRequestMethod.POST;
			var postData:ByteArray = new ByteArray();
			postData.endian = Endian.BIG_ENDIAN;
			postData = BOUNDARY(postData);
			postData = LINEBREAK(postData);
			
			postData = writeStringToByte(postData,'Content-Disposition: form-data; name="'+_self._fileName+'"; filename="'+_self._currentFile.name+'"');
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
			_urlLoader = new URLLoader();
			
           	_urlLoader.addEventListener(Event.COMPLETE, _self._handle_urlloader_complete);
            _urlLoader.addEventListener(Event.OPEN, _self._handle_urlloader_open);
            _urlLoader.addEventListener(ProgressEvent.PROGRESS, _self._handle_urlloader_progress);
            _urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _self._handle_urlloader_security_error);
            _urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, _self._handle_urlloader_httpstatus);
            _urlLoader.addEventListener(IOErrorEvent.IO_ERROR, _self._hand_urlloader_io_error);
			
			try {
                _urlLoader.load(request);
            } catch (error:Error) {
                trace("Unable to load requested document.");
            }
		}
		/*压缩图片*/
		private function _resizeImage(fileData:ByteArray){
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _self._handle_loader_complete);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _self._handle_loader_error);
				
			loader.loadBytes(fileData);trace('oldSize:'+fileData.length);
		}
		private function IsTranscoding(type:String):Boolean {
			return false;//!((type == "image/jpeg" && this.encoder == ImageResizer.JPEGENCODER) || (type == "image/png" && this.encoder == ImageResizer.PNGENCODE));
		}
		/**************************** 绑定事件 start ****************************/
		private function _remove_urlLoader_event(){
			_self._urlLoader.removeEventListener(Event.COMPLETE, _self._handle_urlloader_complete);
           	_self._urlLoader.removeEventListener(Event.OPEN, _self._handle_urlloader_open);
           	_self._urlLoader.removeEventListener(ProgressEvent.PROGRESS, _self._handle_urlloader_progress);
           	_self._urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, _self._handle_urlloader_security_error);
           	_self._urlLoader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, _self._handle_urlloader_httpstatus);
           	_self._urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, _self._hand_urlloader_io_error);
		}
		private function _handle_urlloader_complete(e:Event){
			_self._remove_urlLoader_event();
			_self._startUpload();//进行下一个上传操作
			trace('_handle_urlloader_complete');
			var loader:URLLoader = URLLoader(e.target);
            trace("completeHandler: " + loader.data);
			
		}
		private function _handle_urlloader_open(e:Event){
			trace('_handle_urlloader_open');
		}
		private function _handle_urlloader_progress(e:Event){
			trace('_handle_urlloader_progress');
		}
		private function _handle_urlloader_security_error(e:Event){
			trace('_handle_urlloader_security_error');
		}
		private function _handle_urlloader_httpstatus(e:Event){
			trace('_handle_urlloader_httpstatus');
		}
		private function _hand_urlloader_io_error(e:Event){
			trace('_hand_urlloader_io_error');
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
			trace('cancel');
		}
		/*加载本地图片完成事件*/
		private function _handle_file_load_complete(e:Event){trace('_handle_file_load_complete');
			e.target.removeEventListener(Event.COMPLETE, _self._handle_file_load_complete);
			_self._resizeImage(e.target.data);
		}
		private function _handle_file_load_error(e:IOErrorEvent){
			trace('_handle_file_load_error');
		}
		/*loader加载本地图片数据完成事件*/
		private function _handle_loader_complete(e:Event){trace('_handle_loader_complete');
			e.target.removeEventListener(Event.COMPLETE, _self._handle_loader_complete);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, _self._handle_loader_error);
			
			var loader:Loader = Loader(e.target.loader);

			var contentType:String = loader.contentLoaderInfo.contentType;
			// Calculate the new image size
			var targetRatio:Number = _self._thumbnailWidth / _self._thumbnailHeight;
			var imgRatio:Number = loader.width / loader.height;
			var newHeight = (targetRatio > imgRatio) ? _self._thumbnailHeight : Math.min(_self._thumbnailWidth / imgRatio, _self._thumbnailHeight);
			var newWidth = (targetRatio > imgRatio) ? Math.min(imgRatio * _self._thumbnailHeight, _self._thumbnailWidth) : _self._thumbnailWidth;
			
			var bmp:BitmapData = Bitmap(loader.content).bitmapData;
			if (newWidth < bmp.width || newHeight < bmp.height) {
				// Apply the blur filter that helps clean up the resized image result
				var blurMultiplier:Number = 1.15; // 1.25;
				var blurXValue:Number = Math.max(1, bmp.width / newWidth) * blurMultiplier;
				var blurYValue:Number = Math.max(1, bmp.height / newHeight) * blurMultiplier;
				
				var blurFilter:BlurFilter = new BlurFilter(blurXValue, blurYValue, int(BitmapFilterQuality.LOW));
				bmp.applyFilter(bmp, new Rectangle(0, 0, bmp.width, bmp.height), new Point(0, 0), blurFilter);
			}
			var uploadBytes:ByteArray;
			if (newWidth < bmp.width || newHeight < bmp.height || _self.IsTranscoding(contentType)) {
				// Apply the resizing
				var matrix:Matrix = new Matrix();
				matrix.identity();
				matrix.createBox(newWidth / bmp.width, newHeight / bmp.height);

				var resizedBmp = new BitmapData(newWidth, newHeight, true, 0x000000);
				resizedBmp.draw(bmp, matrix, null, null, null, true);
				
				bmp.dispose();
				bmp = resizedBmp;
			} else {
				trace('else');
				// Just send along the unmodified data
				//dispatchEvent(new ImageResizerEvent(ImageResizerEvent.COMPLETE, this.file.file_reference.data, this.encoder));
			}
			
			uploadBytes = new JPGEncoder(80).encode(bmp);
			bmp.dispose();
			_self._uploadFile(uploadBytes);//调用上传方法
		}
		/*loader加载错误事件*/
		private function _handle_loader_error(e:IOErrorEvent){
			trace('_handle_loader_error');
		}
		/**************************** 绑定事件 end ****************************/
		
	}	
	private class FileItem{
		private var file_index:int;
		private var file_reference:FileReference;
		public function FileItem(file_index:int,file_reference:FileReference){
			this.file_index = file_index;
			this.file_reference = file_reference;
		}
		/*取消上传*/
		public function cancelUpload(){
			
		}
	}
}
