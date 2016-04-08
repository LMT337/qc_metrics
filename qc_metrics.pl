#!/user/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Long;

my ($file, $out, $field);
my %sample;
my %fields;
my (@results, @header);
my $DELIM = "\t";
my @gms_header = ( 'subject.name', 'model.name', 'date_completed','model.last_succeeded_build.merged_alignment_result.bam_file', 'status' );    
GetOptions(
    "file:s" => \$file, 
    "out:s" => \$out,
    "fields:s" => \$field,
) or die ("Error in command arguments");

if ($field){
    my @tmp = split(/,/, $field);
    push(@header, 'build_id');
        foreach my $k (@tmp){
            push(@header, "$k");
        }
}else{
    @header = ( 'build_id', 'ALIGNED_READS', 'DUPLICATION_RATE', 'HAPLOID_COVERAGE', 'PF_ALIGNED_BASES', 'MEAN_TARGET_COVERAGE', 'PCT_TARGET_BASES_20X', 'PCT_USABLE_BASES_ON_TARGET', 'TARGET_TERRITORY', 'instrument_data_count', 'instrument_data_ids' );
}
open(FILE, $file);
open(WRITE, '>', $out);

my $first = 1;

print WRITE (join($DELIM, @header)."\n");

while(<FILE>){
	# Issue #1 starts here
    chomp;
    my $info = $_;
    $info =~ s/^\s+//;

    if ($info =~ /^---/){
    	if ($first){
    		$first = 0;
    		next;
    	}
        print_row(\%fields);
        %fields = ();
    }else{
        my ($k, $v) = split(': ', $info);
        $v =~ s/(^\s+)|([\s:]+$)//g;
        $fields{$k} = $v;
    }
}

close FILE;
close WRITE;

exit;

my $gms_succ = 'gms_succeeded_'.$out;
my $gms_fail = 'gms_fail_'.$out;
my $gms_cmds = 'gms_cmds_'.$out;

open(GMS, $out);
open(SUCC, '>', $gms_succ);
open(FAIL, '>', $gms_fail);
open(CMDS, '>', $gms_cmds);

my $header = <GMS>;
print SUCC (join($DELIM, @header, @gms_header)."\n");
print FAIL (join($DELIM, @header, @gms_header)."\n");

my %hash;

while(<GMS>){
    chomp;
    my @data = split("\t");
    my $bid = $data[0];

    if ($bid){
    
    my $cmd = "genome model build list id=$bid --show subject.name,model.name,date_completed,model.last_succeeded_build.merged_alignment_result.bam_file,status --noheaders --style=tsv";
    print CMDS "$cmd\n";
    my @gms = `$cmd`;
    $hash{$bid} =  [ join("\t", @data, @gms) ];
#    print OUT "$result";
    }
}    


foreach my $k (sort keys %hash){
    foreach my $y (@{$hash{$k}}){
        if ($y =~ /Succeeded/){
        print SUCC "$y";
        }else{
        print FAIL "$y";
        }
    }
}


close GMS;
close CMDS;
close SUCC;
close FAIL;

exit;

sub print_row{
    my $h = shift;
    my @out = map( $h -> {$_}, @header );
    print WRITE ( join( $DELIM, @out)."\n");    
}

