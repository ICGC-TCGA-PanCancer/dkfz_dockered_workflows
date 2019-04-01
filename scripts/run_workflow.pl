#!/usr/bin/perl

use strict;
use Getopt::Long;
use Time::Piece;
use Capture::Tiny qw(capture);

########
# ABOUT
########
# This script wraps calling the DKFZ Roddy workflow.
# It reads param line options, which are easier to deal with in CWL, then
# creates an INI file, and, finally, executes the workflow.

my @files;
my ($normal_bam, $tumor_bam, $bedpe, $reference, $output_dir, $run_id);
my $date = localtime->strftime('%Y%m%d');


# workflow version
my $wfversion = "2.0.0";

GetOptions (
  "output-dir=s" => \$output_dir,
  "run-id:s"   => \$run_id,
  "normal-bam=s" => \$normal_bam,
  "tumor-bam=s" => \$tumor_bam,
  "delly-bedpe=s" => \$bedpe,
  "reference-gz=s" => \$reference,
)
# TODO: need to add all the new params, then symlink the ref files to the right place
 or die("Error in command line arguments\n");

if ($run_id eq "")
{
  $run_id = get_aliquot_id_from_bam($tumor_bam);
}

if ($run_id =~ /^[a-zA-Z0-9_-]+$/) {
    print "run-id is: $run_id\n";
} else {
    die "Found run-id containing invalid character: $run_id\n";
}

# PARSE OPTIONS
system("sudo chmod a+rwx /tmp");


my $pwd = `pwd`;
print "Present working directory is: $pwd\n";

#check assumptions
run("whoami");
run("env");

# SYMLINK REF FILES
run("mkdir -p /data/datastore/normal");
run("mkdir -p /data/datastore/tumor/");
run("mkdir -p /data/datastore/delly/");
run("ln -sf $normal_bam /data/datastore/normal/normal.bam");
run("ln -sf $normal_bam.bai /data/datastore/normal/normal.bam.bai");
run("ln -sf $tumor_bam /data/datastore/tumor/tumor.bam");
run("ln -sf $tumor_bam.bai /data/datastore/tumor/tumor.bam.bai");
run("ln -sf $bedpe /data/datastore/delly/delly.bedpe.txt");
run("mkdir -p /mnt/datastore/workflow_data/");
run("mkdir -p \$TMPDIR/reference");
# make sure we have permissions on these volumes
run("sudo chmod -R a+wrx /reference");
run("cd \$TMPDIR/reference && tar zxf $reference");
run("mkdir -p /mnt/datastore/ && ln -sf \$TMPDIR/reference/bundledFiles /mnt/datastore/");
run("sudo chmod -R a+wrx /mnt/datastore /data/datastore");
run("mkdir -p /mnt/datastore/resultdata");


# MAKE CONFIG
# the default config is the workflow_local.ini and has most configs ready to go
my $config = <<END;
#!/bin/bash
tumorBams=( /data/datastore/tumor/tumor.bam )
controlBam=/data/datastore/normal/normal.bam
dellyFiles=( /data/datastore/delly/delly.bedpe.txt )
aliquotIDs=( $run_id )
runACEeq=true
runSNVCalling=true
runIndelCalling=true
date=$date
END

open OUT, ">/mnt/datastore/workflow_data/workflow.ini" or die;
print OUT $config;
close OUT;

# NOW RUN WORKFLOW
my $error = system("gosu roddy /bin/bash -c '/roddy/bin/runwrapper.sh'");

# MOVE THESE TO THE RIGHT PLACE FOR PROVISION OUT
system("sudo mv /mnt/datastore/resultdata/* $output_dir");
my $resultData = `ls $output_dir`;
print "Result directory listing is: $resultData\n";


# RETURN RESULT
exit($error);

sub run {
  my $cmd = shift;
  print "RUNNING CMD: $cmd\n";
  my $error = system($cmd);
  if ($error) { exit($error); }
}

sub get_aliquot_id_from_bam {
  my $bam = shift;
  die "BAM file does not exist: $bam" unless ( -e $bam );

  my $command = sprintf q{samtools view -H %s | grep '^@RG'}, $bam;
  my ($stdout, $stderr, $exit) = capture { system($command); };
  die "STDOUT: $stdout\n\nSTDERR: $stderr\n" if ( $exit != 0 );

  my %names;
  for ( split "\n", $stdout ) {
    chomp $_;
    if ( $_ =~ m/\tSM:([^\t]+)/ ) {
      $names{$1} = 1;
    }
    else {
      die "Found RG line with no SM field: $_\n\tfrom: $bam\n";
    }
  }

  my @keys = keys %names;
  die "Multiple different SM entries: ."
    . join( q{,}, @keys )
    . "\n\tfrom: $bam\n"
    if ( scalar @keys > 1 );
  die "No SM entry found in: $bam\n" if ( scalar @keys == 0 );
  return $keys[0];
}