﻿package  {
	import flash.external.ExternalInterface;
	public class JsCaller {
		private static var handleName:String = 'UploadCallback.';
		private var movieName = '';
		public function JsCaller(movieName:String){
			this.movieName = movieName;
		}
		private function _call(jsFnName:String,... arguments):*{
			arguments.unshift(this.movieName);
			arguments.unshift(JsCaller.handleName+jsFnName);
			ExternalInterface.call.apply(null,arguments);
			trace(arguments);
		}
		public function log(jsFnName:String,... arguments){
			this._call('log',jsFnName,arguments);
		}
		public function initSettingSuccess(){
			this._call('initSettingSuccess');
		}
		/*鼠标移上*/
		public function onMouseEnter() {
			this._call('mouseEnter');
		}
		/*鼠标移出*/
		public function onMouseLeave() {
			this._call('mouseLeave');
		}
		/*选择完文件准备处理时通知*/
		public function getFiles(files:Array){
			this._call('getFiles',files);
		}
		/*达到最大上传数量*/
		public function toMaxNum(remainNum:int){
			this._call('toMaxNum',remainNum);
		}
		/*文件太大*/
		public function toMaxSize(illegalInfo:String,allowFileSize:String=''){
			this._call('toMaxSize',illegalInfo,allowFileSize);
		}
		/*不合法的文件类型*/
		public function illegalFileType(illegalInfo:String,allowFileType:String=''){
			this._call('illegalFileType',illegalInfo,allowFileType);
		}
		/*上传完成,fileName='all'时表示全部上传完成,此时imgUrl不起作用*/
		public function uploadComplete(fileName:String,imgUrl:String){
			this._call('uploadComplete',fileName,imgUrl);
		}
		/*全部上传完成*/
		public function uploadCompleteAll(){
			this._call('uploadComplete');
		}
		/*准备开始上传*/
		public function uploadStart(fileName:String){
			this._call('uploadStart',fileName);
		}
		/*上传进度,percent为0~1的小数*/
		public function uploadProgress(fileName:String,percent:Number){
			this._call('uploadProgress',fileName,percent);
		}
		/*取消成功*/
		public function uploadCancelSuccess(fileName:String){
			this._call('uploadCancelSuccess',fileName);
		}
		/*错误*/
		public function errorMsg(state:int,msg:String,fileName:String=null){
			var errorObj = {'status':state,'info':msg};
			if(fileName){
				errorObj['fileName'] = fileName;
			}
			this._call('error',errorObj);
		}
		/*压缩前*/
		public function beforeCompress(fileName:String){
			this._call('beforeCompress',fileName);
		}
		/*压缩后*/
		public function afterCompress(fileName:String){
			this._call('afterCompress',fileName);
		}
	}	
}
