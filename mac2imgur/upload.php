<?php
define('BASE_URL', 'https://j.ungeek.fr/'); // @TODO: update this
define('BASE_PATH', __DIR__ . DIRECTORY_SEPARATOR);


$ext = substr(strrchr($_FILES['image']['name'], "."), 1);
$uploadfile = substr(md5(mt_rand().microtime(true)), 0, 6) . '.' . $ext;

$response = array();

$response['success'] = move_uploaded_file($_FILES['image']['tmp_name'], BASE_PATH . $uploadfile);

if($response['success']){
	$response['link'] =  BASE_URL . $uploadfile;
}

echo json_encode($response);
