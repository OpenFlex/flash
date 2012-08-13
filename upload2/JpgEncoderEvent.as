package  {
	import flash.events.Event;
	import flash.utils.ByteArray;

	public class JpgEncoderEvent extends Event{
		public static const COMPLETE:String = "COMPLETE";
		public static const START:String = "START";
		public var encodeByte:ByteArray;
		public function JpgEncoderEvent(type:String,encodedByteArray:ByteArray) {
			super(type);
			this.encodeByte = encodedByteArray;
		}
	}
	
}
