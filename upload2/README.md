#flash+js上传文件
	详解用法参考index.html里的用例,可参考：http://tonny-zhang.github.com/flash/upload2/index.html
## 参数说明(用户可自定义参数覆盖默认配置)
	var defaultConfig = {
		container : $('body'),	//将flash添加到的对象
		version : typeof front_version == 'undefined'?'':front_version,	//flash的版本号
		btn : null,		//此参数必须设置，flash最后将覆盖其上
		minWidth : 500,		//图片最小宽度
		minHeight : 500,	//图片最小高度
		thumbnailWidth : 600,	//缩略图宽度
		thumbnailHeight : 1000,	//缩略图高度
		thumbnailQuality : 80,	//缩略图品质
		fileType : null,	//文件类型,flash里默认为"*.jpg;*.gif;*.png"
		allowFileSize : '6m',	//允许上传的文件大小
		noCompressUnderSize : '300k',	//小于这个大小时不压缩
		allowFileNum : 6,		//允许上传的最大数量
		fileName : 'imagefile',		//上传文件的字段名
		uploadUrl : '/show/ajax/upload.fan',//上传URL
		commitUrl : '/show/save.fan',	//上传完成后的提交地址
		commitParam : {},		//上传完成后提交时要传递的参数,GET方式会追加到commitUrl后
		postParam : {},			//上传完成后提交时要传递的参数，POST方式提交

		onMouseEnter : null,		//鼠标移上事件
		onMouseLeave : null,		//鼠标移出事件
		onGetFiles : null,		//当选择文件完成事件
		onToMaxSize : function(flashName,allowFileSize,irregularInfo){//文件太大事件
			alert('最大可上传大小为 '+this.config.allowFileSize+' 的文件');
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
		onUploadCancelSuccess : null,		//取消上传成功事件
		onError : function(flashName,res){	//一般错误事件
			res && res.info && alert(res.info+(res.status?' [错误代码：'+res.status+']':''));
		}
	};