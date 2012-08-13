<?php
error_reporting(E_ALL ^ E_NOTICE);
$return = array();
if (!empty($_FILES)) {
	$tempFile = $_FILES['Filedata']['tmp_name'];
	$filename = $_FILES['Filedata']['name'];
	$targetPath = 'e:/flash/uploadImg/';
	$ext = strtolower( end( explode( '.',$filename ) ) );
	$filename = md5($filename).'.'.$ext;
	$targetFile =  str_replace('//','/',$targetPath) . $filename;
	
	// $fileTypes  = str_replace('*.','',$_REQUEST['fileext']);
	// $fileTypes  = str_replace(';','|',$fileTypes);
	// $typesArray = split('\|',$fileTypes);
	// $fileParts  = pathinfo($_FILES['Filedata']['name']);
	
	// if (in_array($fileParts['extension'],$typesArray)) {
		// Uncomment the following line if you want to make the directory if it doesn't exist
		// mkdir(str_replace('//','/',$targetPath), 0755, true);
		move_uploaded_file($tempFile,$targetFile);
		$return['status'] = 200;
		$return['img_hash'] = '123';
		$return['img_time'] = time();
		echo json_encode($return);
	// } else {
	// 	echo 'Invalid file type.';
	// }
}
?>