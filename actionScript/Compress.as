package  {
	
	import com.adobe.images.JPGEncoder;
	import com.adobe.images.PNGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.net.*;
	import flash.filters.BitmapFilterQuality;
	import flash.utils.ByteArray;
	
	
	public class Compress extends MovieClip {
		
		public function Compress() {
			var mc:MovieClip = new MovieClip();
				mc.graphics.beginFill(0x000000, 0.2);
				mc.graphics.drawRect(0, 0, 320, 455);
				mc.x = 30;
				mc.y = 60;
			
			addChild(mc);
			var _loader = new Loader();
			_loader.load(new URLRequest("../1.jpg"));
			mc.addChild(_loader);
			
			var bitmapData:BitmapData = new BitmapData(100, 100, true, 0);
				bitmapData.draw(_loader);
				
			
			//var encoder:JPGEncoder = new JPGEncoder(100);
			//var bytes:ByteArray = encoder.encode(bitmapData);
			var bytes:ByteArray = PNGEncoder.encode(bitmapData);
			
			var req:URLRequest = new URLRequest("http://js.zk.com/php/upload.php");
				req.data = bytes;
				req.method = URLRequestMethod.POST;
				req.contentType = "application/octet-stream";
				
			var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.BINARY;
				loader.load(req);
				loader.addEventListener(Event.COMPLETE, completeHandler);
		}
		private function completeHandler(evt:Event):void {
			trace(evt.target.data);
		}
	}
	
}
