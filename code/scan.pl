# Category = Link Management

#@  Scan one link a minute to try and catch up on status of things missed

if ($New_Minute){
	my @array = $All_Lights->list;
	my $link_number = (int(time / 60) % scalar(@array));
	my $insteon_device = ($All_Lights->list)[$link_number];
	$insteon_device->request_status();
}
