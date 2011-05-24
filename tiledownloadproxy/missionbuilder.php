<?
	//create mission file
	include('coordtotile.php');

	if ($argc != 6)
		echo "Usage: phpcomposer latitude longitude zoom wspan_tiles hspan_tiles\n";

	$latitude = $argv[1];
	$longitude = $argv[2];
	$zoom = $argv[3];
	$width = $argv[4];
	$height = $argv[5];
	
	$base_tile = new Tile($latitude,$longitude,$zoom);
	$basex = $base_tile->p->x;
	$basey = $base_tile->p->y;
	$base_coords = $base_tile->getLatLongFromXYZoom($base_tile->p->x, $base_tile->p->y, $zoom); //y+1
	// final image
	$final = imagecreatetruecolor($width * 256, $height * 256);
	
	for ($i=0;$i<$width;$i++) {
		$base_tile->p->x = $basex + $i;
		for ($j=0;$j<$height;$j++) {
			$base_tile->p->y = $basey + $j; // base - $j
			
			// get image
			$filename = "images/".$base_tile->getKeyholeString() . ".jpg";
			if (!file_exists($filename)) {
				echo $filename . " does not exist. will try download\n";
				// not here. attempt download
				$server = $j%3;
				$contents = file_get_contents("http://kh".$server.".google.com/kh?n=404&v=25&hl=en&t=" . $base_tile->getKeyholeString());
				if (!$contents) {
					echo "No contents... Using 404\n";
					$filename = "images/404.jpg"; // download failed. use 404
				}
				else
					fwrite(fopen($filename,"w"), $contents); // download ok. use this one
			}
			
			// last check before making
			$check = fread(fopen($filename, "r"), 6);
			if ($check == "<html>") {
				echo "Image data contains html... Google error. Will use 404\n";
				unlink($filename);
				$filename = "images/404.jpg";
			}
			
			// get handle for this image
			$local = @imagecreatefromjpeg($filename);
			
			// append to right offset
			imagecopy($final, $local, $i*256, $j*256, 0, 0, 256, 256); //($height-1-$j)
		}
	}
	
	imagejpeg($final, "images/composition.jpg", 100);
	
	// now estimate coordinates of last tile
	$base_tile->p->x++;
	$base_tile->p->y++;
	
	$p = $base_tile->getLatLongFromXYZoom($base_tile->p->x, $base_tile->p->y, $zoom);
	
	echo "Debug: latitude[".$base_coords->x." ".$p->x."]\n";
	// creating mission file
	$output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
	<plist version=\"1.0\">
	<dict>
		<key>backgroundImage</key>
		<data>
		" . base64_encode(file_get_contents("images/composition.jpg")) . "
		</data>
		<key>baseCoordinates</key>
		<dict>
			<key>endLatitude</key>
			<real>".$base_coords->x."</real>
			<key>endLongitude</key>
			<real>".$p->y."</real>
			<key>startLatitude</key>
			<real>".$p->x."</real>
			<key>startLongitude</key>
			<real>".$base_coords->y."</real>
		</dict>
		<key>waypoints</key>
		<array/>
	</dict>
	</plist>";
	fwrite(fopen("composition.mission", "w"), $output);
?>