trace('begin111');
package {
        import flash.display.Sprite;
        import flash.display.StageAlign;
        import flash.display.StageScaleMode;
        import flash.events.*;
        import flash.media.Camera;
        import flash.media.Video;
        public class CameraExample extends Sprite
        {
                private var video:Video;
                public function CameraExample()
                {
					trace('begin');
                        stage.scaleMode=StageScaleMode.NO_SCALE;
                        stage.align=StageAlign.TOP_LEFT;
                        var camera:Camera=Camera.getCamera();
                        if(camera!=null)
                        {
                                camera.addEventListener(ActivityEvent.ACTIVITY,activityHandler);
                                video=new Video(camera.width*2,camera.height*2);
                                video.attachCamera(camera);
                                addChild(video);     
                        }
                        else
                        {
                                trace("机器上没有安装摄像头！");
                        }
                }
                private function activityHandler(e:ActivityEvent):void
                {
                   trace("activityHandler:"+e);
                }
        }
		new CameraExample();
}