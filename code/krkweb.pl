# Category = Interfaces

#@  HTML5 Interface, mostly for phones, and to some extent tablets.
#@  Todo: AJAX dyanimc objects, some code cleanup

####Changelog
# 2013-01-03 Import from my tailored iPhone.pl

## The main routine
# takes 2 arguments, group name, and output type
sub html5WebApp { 
  my ($list_name, $output) = @_; 
  my @objects = &list_objects_by_group($list_name, 1);
  my $html = ""; 
  my $html_group = "";
  my $html_group_list ="";
  my $html_group_list_no_act ="";
  my $html_item_list= "";
  my $html5_state;
  my $object;

  # Create a hash to sort items numerically
  # Items should be named to look like 1-First Floor
  # the number and dash are removed
  my %hash_names;
  foreach my $item (@objects) { 
	my $name = &get_object_by_name($item)->{label};
	#If we have a nicely entered name use that, otherwise make things nicer
	if ($name eq '' or $name eq undef) {
		$name = &pretty_object_name($item);
	}
	$hash_names{$name} = $item; 
  }

  # This sorts the items and then creates the appropriate html
  for my $key (sort {$a<=>$b} keys %hash_names) {
    my $item = $hash_names{$key};
    my $name = $key;
    $object = &get_object_by_name($item);
    my @item_states = ();
    
    #create a usuable name without the dollar sign
    $item =~ s/^\$//;

    next if $object->{hidden};

	my $state = $object->state();

    if ($object->isa('Group')) {
        ###fix state, if reset MH reports groups as off even when a member is on
        # Weather items don't have states
        if ($$object{jq_state}){
        		#package main;
			$state = eval ($$object{jq_state});
			&::print_log("[JQuery_Web] Error object jq_state eval $@") if $@;
			#package Insteon::BaseObject;
        }
        else{
        	$state = '';
        }

    }
    $html5_state .= "$item,$state|";
    my $html_state_id = $item . "_state";

    # Remove sort numerals
    $name =~ s/(^\d*-)//g;
    
    # Add divider
    if ($name =~ /^#/){
        $html_group_list .= insert_divider();
        $name =~ s/(^#)//g;
    }
    
    ### Item specific tasks
    if ($object->isa('Group')) {
    	#Create group html entry
        $html_group_list .= insert_list_item($name, "$html_state_id", $state, "#page_$item");
        #Create appropriate html for group members recursively
        if ($output eq "states"){
            $html5_state .= html5WebApp($item,'states');
        } else {
            $html_group .= html5WebApp($item,'subgroup');    
        }
    } elsif ($object->isa('Insteon::BaseObject')) {
    	## I would like to destroy this whole section in favor of simply relying on the broadcast
    	## states provided by each item.
        my @item_states = ();
        @item_states = $object->get_states;
          $html_item_list .= <<EOF;
                    <div data-role="collapsible" data-collapsed="true">
                        <h3>
                            $name
                            <span style="float: right;" id="$html_state_id">$state</span>
                        </h3>
                        <div data-role="controlgroup" data-mini="false" data-type="horizontal">
EOF
          #Populate states
          if ($object->isa('Insteon::DimmableLight')){
            $html_item_list .= <<EOF;
                            <a href="#" data-role="button" onClick="setState('$item','on');" data-theme="b">on</a>
                            <a href="#" data-role="button" onClick="setState('$item','80');" data-theme="b">80</a>
                            <a href="#" data-role="button" onClick="setState('$item','60');" data-theme="b">60</a>
                            <a href="#" data-role="button" onClick="setState('$item','40');" data-theme="b">40</a>
                            <a href="#" data-role="button" onClick="setState('$item','20');" data-theme="b">20</a>
                            <a href="#" data-role="button" onClick="setState('$item','off');" data-theme="b">off</a>
EOF
          } else {
              #my @item_states = @{$object->{states}}; Already have states from above
              for my $s (@item_states) {
                next if ($s =~ m:\d*/\d*.*:);
                $html_item_list .= <<EOF;
                            <a href="#" data-role="button" onClick="setState('$item','$s');" data-theme="b">$s</a>
EOF
              }              
          }
          $html_item_list .= <<EOF;
                        </div>
                    </div>
EOF
    } else {
        ##Generic Items
        @item_states = $object->get_states;
	if ((scalar(@item_states) > 0) && ($item_states[0] ne '') ) { #Generic item has states
		$html_item_list .= <<EOF;
                    <div data-role="collapsible" data-collapsed="true">
                        <h3>
                            $name
                            <span style="float: right;" id="$html_state_id">$state</span>
                        </h3>
                        <div data-role="controlgroup" data-mini="false" data-type="horizontal">
EOF
              for my $s (@item_states) {
                #next if ($s =~ m:\d*/\d*.*:);
                $html_item_list .= <<EOF;
                            <a href="#" data-role="button" onClick="setState('$item','$s');" data-theme="b">$s</a>
EOF
              }              
          $html_item_list .= <<EOF;
                        </div>
                    </div>
EOF
	}
	else { #No item states
		$html_group_list_no_act .= insert_list_item($name, "$html_state_id", $state);
	}
     } #End item specific HTML
  } #End loop of objects

  ## Build basic page structure and insert item html
  my $title;
  $object = &get_object_by_name($list_name);
  $title = $object->{label};
  $title = &pretty_object_name($list_name) if ($title eq '' or $title eq undef);
  #KRK added to remove sort numerals and dividers
  $title =~ s/(^\d*-)//g;
  $title =~ s/(^#)//g;
  my $id = $list_name;
  $id =~ s/^\$//;
  #id is variable name, title is the pretty name
  my $footer = &mobile_footer;
  if ($output eq "main" || $output eq "subgroup") {
    return insert_page($id, $title, $html_group_list, $html_group_list_no_act, 
		$html_item_list, $html_group, $output);
  } elsif ($output eq "states"){
      return $html5_state;
  } else {
    $html = 'Error no layer type selected';
  }
  return &html_page('', $html);
}

sub insert_divider {
	my ($output);
	$output = <<EOF;
		<li data-role="list-divider" role="heading">
		</li>
EOF
	return $output;
}

sub insert_list_item {
	my ($name, $id, $state, $href) = @_;
	my ($output);
	if ($href){
		$output = <<EOF;
		<li data-theme="c">
			<a href="$href" data-transition="slide">
				$name <span style="float: right;" id="$id">$state</span>
			</a>
		</li>
EOF
	} else {
		$output = <<EOF;
		<li data-theme="c">
			$name <span style="float: right;" id="$id">$state</span>
		</li>
EOF
	}
	return $output;
}

sub insert_page{
	my ($id, $title, $html_group_list, $html_group_list_no_act, 
		$html_item_list, $html_group, $type) = @_;
	my $footer = mobile_footer();
	my $output = <<EOF;
        <div data-role="page" id="page_$id">
            <div data-theme="a" data-role="header">
EOF
	if ($type eq "main"){
		$output .= <<EOF;
                <a data-role="button" href="#" id="refresh_time" 
                onClick="updateState();" class="ui-btn-left">
EOF
	} else {
		$output .= <<EOF;
                <a data-role="button" data-rel="back" data-transition="slide" href="#page1"
                data-icon="arrow-l" data-iconpos="left" class="ui-btn-left">
                    Back
EOF
	}
	$output .= <<EOF;
                </a>
                    
                </a>
                <h3>
                    $title
                </h3>
            </div>
            <div data-role="content">
                <ul data-role="listview" data-divider-theme="b" data-inset="true">
$html_group_list
                </ul>
                <ul data-role="listview" data-divider-theme="b" data-inset="true">
$html_group_list_no_act
                </ul>
                <div data-role="collapsible-set" data-theme="d" data-content-theme="b">
$html_item_list
                </div>
            </div>
$footer
        </div>
$html_group
EOF
	return $output;
}

sub mobile_log {
    my ($log, $lines) = @_;
    $lines = 10 if (!$lines or $lines == 0);
    my @entries;
    my $html = "";
    if ($log eq "Speech") {
        @entries = &main::speak_log_last($lines);
    }elsif ($log eq "Display") {
        @entries = &main::display_log_last($lines);
    }elsif ($log eq "Print") {
        @entries = &main::print_log_last($lines);
    }elsif ($log eq "Error") {
        @entries = &main::error_log_last($lines);
    }
    for my $l (@entries) {
        ##Put Date and Time on Top Line and Bracketed Stuff to right
        $l =~ s/(\d\d\/\d\d\/\d\d\d\d \d\d:\d\d:\d\d)  (\[.{1,30}\])?/<p>$1 <span style="float: right;">$2<\/span><\/p>\n<p>/ig;
        $l =~ s/(WARN)/<strong>WARN<\/strong>/g;
        $html .= <<EOF;
                    <li data-theme="c">
                            <p>
                            $l
                            </p>
                    </li>
EOF
    }
    my $footer = &mobile_footer;
    $html = <<EOF;
        <div data-role="page" id="Print_Log">
            <div data-theme="a" data-role="header">
                <a data-role="button" data-rel="back" data-transition="slide" href="#page1"
                data-icon="arrow-l" data-iconpos="left" class="ui-btn-left">
                    Back
                </a>
                <h3>
                    Print Log
                </h3>
            </div>
            <div data-role="content">
                <ul data-role="listview" data-divider-theme="b" data-inset="true">
$html
                </ul>
            </div>
$footer
        </div>
EOF
    return $html;
}

sub mobile_footer {
    return <<EOF;
              <div data-theme="a" data-role="footer" data-position="fixed">
                <div data-role="navbar" data-iconpos="none">
                    <ul>
                        <li>
                            <a href="/iphone/#page_Main" data-transition="slide" rel="external">
                                Main
                            </a>
                        </li>
                        <li>
                            <a href="#" data-transition="slide">
                                Fav.
                            </a>
                        </li>
                        <li>
                            <a href="#" data-transition="slide">
                                Settings
                            </a>
                        </li>
                        <li>
                            <a href="/iphone/#page_Logs" data-transition="slide" rel="external">
                                Log
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
EOF
}

sub mobile_menu {
    my ($menu_group, $menu) = @_;
    ($menu_group, $menu) = split ',', $menu_group unless defined $menu;

    ($menu_group) = &get_menu_default('default') unless $menu_group;
    $menu       = $Menus{$menu_group}{_menu_list}[0] unless $menu;
    $menu       = 'Top' unless $menu;

    my $html = "";
    my $item = 0;
    my $ptr = $Menus{$menu_group};

    for my $ptr2 (@{$$ptr{$menu}{items}}) {
        my $goto = $$ptr2{goto};
                                # Action item
        if ($$ptr2{A}) {
                                # Multiple states
            if ($$ptr2{Dstates}) {
                $html .= "$$ptr2{Dprefix}\n";  #This is the item
                my $state = 0;
                for my $state_name (@{$$ptr2{Dstates}}) {
                    $html .= "      <a href='/sub?menu_run($menu_group,$menu,$item,$state,h)'>$state_name</a>, \n";  #each voice cmd
                    $state++;
                }
                $html .= "    $$ptr2{Dsuffix}\n";
            }
                                # One state
            else {
                $html .= "    <li><a href='/sub?menu_run($menu_group,$menu,$item,,h)'>$$ptr2{D}</a>\n";
            }
        }
        elsif ($$ptr2{R}) {
            $html .= "    <li><a href='/sub?menu_run($menu_group,$menu,$item,,h)'>$$ptr2{D}</a>\n";
        }

                                # Menu item
        else {
            $html .= "    <li><a href='/sub?menu_html($menu_group,$goto)'>$goto</a>\n";
        }
        $item++;
    }
    return &html_page($menu, $html);
}

sub mobile_css_mtime {
    return (stat($config_parms{html_alias_iphone} . '/my.css'))[9];
}

sub mobile_js_mtime {
    return (stat($config_parms{html_alias_iphone} . '/my.js'))[9];
}