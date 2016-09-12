#!/usr/bin/perl

use strict;
use Getopt::Long;
use Cwd;

########
# ABOUT
########
# This script wraps calling the DKFZ Roddy workflow.
# It reads param line options, which are easier to deal with in CWL, then
# creates an INI file, and, finally, executes the workflow.

my @files;
my ($run_id, $normal_bam, $tumor_bam, $bedpe, $reference);
my $cwd = cwd();

# workflow version
my $wfversion = "2.0.0";

GetOptions (
  "run-id=s"   => \$run_id,
  "normal-bam=s" => \$normal_bam,
  "tumor-bam=s" => \$tumor_bam,
  "delly-bedpe=s" => \$bedpe,
  "reference-gz=s" => \$reference,
)
# TODO: need to add all the new params, then symlink the ref files to the right place
 or die("Error in command line arguments\n");

# PARSE OPTIONS
system("sudo chmod a+rwx /tmp");


print "Current working directory is: $cwd\n";
my $pwd = `pwd`;
print "Present working directory is: $pwd\n";

# SYMLINK REF FILES
run("mkdir -p /data/datastore/normal");
run("mkdir -p /data/datastore/tumor/");
run("mkdir -p /data/datastore/delly/");
run("ln -s $normal_bam /data/datastore/normal/normal.bam");
run("samtools index /data/datastore/normal/normal.bam");
run("ln -s $tumor_bam /data/datastore/tumor/tumor.bam");
run("samtools index /data/datastore/tumor/tumor.bam");
run("ln -s $bedpe /data/datastore/delly/delly.bedpe.txt");
run("mkdir -p /mnt/datastore/workflow_data/");
run("mkdir -p \$TMPDIR/reference");
# make sure we have permissions on these volumes
run("sudo chmod -R a+wrx /reference");
run("cd \$TMPDIR/reference && tar zxf $reference");
run("mkdir -p /mnt/datastore/ && ln -s \$TMPDIR/reference/bundledFiles /mnt/datastore/");
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
date=20160520
END

open OUT, ">/mnt/datastore/workflow_data/workflow.ini" or die;
print OUT $config;
close OUT;

# NOW RUN WORKFLOW
my $error = system("/bin/bash -c '/roddy/bin/runwrapper.sh'");

# MOVE THESE TO THE RIGHT PLACE
print "Current working directory is: $cwd\n";
system("mv /mnt/datastore/resultdata/* $cwd");
$pwd = `pwd`;
print "Present working directory is: $pwd\n";
my $resultData = `ls $cwd`;
print "Result directory listing is: $resultData\n";


# RETURN RESULT
exit($error);

sub run {
  my $cmd = shift;
  print "RUNNING CMD: $cmd\n";
  my $error = system($cmd);
  if ($error) { exit($error); }
}
