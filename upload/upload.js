define(function(require,exports){
	var defaultConfig = {
		container : $('body'),//将flash添加到的对象
		version : Math.random(),
		width : 130,//按钮宽
		height : 30,//按钮高
		thumbnailWidth : 600,//缩略图宽度
		thumbnailHeight : 1000,//缩略图高度
		thumbnailQuality : 80,//缩略图品质
		fileType : null,//文件类型,flash里默认为"*.jpg;*.gif;*.png"
		allowFileSize : '6m',//允许上传的文件大小
		noCompressUnderSize : '300k',//小于这个大小时不压缩
		allowFileNum : 6,//允许上传的最大数量
		fileName : '',//上传文件的字段名
		uploadUrl : 'http://flash.zk.com/upload.php',//上传URL
		imgData : null,//可能会初始化的图片信息

		onMouseEnter : null,//鼠标移上事件
		onMouseLeave : null,//鼠标移出事件
		progressStyleOn : true,//是否使用默认进度条样式
		onGetFiles : null,//当选择文件完成事件
		onToMaxSize : null,//文件太大事件
		onToMaxNum : null,//达成最大数量事件
		onUploadStart : null,//上传开始事件
		onUploadProgress : null,//上传进度事件
		onUploadError : null,//上传错误事件
		onUploadComplete : null,//上传完成事件
		onAllUploadComplete : function(files){
			if(files){
				var imgData = this.config.imgData||[];
				for(var i = 0,j=files.length;i<j;i++){
					var file = files[i];
					imgData.push({'img_hash':file['img_hash'],'img_time':file['img_time']});
				}
				post_to_url(config.uploadUrl,imgData);
			}
		},//全部上传完成事件
		onUploadCancelSuccess : null,//取消上传成功事件
		onError : function(res){
			res && alert(res.info+' [错误代码：'+res.status+']');
		},//一般错误事件

		cancelUpload : null//取消上传
	};
	var flashFile = 'http://flash.zk.com/upload/index.swf';
	var uploadPregressHtml = '<ul class="upload_progress" id="${movieName}_progress">'+
								'{{each(i,v) fileList}}'+
								'<li class="upload_file_${v.index}">'+
									'<span class="upload_filename">${v.name}</span>'+
									'<span class="upload_close" data-name="${movieName}" data-index="${v.index}">X</span>'+
									'<span class="upload_status">等待..</span>'+
									'<span class="upload_progressbar"></span>'+
								'</li>'+
								'{{/each}}'+
							 '</ul>';
	$.template( 'uploadPregressTmpl', uploadPregressHtml);
	/**构造函数*/
	var Upload = function(settings){
		this.config = null;
		this.flashObj = '';
		this.name = Upload.getMovieName(Upload.cache.length++);
		this.init(settings);
		this.uploadedFiles = {};
		Upload.cache[this.name] = this;
	},
	uploadProp = Upload.prototype;
	/*初始化配置*/
	uploadProp.init = function(settings){
		if(settings){
			settings = $.extend({},defaultConfig,settings);
		}
		this.config = settings;
		this.flashObj = $(Upload.getFlashHtml(this.name,settings.width,settings.height,settings.version,$.param(this.getFlashParam())));
	};
	//得到初始化flash时的参数	
	uploadProp.getFlashParam = function(){
		var settings = this.config;
		var pArr = ['thumbnailWidth','thumbnailHeight','thumbnailQuality',
			'fileType','allowFileSize','allowFileSize','noCompressUnderSize',
			'allowFileNum','fileName','uploadUrl'];
		var flashPram = {'movieName':this.name};
		for(var i=0,j=pArr.length;i<j;i++){
			if(pArr[i] in settings && settings[pArr[i]]){
				flashPram[pArr[i]] = settings[pArr[i]];
			}
		}
		return flashPram;
	}
	/*得到上传完成的图片列表*/
	uploadProp.getUploadedFiles = function(){
		var files = this.uploadedFiles,filesArr = [];
		for(var i in files){
			filesArr.push(files[i]);
		}
		return filesArr;
	}
	/*重置*/
	uploadProp.reset = function(){
		$('#'+this.name+'_progress').remove();
		this.uploadedFiles = {};
	}
	/*取消上传*/
	uploadProp.cancel = function(fileIndex){
		Upload.getFlashMovie(this.name).cancel(fileIndex);
	}

	//缓存Upload对象
	Upload.cache = {'length':0};
	//得到对象名
	Upload.getMovieName = function(index){
		return 'fdx_upload_'+index;
	}
	
	//得到要显示的flash的html
	Upload.getFlashHtml = function(id,width,height,version,flashParam){
		var swf = flashFile+(version?'?'+version:'');
		/*FF中浏览器只认识embed标记，所以如果你用getElementById获 flash的时候，
		需要给embed做ID标记，而IE是认识object标记的 ，所以你需要在object上的
		ID做上你的标记*/
		flashHtml = 
			'<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=7,0,0,0" width="'+width+'" height="'+height+'" id="'+id+'">'+
			'<param name="allowScriptAccess" value="sameDomain" />'+
			'<param name="movie" value="'+swf+'" />'+
			'<param name="quality" value="high" />'+
			'<param name="bgcolor" value="#ffffff" />'+
			'<param name="wmode" value="transparent">'+
			'<param name="flashvars" value="'+flashParam+'">'+
			'<embed src="'+swf+'" name="'+id+'" quality="high" bgcolor="#ffffff" width="'+width+'" height="'+height+'" name="myFlash" swLiveConnect="true" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" wmode="transparent" flashvars="'+flashParam+'"/> '+
		  '</object>';
		return flashHtml;
	}
	/*得到flash对象，用于交互*/
	Upload.getFlashMovie = (function(){
		var doc = ~navigator.appName.indexOf("Microsoft")?window:document;
		return function(name){
			doc[name];
		}
	})();

	Upload.getFlashMovie = function(movieName){
		if(navigator.appName.indexOf("Microsoft") != -1){
			return window[movieName]; 
		}else{
			return document[movieName];
		}
	}
	/*单个文件的状态*/
	Upload.getFileProgress = function(movieName,fileName){
		return $('#'+movieName+'_progress').find('.upload_file_'+fileName);
	}
	;(function(win){
		var uploadCallback = {};
		function callback(flashName,fn,fnArgs/*Array*/){
			var uploadObj = Upload.cache[flashName];
			if(typeof uploadObj != 'undefined'){
				if(!$.isFunction(fn)){
					fn = uploadObj.config[fn];
				}
				$.isFunction(fnArgs) && (fnArgs = fnArgs.apply(uploadObj));
				$.isFunction(fn) && fn.call(uploadObj,fnArgs);
			}
		}
		/*鼠标移上*/
		uploadCallback.mouseEnter = function(flashName){
			callback(flashName,'onMouseEnter');
			myLog('mouseEnter',arguments);
		}
		/*鼠标移出*/
		uploadCallback.mouseLeave = function(flashName){
			callback(flashName,'onMouseLeave');
			myLog('mouseLeave',arguments);
		}
		/*选择完文件准备处理时通知*/
		uploadCallback.getFiles = function(flashName,files){
			callback(flashName,'onGetFiles',arguments);
			myLog('getFiles',arguments);
			callback(flashName,function(){
				var _this = this,
					flashObj = _this.flashObj,
					offset = flashObj.offset();myLog('选择时'+_this.name);
				var uploadPregress = $.tmpl('uploadPregressTmpl', {'movieName':_this.name,'fileList':files});
				uploadPregress.css({'left':offset.left,'top':offset.top+flashObj.height()})
					.find('.upload_close').click(function(){
						_this.cancel($(this).data('index'));
					});
				$(this.config.container).append(uploadPregress);
			});
		}
		/*达到最大上传数量*/
		uploadCallback.toMaxNum = function(flashName,remainNum){
			callback(flashName,'onToMaxNum',arguments);
			myLog('toMaxNum',arguments);
		}
		/*文件太大*/
		uploadCallback.toMaxSize = function(flashName,irregularInfo){
			callback(flashName,'onToMaxSize',arguments);
			myLog('toMaxSize',arguments);
		}
		/*上传完成,fileName='all'时表示全部上传完成,此时imgUrl不起作用*/
		uploadCallback.uploadComplete = function(flashName,fileName,imgInfo){
			myLog('uploadComplete',arguments);
			imgInfo = $.parseJSON(imgInfo)
			if(imgInfo && imgInfo.status == '200'){
				if(fileName){
					callback(flashName,'onUploadComplete',arguments);
					callback(flashName,function(){
						this.uploadedFiles[fileName] = imgInfo;
						var $file = Upload.getFileProgress(this.name,fileName);
						$file.find('.upload_close').remove();
						$file.find('.upload_status').html('成功');
						$file.find('.upload_progressbar').css('width',180*percent);
					});
				}else{//全部上传完成
					$('#'+flashName+'_progress').remove();
					callback(flashName,'onAllUploadComplete',function(){
						return this.getUploadedFiles();
					});
				}
			}else{
				callback(flashName,function(){
					this.cancel();
				});
				uploadCallback.error(flashName,imgInfo);
			}
		}
		/*准备开始上传*/
		uploadCallback.uploadStart = function(flashName,fileName){
			callback(flashName,'onUploadStart',arguments);
			myLog('uploadStart',arguments);
		}
		/*上传进度,percent为0~1的小数*/
		uploadCallback.uploadProgress = function(flashName,fileName,percent){
			callback(flashName,'onUploadProgress',arguments);
			myLog('uploadProgress',arguments);
			callback(flashName,function(){
				var $file = Upload.getFileProgress(this.name,fileName);
				$file.find('.upload_status').html(percent*100+'%');
				$file.find('.upload_progressbar').css('width',180*percent);
			});
		}
		/*取消成功*/
		uploadCallback.uploadCancelSuccess = function(flashName,fileName){
			callback(flashName,'onUploadCancelSuccess',arguments);
			myLog('uploadCancelSuccess',arguments);
			callback(flashName,function(){
				if(fileName){
					Upload.getFileProgress(this.name,fileName).remove();
				}else{
					$('#'+movieName+'_progress').remove();
				}
			});
		}
		/*错误*/
		uploadCallback.error = function(flashName,info){
			myLog('error',arguments);
			callback(flashName,function(){
				this.reset();
			});
			callback(flashName,'onError',info);
		}
		win.UploadCallback = uploadCallback;
	})(window);

	exports.Upload = function(settings){
		this.up = new Upload(settings);
	}
	exports.Upload.prototype.init = function(settings){
		this.up.init(settings);
		return this;
	}
	/*将flash覆盖在按钮上*/
	exports.Upload.prototype.show = function(btn){
		var up = this.up,
			flashObj = up.flashObj,
			settings = up.config;
		flashObj.css({'position':'absolute'});
		btn = $(btn);
		if(btn.length > 0){
			var offset = btn.offset();
			flashObj.css({'left':offset.left,'top':offset.top});
		}
		if(settings.container){
			$(settings.container).append(flashObj);
		}
		return flashObj;
	}
})