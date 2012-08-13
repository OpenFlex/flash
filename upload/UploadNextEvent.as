package  {
	import flash.events.Event;
	public class UploadNextEvent extends Event{

		public static const COMPLETE:String = "COMPLETE";
		public var message:String;
		public var fileName:String;
		public function UploadNextEvent(type:String,fileName:String,msg:String=''){
			super(type);
			this.message = msg;
			this.fileName = fileName;
		}
	}
}
