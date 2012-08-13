package{
	internal class State{
		public static const ERROR_LOAD_FILE = 1;				//加载本地图片错误
		public static const ERROR_UPLOAD_FILE_IO  = 2;			//上传文件IO错误
		public static const ERROR_UPLOAD_FILE_SECURITY  = 21;	//上传文件安全错误security
		
		public static const FILE_STATE_FILE_LOAD = 3;//加载本地图片
		public static const FILE_STATE_LOADER = 31;//加载图片二进制数据
		public static const FILE_STATE_UPLOAD = 32;//上传中
		public static const FILE_STATE_CANCEL = 33;//取消上传
	}
}