package  {
	import flash.external.ExternalInterface;
	public class FlashCaller {
		private var movieName = '';
		private var uploader:Upload;
		public function FlashCaller(movieName:String,uploader:Upload) {
			this.movieName = movieName;
			this.uploader = uploader;
		}
		/*注册全部JS可以调用的方法*/
		public function registerCallback(){
			ExternalInterface.addCallback('cancel',_handle_cancel);
			ExternalInterface.addCallback('initSettings',_handle_init_setting);
		}
		/*取消上传*/
		private function _handle_cancel(fileName:String){
			uploader.cancelUpload(fileName);
		}
		/*初始化参数*/
		private function _handle_init_setting(settings:Object){
			uploader.initSettings(settings);
		}
	}
}
