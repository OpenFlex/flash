package  {
	import flash.events.Event;
	public class UploadNextEvent extends Event{
		
		/*上传完成触发*/
		public static const COMPLETE:String = "COMPLETE";
		/*上传不合法尺寸时触发*/
		//public static const ILLEGAL_SIZE:String = 'ILLEGAL_SIZE';
		//加载本地图片时出错
		//public static const ERROR_LOAD:String = 'ERROR_LOAD';
		
		//单个文件上传出现错误
		public static const ERROR:String = 'ERROR_UPLOAD';
		public var message:String;
		public var fileName:String;
		public function UploadNextEvent(type:String,fileName:String,msg:String=''){
			super(type);
			this.message = msg;
			this.fileName = fileName;
		}
	}
}
