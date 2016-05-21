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
  "reference=s" => \$reference,
)
# TODO: need to add all the new params, then symlink the ref files to the right place
 or die("Error in command line arguments\n");

# PARSE OPTIONS
system("sudo chmod a+rwx /tmp");

# SYMLINK REF FILES
run("mkdir -p /data/datastore/normal");
run("mkdir -p /data/datastore/tumor/");
run("mkdir -p /data/datastore/delly/");
run("ln -s $normal_bam /data/datastore/normal/");
run("samtools index /data/datastore/normal/normal.bam");
run("ln -s $tumor_bam /data/datastore/tumor/");
run("samtools index /data/datastore/tumor/tumor.bam");
run("ln -s $bedpe /data/datastore/delly/delly.bedpe.txt");
run("mkdir -p /mnt/datastore/workflow_data/");
run("mkdir -p $cwd/reference");
run("cd $cwd/reference && tar zxf $reference");
run("mkdir -p /mnt/datastore/ && ln -s $cwd/reference/bundledFiles /mnt/datastore/");

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

# NOW FIND OUTPUT
#my $path = `ls -1t /datastore/ | grep 'oozie-' | head -1`;
#chomp $path;

# MOVE THESE TO THE RIGHT PLACE
#system("mv /datastore/$path/*.vcf.gz /datastore/$path/*.bedpe.txt /datastore/$path/delly_results/*.sv.cov.tar.gz /datastore/$path/delly_results/*.sv.cov.plots.tar.gz /datastore/$path/*.sv.log.tar.gz /datastore/$path/*.json $cwd");

# RETURN RESULT
#exit($error);
exit(0);

sub run {
  my $cmd = shift;
  my $error = system($cmd);
  if ($error) { exit($error); }
}
