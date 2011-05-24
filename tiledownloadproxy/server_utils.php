<?
	declare(ticks = 1);
	$__server_listening = true;	
	
	function server_loop($address, $port)
	{
	    GLOBAL $__server_listening;
	
	    if(($sock = socket_create(AF_INET, SOCK_STREAM, 0)) < 0)
	    {
	        echo "failed to create socket: ".socket_strerror($sock)."\n";
	        exit();
	    }
	
	    if(($ret = socket_bind($sock, $address, $port)) < 0)
	    {
	        echo "failed to bind socket: ".socket_strerror($ret)."\n";
	        exit();
	    }
	
	    if( ( $ret = socket_listen( $sock, 0 ) ) < 0 )
	    {
	        echo "failed to listen to socket: ".socket_strerror($ret)."\n";
	        exit();
	    }
	    
	    echo "waiting for clients to connect\n";
	
	    while ($__server_listening) {
	        $connection = @socket_accept($sock);
            handle_client($sock, $connection);
	    }
	}
	
	function handle_client($ssock, $csock)
	{
	    GLOBAL $__server_listening, $children;
		
	    $pid = pcntl_fork();
	
	    if ($pid == -1)
	    {
	        /* fork failed */
	        echo "fork failure!\n";
	        die;
	    } elseif ($pid == 0) {
	        /* child process */
	        $__server_listening = false;
	        socket_close($ssock);
	        handle_connection($csock);
	        socket_close($csock);
	        echo "Closed \n";
	        exit();
	    }else {
	    	$children[] = $pid;
	        socket_close($csock);
	    }
	    
	    while (pcntl_wait($status, WNOHANG OR WUNTRACED) > 0)
	    	echo "Waiting for child\n";
	    	
	    while (list($key, $val) = each($children)) {
			if (!posix_kill($val, 0)) {
				echo "Killed zombie $key\n";
				unset($children[$key]);
			}
	    }
	    
	    $children = array_values($children);
	}
?>