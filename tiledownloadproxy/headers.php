<?

class headers {
	private $requestString;
	private $headerDictionary;
	
	function headers() {
		$this->headerDictionary = array();
		return $this;
	}
	
	/* constructor override. creates from open socket positioned at start-of-conn */
	function buildFromSocket($socketRef) {
		$last_line = "";
		do
        {
        	/* php_normal_read returns lines */
            if (false === ($line = socket_read($socketRef, 2048, PHP_NORMAL_READ))) {
            	echo "socket_read() failed: reason: " . socket_strerror(socket_last_error($socketRef)) . "\n";
            	break;
        	}
        	
        	if (ord($line[0]) == 10 && ord($last_line[0]) == 13)
        		break;
        		
			// clean line
        	$line_new = str_replace(chr(13), "", $line);
        	$line_new = str_replace(chr(10), "", $line_new);
        	
        	if (strlen($line_new) > 0 && ord($line_new[0]) != 13) // add to headers
				$request_headers[] = $line_new;
			
			$last_line = $line;
		        
        } while (true);
        
        // add fro, request_headers
        $this->setHeaders($request_headers);
	}
	
	function setHeaders($headerArray) {
		// for each item, add
		for ($i=0;$i<sizeof($headerArray);$i++) {
			// each item is plain string key = value
			$header = explode(": ", $headerArray[$i]);
			if (sizeof($header) == 2)
				$this->addHeader($header[0], $header[1]);
			else
				$this->setRequestString($headerArray[$i]);
		}
	}
	
	function addHeader($key, $value) {
		$this->headerDictionary[$key] = $value;
	}
	
	function getHeaderForKey($key) {
		return $this->headerDictionary[$key];
	}
	
	function getRequestString() {
		return $this->requestString;
	}
	
	function setRequestString($requestStr) {
		$this->requestString = $requestStr;
	}
	
	function makeFullRequestString() {
		$reqStr = "";
		
		if (!empty($this->requestString))
			$reqStr .= $this->requestString . chr(13) . chr(10);
		
		foreach($this->headerDictionary as $key=>$value)
			$reqStr .= $key . ": " . $value . chr(13) . chr(10);
		
		$reqStr .= chr(13) . chr(10);
		
		return $reqStr;
	}
}
?>