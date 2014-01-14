#!/usr/bin/perl -w

##############################################################################
#
#	File:			disk_usage.pl
#
#	Function:		Traverse a Directory and get the disk usage of 
#					items in the folder(s)
#					additional functionality : 
#						threshold (only show items > threshold val)
#						recurse from initial directory to show grand-total 
#						(TODO)
#
# 					the syntax is : 
#					./du.pl [directory] -t=[threshold value]  -r
#
#	Author(s):		Michael Jelks
#
#	Copyright:		Copyright (c) 2003 Michael Jelks
#					All Rights Reserved.
#
#	Source:			Started anew.
#
#	Notes:			
#
#	Change History:
#			10/15/03	Started source
#			
#	
##############################################################################
use strict; 

#Unbuffers output- good for nph-scripts
$| = 1;

my $output;
my @total_list;
my $dir = $ARGV[0];
my $threshold = 0;
my $subtotal = 0;
my $total = 0;

#clear the screen for readability
system "clear";

#exit program if they don't enter a [valid] directory
if (!$dir) { 
	print "You need to supply a directory before we can process the folders\n"; 
	exit; }

if (!-d $dir) {
	print "\"$dir\" is not a valid directory - check to make sure it exists\n"; 
	exit; }

#this adds a trailing slash - needed for du -ks later on...
if ($dir !~ /\/$/) {
	$dir =~ s/(.+)/$1\//; }

# add threshold values if -t argument exists - 
# otherwise use initialized value up top
if ($ARGV[1]) {  
	$threshold = $ARGV[1];
	$threshold =~ s/-t=(.+)/$1/;
	print "Checking for values >= " .$threshold."MB\n"; }

&process_header;
&process_directory($dir, \$subtotal);

# init the process by priming the @total_list array 
# with the $dir input via ARGV
$total_list[0] = $dir;
&process_list(\@total_list,$subtotal,"subtotal");

#then get the grand total for the entire directory
@total_list = ();
$output = &command_line("du", "-ks" , "\"" . $dir . "\"");
push(@total_list,$output);
$total = &process_list(\@total_list,$total,"total");

print "\n\n\n";

exit;

##############################################################################
# 
#	SUBS
#
##############################################################################

sub command_line {
	my ($command, $argument, $parameter) = @_;
	my $system;

	$system = `$command $argument $parameter`;

	return $system;
}

sub process_directory {
	my ($dir, $subtotal) = @_;
	#first get a list of all files for the specified directory
	my $output = &command_line("ls","-1F",$dir);
	my $list = &parse_list($output);
	my $list_tmp;

	#then get the subtotal for any files that exceed the threshold value
	foreach my $item (@$list) {
		$output = &command_line("du", "-ks" , "\"" . $dir .  $item . "\"");
		$list_tmp = &parse_list($output);
		$subtotal = &process_list($list_tmp,$subtotal,"");
	}
}

sub parse_list {
	my $output = shift;
	my (@list,@new_list);
	my $listing;

	@list = split(/\n/,$output);		
		
	foreach $listing (@list)
	{
		# if it's not a symlink - push into new array
		if ($listing !~ /.+\@$/) 
		{
			#remove any funny stuff at the end - * / etc. 
			$listing =~ s/(.+)\W$/$1/; 
			push (@new_list, $listing); 
		} 
	}
	#sort file listing case-insensitve - gives human alphabetical order...
	@new_list = sort {lc($a) cmp lc($b)} @new_list;
	return \@new_list;
}

sub process_list {
	my ($list, $total, $type) = @_;
	my ($item, $name, $size);

	foreach $item (@$list)
	{
		#extract the byte count and file/dir name from the list
		if ($item =~ /^(\d+)\s+(.+)/) 
		{ 
			$size = $1;
			$name = $2;
			#format the output to 2 decimals - print only if threshold exceeded
			$size = sprintf("%.2f", ($size/1024));
			if ($type eq "total") 
			{
				&process_footer;
				$name = "Total for directory -> " . $name;
				&process_items($name, $size);
			}
			elsif ($size >= $threshold) 
			{ 
				&process_items($name, $size);
				$total += $size;
			}
		}
	}
	
	return $total;
	
}

## FORMATTING PERL CONSTRUCTS ##
sub process_header {
format HEADER = 
                                 SIZE
Path/Filename                                                     Size (in MB)	 
------------------------------------------------------------------------------
.
	&setHandle("HEADER");
	write;
}

sub process_footer {
format FOOTER =
-------------------------------------------------------------------------------
.
	&setHandle("FOOTER");
	write;
}

sub process_items {
	my ($name, $size) = @_;
format ITEMS = 
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<@>>>>>>>>>>>>>>
$name,                                                         $size
.
	&setHandle("ITEMS");
	write;
}

## PERL FORMATTING MAGIC ##
sub setHandle {
	my $handle = shift;
	my $oldhandle = select STDOUT;
	
	$~ = $handle;
	select ($oldhandle);	
}