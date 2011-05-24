#!/usr/bin/env php -q
<?
	set_time_limit(0);
	
	include "server_utils.php";
	include "headers.php";
		
	/* children array. used to murder zombies */
	$children = array();
	
	/* headers */
	$requestHeaders = new headers();
	$replyHeaders = new headers();
		
	/* change this to your own host / port */
	server_loop("127.0.0.1", 8080);
			
	function handle_connection($socket) {
		global $type, $requestHeaders;
		
		$requestHeaders->buildFromSocket($socket);
        
        // check if host and query matches google keyhole. if so, cache the result
        $sat_regexp = "http:\/\/kh[0-3]\.google\.com\/kh\?n\=404&v\=25&hl\=en&t\=[qrts]";
        $lab_regexp = "http:\/\/mt[0-3]\.google\.com\/mt\?n\=404&v\=w2t\.69&hl\=en&x\=[0-9]+&y\=[0-9]+&zoom\=[0-9]+&s\=[Galieo]*";
        $top_regexp = "http:\/\/mt[0-3]\.google\.com\/mt\?n\=404&v\=w2p\.71&hl\=en&x\=[0-9]+&y\=[0-9]+&zoom\=[0-9]+&s\=[Galieo]*";
        $caching = false;
        
        if (ereg($sat_regexp, $requestHeaders->getRequestString())) {
        	$caching = true;
        	$type = "satelite";
        	echo "WILL CACHE SATELITE\n";
        }
        if (ereg($lab_regexp, $requestHeaders->getRequestString())) {
        	$caching = true;
        	$type = "label";
        	echo "WILL CACHE LABEL\n";
        }

       if (ereg($top_regexp, $requestHeaders->getRequestString())) {
        	$caching = true;
        	$type = "topo";
        	echo "WILL CACHE TOPO\n";
        }

        /* forward to destination */
        pipe_request($socket, $requestHeaders, $caching);
	}
	
	function pipe_request($source_socket, $headers, $caching) {
		global $type, $replyHeaders;
		
		$destination_socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
		
		$host = gethostbyname($headers->getHeaderForKey("Host"));
		
		$host_array = explode(":", $host);
		if (sizeof($host_array) == 2) {
			$host = $host_array[0];
			$port = $host_array[1];
		} else
			$port = 80;
			
		if (socket_connect($destination_socket, $host, $port) === false)
	    	echo "socket_bind() failed: reason: " . socket_strerror(socket_last_error($destination_socket)) . "\n";
	    
	    // pipe the original request
	    $request = $headers->makeFullRequestString();
	    socket_write($destination_socket, $request);
		

		// read the reply headers
		$replyHeaders->buildFromSocket($destination_socket);
		$payload_len = 0;
		
		// pipe the reply headers to source
		$reply = $replyHeaders->makeFullRequestString();
		socket_write($source_socket, $reply);
		
		// determine destination filename
		if ($type == "satelite") {
			$name_arr = explode("&t=", $headers->getRequestString());
			$name = explode(" ", $name_arr[1]);
			$name = "images/" . $name[0] . ".jpg";
		}
		if ($type == "label" || $type == "topo") {
			$name_arr = explode("&x=", $headers->getRequestString());
			$x = explode("&y=", $name_arr[1]);
			$name_arr = explode("&y=", $headers->getRequestString());
			$y = explode("&zoom=", $name_arr[1]);
			$name_arr = explode("&zoom=", $headers->getRequestString());
			$zoom = explode("&s=", $name_arr[1]);
		
			if ($type == "label")
				$name = "images/label_". $x[0] . "." . $y[0] . "." . $zoom[0] . ".png";
			if ($type == "topo")
				$name = "images/topo_" . $x[0] . "." . $y[0] . "." . $zoom[0] . ".jpg";
		}
		
		// open the file
		if ($caching && !file_exists($name))
			$destination_file = fopen($name, "w");
			
		
		// everything we get now is plain data
		do {
			if (false === ($data = socket_read($destination_socket, 10000, PHP_BINARY_READ)))
				break;
			if (strlen($data) == 0)
				break;
			
			// write to cache file
			if ($caching)
				fwrite($destination_file, $data);
				
			// pipe to source
			if (false === socket_write($source_socket, $data))
				break;
				
			// got some data. add to payload_so_far. got all data? close connection
			$payload_so_far += strlen($data);
			if (@$replyHeaders->getHeaderForKey("Content-Length") == $payload_so_far)
				break;
			
		} while (true);
		
		@fclose($destination_file);
		
		// got the data, close the destination socket... client should close ours
		socket_close($destination_socket);
		
	}
?>
