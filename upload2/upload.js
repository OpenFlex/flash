(function(){
	var debug = /debug/.test(location.search);//调试模式
	var fdx_time = new Date().getTime();//flash定义名称时用到，保证作用域的唯一性
	var defaultConfig = {
		container : $('body'),	//将flash添加到的对象
		version : typeof front_version == 'undefined'?'':front_version,	//flash的版本号
		btn : null,				//此参数必须设置，flash最后将覆盖其上
		minWidth : 500,			//图片最小宽度
		minHeight : 500,		//图片最小高度
		thumbnailWidth : 600,	//缩略图宽度
		thumbnailHeight : 1000,	//缩略图高度
		thumbnailQuality : 80,	//缩略图品质
		fileType : null,		//文件类型,flash里默认为"*.jpg;*.gif;*.png"
		allowFileSize : '6m',	//允许上传的文件大小
		noCompressUnderSize : '300k',//小于这个大小时不压缩
		allowFileNum : 6,		//允许上传的最大数量
		fileName : 'imagefile',	//上传文件的字段名
		uploadUrl : '/show/ajax/upload.fan',//上传URL
		commitUrl : '/show/save.fan',//上传完成后的提交地址
		commitParam : {},		//上传完成后提交时要传递的参数,GET方式会追加到commitUrl后
		postParam : {},			//上传完成后提交时要传递的参数，POST方式提交

		onMouseEnter : null,	//鼠标移上事件
		onMouseLeave : null,	//鼠标移出事件
		onGetFiles : null,		//当选择文件完成事件
		onToMaxSize : function(flashName,allowFileSize,irregularInfo){//文件太大事件
			alert('最大可上传大小为 '+allowFileSize+' 的文件');
		},
		onToMaxNum : function(flashName,remainNum){//达成最大数量事件
			alert('最多可上传'+remainNum+'个文件');
		},
		illegalFileType : function(flashName,allowFileType,irregularInfo){//文件类型不正确
			alert('请选择正确的文件类型');
		},
		onUploadStart : null,	//上传开始事件
		onUploadProgress : null,//上传进度事件
		onUploadError : null,	//上传错误事件
		onUploadComplete : null,//上传完成事件
		onAllUploadComplete : function(flashName,files){//全部上传完成事件
			var _this = this;
			if($.isArray(files) && files.length > 0){
				if(_this.uploadFailedFiles.length > 0){
					alert('部分文件因为尺寸不符合要求等原因，上传失败');
				}
				var config = _this.config;
				var imgData = config.imgData||[];
				for(var i = 0,j=files.length;i<j;i++){
					var file = files[i];
					imgData.push({'img_hash':file['img_hash'],'img_time':file['img_time']});
				}
				Upload.log('post to save',imgData);
				var url = config.commitUrl,
					param = $.extend({},config.commitParam);
				if(param){
					param = $.param(param);
					param && (url += (~url.indexOf('?')?'&':'?')+param);
				}
				Upload.post(url,imgData,config.postParam);
			}
		},
		onUploadCancelSuccess : null,			//取消上传成功事件
		onError : function(flashName,res){		//一般错误事件
			res && res.info && alert(res.info+(res.status?' [错误代码：'+res.status+']':''));
		}
	};
	//flash路径
	var flashFile = './index.swf';
	//上传进度模板
	var uploadPregressHtml = '<ul class="upload_progress" id="${movieName}_progress">'+
								'{{each(i,v) fileList}}'+
								'<li class="upload_file_${v.index}">'+
									'<span class="upload_filename" title="${v.name}">${v.name}</span>'+
									'<span class="upload_close" data-name="${movieName}" data-index="${v.index}">X</span>'+
									'<span class="upload_status">等待..</span>'+
									'<span class="upload_progressbar"></span>'+
								'</li>'+
								'{{/each}}'+
								'<li>'+
									'<input class="upload_cancel_btn" type="button" value="取消所有上传"/>'+
								'</li>'+
							 '</ul>';
	$.template( 'uploadPregressTmpl', uploadPregressHtml);
	/**构造函数*/
	var Upload = function(settings){
		var _this = this;
		_this.flashObj = '';
		_this.name = Upload.getMovieName(Upload.cache.length++);
		_this.uploadedFiles = {};
		_this.uploadFailedFiles = [];
		Upload.cache[_this.name] = _this;
		settings = $.extend({},defaultConfig,settings);
		settings.btn = $(settings.btn);
		_this.config = settings;
		if(!settings.btn || $(settings.btn).length == 0){
			alert('参数btn不可为空');
			return;
		}
		if(!settings.container || $(settings.container).length == 0){
			alert('参数container不可为空');
			return;
		}
		_this.show();
	},
	uploadProp = Upload.prototype;
	//得到初始化flash时的参数	
	uploadProp.getFlashParam = function(){
		var settings = this.config;
		var pArr = ['minWidth','minHeight','thumbnailWidth','thumbnailHeight','thumbnailQuality',
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
			files[i] && filesArr.push(files[i]);
		}
		return filesArr;
	}
	/*重置*/
	uploadProp.reset = function(){
		Upload.removeFileProgress(this.name);
		this.uploadedFiles = {};
	}
	/*取消上传*/
	uploadProp.cancel = function(fileIndex){
		Upload.getFlashMovie(this.name).cancel(fileIndex);
	}
	/*
	* 修改上传flash的位置
	* 当初始化时容器隐藏着（尤其初始尺寸为０）,改变尺寸后要调用此方法修复flash的位置
	*/
	uploadProp.fixedPosition = function(){
		var _this = this,
			config = _this.config,
			btn = config.btn;
		var offset = Upload.getOffset(config,btn);
		_this.flashObj.css({'left':offset.left,'top':offset.top});
	}
	/*将flash覆盖在按钮上*/
	uploadProp.show = function(){
		var _this = this,
			config = _this.config,
			btn = config.btn,
			flashObj = null;

		flashObj = $(Upload.getFlashHtml(this.name,btn.outerWidth(),btn.outerHeight(),config.version,$.param(_this.getFlashParam())));
		_this.flashObj = flashObj;
		flashObj.css({'position':'absolute','z-index':'99'});
		var offset = Upload.getOffset(config,btn);
		flashObj.css({'left':offset.left,'top':offset.top});
		config.container.append(flashObj);
	}
	/*post提交数据*/
	Upload.post = function(url,params){
		if(arguments.length > 1){
			params = Array.prototype.slice.call(arguments,0);
			url = params.shift();

			var form = document.createElement("form");
			form.setAttribute("method", 'POST');
			form.setAttribute("action", url);
			function addFeild(name,value){
				var hiddenField = document.createElement("input");
				hiddenField.setAttribute("type", "hidden");
				hiddenField.setAttribute("name", name);
				hiddenField.setAttribute("value", value);
				form.appendChild(hiddenField);
			}
			for (var i = 0,j=params.length;i<j;i++) {
				var param = params[i];
				if(param){
					if($.isArray(param)){
						for (var k in param) {
							for (var k2 in param[k]) {
								addFeild( k + "[" + k2 + "]",param[k][k2]);
							}
						}
					}else if($.isPlainObject(param)){
						for(var i in param){
							addFeild(i,param[i]);
						}
					}
				}
			}
			document.body.appendChild(form);
			debug || form.submit();
		}
	}
	/*得到元素的offset,如果是container==body返回offset(),否则用position()*/
	Upload.getOffset = function(config,obj){
		var container = $(config.container);
		return container.selector.toLowerCase() == 'body'?obj.offset() : obj.position();
	}
	/*url参数加debug即可调试*/
	Upload.log = (function(){
		if(typeof console != 'undefined' && debug){
			return function(){
				console.log.apply(console,Array.prototype.splice.call(arguments,0));
			}
		}else{
			return function(){};
		}
	})();

	//缓存Upload对象
	Upload.cache = {'length':0};
	//得到对象名
	Upload.getMovieName = function(index){
		//保证多次加载文件时有不同的作用域和名称
		return 'fdx_upload_'+fdx_time+'_'+index;
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
			'<embed src="'+swf+'" name="'+id+'" quality="high" bgcolor="#ffffff" width="'+width+'" height="'+height+'" name="'+id+'" swLiveConnect="true" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" wmode="transparent" flashvars="'+flashParam+'"/> '+
		  '</object>';
		return flashHtml;
	}
	/*得到flash对象，用于交互*/
	/*Upload.getFlashMovie = (function(){
		var doc = ~navigator.appName.indexOf("Microsoft")?window:document;
		return function(name){
			doc[name];
		}
	})();*/
	
	Upload.getFlashMovie = function(movieName){
		if(navigator.appName.indexOf("Microsoft") != -1){
			return window[movieName]; 
		}else{
			return document[movieName];
		}
	}
	/*单个文件的状态*/
	Upload.getFileProgress = function(movieName,fileName){
		var p_container = $('#'+movieName+'_progress');
		return (fileName||fileName=="0")?p_container.find('.upload_file_'+fileName):p_container;
	}
	/*删除上传进度*/
	Upload.removeFileProgress = function(movieName,fileName){
		var isRemoveAll = (!fileName && fileName!="0");
		if(!isRemoveAll){
			var removeProgress = Upload.getFileProgress(movieName,fileName);
			isRemoveAll = removeProgress.siblings().length <= 1;
			removeProgress.remove();
		}
		if(isRemoveAll){
			Upload.getFileProgress(movieName).remove();
			var uploadObj = Upload.cache[movieName];
			uploadObj && (uploadObj.uploadFailedFiles=[]);//将错误列表清除
		}
	}
	/*flash要调用的方法*/
	;(function(win){
		var uploadCallback = {};
		/*fn的回调中会传入除fn个的所有参数*/
		function callback(flashName,fn,fnArgs/*可以有多个*/){
			var uploadObj = Upload.cache[flashName];
			if(typeof uploadObj != 'undefined'){
				var args = Array.prototype.slice.call(arguments,0);
				fn = args.splice(1,1).shift();
				if(!$.isFunction(fn)){
					fn = uploadObj.config[fn];
				}
				$.isFunction(fn) && fn.apply(uploadObj,args);
			}
		}
		/*鼠标移上*/
		uploadCallback.mouseEnter = function(flashName){
			Upload.log('mouseEnter',arguments);
			callback(flashName,'onMouseEnter');
		}
		/*鼠标移出*/
		uploadCallback.mouseLeave = function(flashName){
			Upload.log('mouseLeave',arguments);
			callback(flashName,'onMouseLeave');
		}
		/*选择完文件准备处理时通知*/
		uploadCallback.getFiles = function(flashName,files){
			Upload.log('getFiles',arguments);
			callback(flashName,'onGetFiles',files);
			callback(flashName,function(){
				var _this = this,
					flashObj = _this.flashObj,
					offset = Upload.getOffset(_this.config,flashObj);
					
				var uploadPregress = $.tmpl('uploadPregressTmpl', {'movieName':_this.name,'fileList':files});
				uploadPregress.css({'left':offset.left,'top':offset.top+flashObj.height()})
					.find('.upload_close').click(function(){
						_this.cancel($(this).data('index'));
					});
				uploadPregress.find('.upload_cancel_btn').click(function(){
					_this.cancel();
				});
				$(_this.config.container).append(uploadPregress);
			});
		}
		/*达到最大上传数量*/
		uploadCallback.toMaxNum = function(flashName,remainNum){
			Upload.log('toMaxNum',arguments);
			callback(flashName,'onToMaxNum',remainNum);
		}
		/*文件太大*/
		uploadCallback.toMaxSize = function(flashName,illegalInfo,allowFileSize){
			Upload.log('toMaxSize',arguments);
			callback(flashName,'onToMaxSize',allowFileSize,illegalInfo);
		}
		/*不合法的文件类型*/
		uploadCallback.illegalFileType = function(flashName,illegalInfo,allowFileType){
			Upload.log('illegalFileType',arguments);
			callback(flashName,'illegalFileType',allowFileType,illegalInfo);
		}
		/*上传完成,fileName='all'时表示全部上传完成,此时imgUrl不起作用*/
		uploadCallback.uploadComplete = function(flashName,fileName,imgInfo){
			Upload.log('uploadComplete',arguments);
			if(fileName){
				imgInfo = $.parseJSON(imgInfo);
				if(imgInfo && imgInfo.status == '200'){
					//修复出现异常的上传进度条
					uploadCallback.uploadProgress(flashName,fileName,1);
					callback(flashName,'onUploadComplete',fileName,imgInfo);
					callback(flashName,function(){
						this.uploadedFiles[fileName] = imgInfo;
						var $file = Upload.getFileProgress(this.name,fileName);
						$file.find('.upload_close').remove();
						$file.find('.upload_status').html('成功');
						$file.find('.upload_progressbar').css('width',function(){
							var $this = $(this);
							return $this.parent().outerWidth()-$($this).css('left');
						});
					});
				}else{
					uploadCallback.error(flashName,imgInfo,true);
				}
			}else{//全部上传完成
				Upload.removeFileProgress(flashName);
				callback(flashName,function(){
					callback(flashName,'onAllUploadComplete',this.getUploadedFiles());
				});
			}
		}
		/*准备开始上传*/
		uploadCallback.uploadStart = function(flashName,fileName){
			Upload.log('uploadStart',arguments);
			callback(flashName,'onUploadStart',fileName);
		}
		/*上传进度,percent为0~1的小数*/
		uploadCallback.uploadProgress = function(flashName,fileName,percent){
			Upload.log('uploadProgress',arguments);
			callback(flashName,'onUploadProgress',fileName,percent);
			
			callback(flashName,function(){
				var $file = Upload.getFileProgress(this.name,fileName);
				$file.find('.upload_status').html(percent*100+'%');
				$file.find('.upload_progressbar').css('width',function(){
					var $this = $(this),s=$this.data('tW');
					if(!s){
						s = $this.parent().width()-parseFloat($this.css('left'))*2;
						$this.data('tW',s);
					}
					return s*percent;
				});
			});
		}
		/*取消成功*/
		uploadCallback.uploadCancelSuccess = function(flashName,fileName){
			Upload.log('uploadCancelSuccess',arguments);
			callback(flashName,'onUploadCancelSuccess',fileName);
			callback(flashName,function(){
				if(fileName){
					Upload.removeFileProgress(this.name,fileName);
				}else{
					this.reset();
				}
			});
		}
		/*压缩前*/
		uploadCallback.beforeCompress = function(flashName,fileName){
			Upload.log('beforeCompress',arguments);
		}
		/*压缩后*/
		uploadCallback.afterCompress = function(flashName,fileName){
			Upload.log('afterCompress',arguments);
		}
		/*错误*/
		uploadCallback.error = function(flashName,info,noCancel){
			Upload.log('error',arguments);
			callback(flashName,function(){
				//单个文件出现错误
				if(info && info.fileName){
					this.uploadFailedFiles.push({});
					Upload.removeFileProgress(this.name,info.fileName);
				}else if(!noCancel){
					this.reset();
				}
			});
			callback(flashName,'onError',info);
		}
		uploadCallback.log = function(){
			Upload.log('==log==',arguments);
		};
		win.UploadCallback = uploadCallback;
	})(window);

	/*保证seajs在解析require时的效率(减少正则要检索的字条串长度)*/
	define(function(require,exports){
		require('./upload.css');
		exports.log = Upload.log;
		exports.Upload = function(settings){
			this.up = new Upload(settings);
		}
		/*取消上传*/
		exports.Upload.prototype.cancel = function(fileIndex){
			this.up.cancel(fileIndex);
		}
		/*取消上传*/
		exports.Upload.prototype.fixedPosition = function(){
			this.up.fixedPosition();
		}
	});
})()