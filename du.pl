#!/usr/bin/perl -w

###############################################################################
#
#	File:			disk_usage.pl
#
#	Function:		
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

#Unbuffers output- good for nph-scripts
$| = 1;
use strict; 
# the syntax is : ./disk_usage.pl [directory] -t=[threshold value]  

my $output;
my ($list, @total_list);
my $dir = $ARGV[0];
my $threshold = 0;
my $subtotal = 0;
my $total = 0;

#clear the screen for readability
system "clear";

#exit program if they don't enter a [valid] directory
if (!$dir) { print "You need to supply a directory before we can process the folders\n"; exit; }
if (!-d $dir) { print "\"$dir\" is not a valid directory - check to make sure it exists\n"; exit; }

#if ($dir !~ /\/$/) { print "pre-dir manip: $dir\n"; $dir =~ s/(.+)/$1\//; print "post-dir manip: $dir\n"; exit; }
#this adds a trailing slash - needed for du -ks later on...
if ($dir !~ /\/$/) {  $dir =~ s/(.+)/$1\//; }

#add threshold values if -t argument exists - otherwise use initialized value up top
if ($ARGV[1]) 
{  
	$threshold = $ARGV[1];
	$threshold =~ s/-t=(.+)/$1/;
	print "Checking for values >= " .$threshold."MB\n";
}

#process the header
$total_list[0] = $dir;
&process_list(\@total_list,$total,"header");
@total_list = ();

#first get a list of all files for the specified directory
$output = &command_line("ls","-1F",$dir);
$list = &parse_list($output);

#then get the subtotal for any files that exceed the threshold value
foreach (@$list) 
{
	$output = &command_line("du", "-ks" , "\"" . $dir .  $_ . "\"");
	my $list2 = &parse_list($output);
	
	$subtotal = &process_list($list2,$subtotal,"");
}

#process the subtotal (only if threshold specified)
$total_list[0] = $dir;
&process_list(\@total_list,$subtotal,"subtotal");

@total_list = ();

#then get the grand total for the entire directory
$output = &command_line("du", "-ks" , "\"" . $dir . "\"");
push(@total_list,$output);
$total = &process_list(\@total_list,$total,"total");

print "\n\n\n";

exit;

###############################################################################
# 
#	SUBS
#
###############################################################################

sub command_line
{
	my ($command, $argument, $parameter) = @_;
	my $system;

	$system = `$command $argument $parameter`;

	return $system;
}

sub parse_list
{
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

sub process_list
{
	my ($list, $total, $type) = @_;
	my ($name, $size);

######################## FORMATS #############################################
#

format HEADER = 
                                 SIZE
Path/Filename                                                      Size (in MB)	 
-------------------------------------------------------------------------------
.

format ITEMS = 
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<@>>>>>>>>>>>>>>
$name,                                                         $size
.

format FOOTER =
-------------------------------------------------------------------------------
.
#                                                                       
##############################################################################



	foreach (@$list)
	{
		#extract the byte count and file/dir name from the list
		if ($_ =~ /^(\d+)\s+(.+)/) 
		{ 
			$size = $1;
			$name = $2;
			#format the output to 2 decimals - print only if threshold exceeded
			$size = sprintf("%.2f", ($size/1024));  
			if ($type eq "total") 
			{
				&setHandle("FOOTER");
				write;
				&setHandle("ITEMS");
				$name = "Total for directory -> " . $name;
				write;
			}
			elsif ($size >= $threshold) 
			{ 
				&setHandle("ITEMS");
				write;
				#print $name ." => " . $size . "MB\n"; 
				$total += $size;
			}
		}
		elsif ($type eq "subtotal" && $threshold > 0)
		{
			$size = $total;
			$name = $_;
			#print "$size $name";exit;
			&setHandle("FOOTER");
			write;
			&setHandle("ITEMS");
			$name = "Total for search -> " . $name . " >= $threshold MB: ";
			write;
		}
		elsif ($type eq "header")
		{
			&setHandle("HEADER");
			write;
		}
	}
	
	return $total;
	
}

sub setHandle
{
	my $handle = shift;

	my $oldhandle = select STDOUT;
	$~ = $handle;
	select ($oldhandle);	
}