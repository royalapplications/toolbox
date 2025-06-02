function sendError($text) {
	fwrite(STDERR, "ERROR: ".$text);
	exit;
}

$host = '$CustomProperty.ForemanURL$';
$user = '$EffectiveUsername$';
$pass = '$EffectivePassword$';
$preferIP = strtolower('$CustomProperty.ConnectbyIP$') == 'yes';

if(empty($host) || $host=='TODO') sendError('Set Foreman URL in Custom-Propertys');
if(empty($user) || empty($pass)) sendError('No Credentials configured');

$ch = curl_init($host.'/api/hosts');
curl_setopt($ch, CURLOPT_USERPWD, "{$user}:{$pass}");
curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$return = curl_exec($ch);
curl_close($ch);

if(empty($return)) sendError("Can't connect to Foreman"); 
$hosts = json_decode($return);
if(empty($hosts)) sendError("Invalid Response from Foreman"); 
if(!empty($hosts->error)) sendError($hosts->error->message); 
if(count((array)$hosts->results) == 0) sendError("No Hosts found"); 

$folders = array();
foreach($hosts->results as $host)
{
	if(!isset($folders[$host->location_name])) $folders[$host->location_name] = array();
	$e = &$folders[$host->location_name][];

	$e['Name'] = $host->name;
	if($preferIP)
	{
		if(!empty($host->ip)) $e['ComputerName'] = $host->ip;
		else if(!empty($host->ip6)) $e['ComputerName'] = $host->ip6;
	}
	if(empty($e['ComputerName'])) $e['ComputerName'] = $host->certname;
	$e['MACAddress'] = $host->mac;

	$desc = '';
	if(!empty($host->ip)) $desc.="IPv4: {$host->ip}\r\n";
	if(!empty($host->ip6)) $desc.="IPv6: {$host->ip6}\r\n";
	if(!empty($host->operatingsystem_name)) $desc.="OS: {$host->operatingsystem_name}\r\n";
	if(!empty($host->compute_resource_name)) $desc.="VM HOST: {$host->compute_resource_name}\r\n";
	else if(!empty($host->model_name)) $desc.="Model: {$host->model_name}\r\n";
	
	if(!empty($desc)) $e['Description'] = "\r\n".$desc;

	if(strpos($host->operatingsystem_name, 'windows') !== FALSE)
	{
		$e['Type'] = 'RemoteDesktopConnection';
		$e['IconName'] ='/Flat/Hardware/Platform OS Windows';
	} else {
		$e['Type'] = 'TerminalConnection';
		$e['TerminalConnectionType'] = 'SSH';
		$e['IconName'] ='/Flat/Hardware/Platform OS Linux';
	}
}

$ret = array();
foreach($folders as $foldername => $entrys)
{
	$e = &$ret[];
	$e['Name'] = $foldername;
	$e['Type'] = 'Folder';
	$e['Objects'] = $entrys;
}

$json = json_encode(array( "Objects" => $ret ));
echo $json;