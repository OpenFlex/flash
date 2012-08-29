package  {
	import flash.events.Event;
	
	public class CancelEvent extends Event{
		public static const COMPLETE:String = "CANCEL_COMPLETE";
		public var fileName:String;
		public var isCancelAll:Boolean;
		public function CancelEvent(type:String,file_name:String,isCancelAll:Boolean=false) {
			super(type);
			this.fileName = file_name;
			this.isCancelAll = isCancelAll;
		}
	}
}
