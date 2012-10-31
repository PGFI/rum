package RUM::Script::RemoveDups;

no warnings;

use base 'RUM::Script::Base';

our $log = RUM::Logging->get_logger();
$|=1;

sub summary {
    'Remove duplicates from a RUM non-unique mapper file.'
}

sub description {
    'This was made for the RUM NU file which accrued some duplicates along its way through the pipeline.'
}

sub accepted_options {
    return (
        RUM::CommonProperties->non_unique_out->set_required,
        RUM::CommonProperties->unique_out->set_required,
        RUM::Property->new(
            opt => 'input',
            desc => 'input file. Should be RUM_NU file',
            required => 1,
            positional => 1,
            required => 1
        )
    );
}

sub run {
    my ($self) = @_;
    my $props = $self->properties;
    my $outfile  = $props->get('non_unique_out');
    my $outfileu = $props->get('unique_out');
    my $infile   = $props->get('input');

    open RUMNU, $infile;
    $flag = 0;
    $entry = "";
    $seqnum = 1;
    open OUTFILE, ">", $outfile;
    open OUTFILEU, ">>", $outfileu;
    while ($flag == 0) {
        $line = <RUMNU>;
        chomp($line);
        $type = "";
        $line =~ /seq.(\d+)(.)/;
        $sn = $1;
        $type = $2;
        if ($sn == $seqnum && $type eq "a") {
            if ($entry eq '') {
                $entry = $line;
            } else {
                $hash{$entry} = 1;
                $entry = $line;
            }
        }
        if ($sn == $seqnum && $type eq "b") {
            if ($entry =~ /a/) {
                $entry = $entry . "\n" . $line;
            } else {
                $entry = $line; # a line with 'b' never follows a merged of the same id, 
                # otherwise this would wax the merged...
            }
            $hash{$entry} = 1;
            $entry = '';
        }
        if ($sn == $seqnum && $type eq "\t") {
            if ($entry eq '') {
                $entry = $line;
                $hash{$entry} = 1;
                $entry = '';
            } else {
                $hash{$entry} = 1;
                $entry = $line;
            }
        }
        if ($sn > $seqnum || $line eq '') {
            $len = -1 * (1 + length($line));
            seek(RUMNU, $len, 1);
            $hash{$entry} = 1;
            $cnt=0;
            foreach $key (keys %hash) {
                if ($key =~ /\S/) {
                    $cnt++;
                }	    
            }
            foreach $key (keys %hash) {
                if ($key =~ /\S/) {
                    chomp($key);
                    $key =~ s/^\s*//s;
                    if ($cnt == 1) {
                        print OUTFILEU "$key\n";
                    } else {
                        print OUTFILE "$key\n";
                    }
                }
            }
            undef %hash;
            $seqnum = $sn;
            $entry = '';
        }
        if ($line eq '') {
            $flag = 1;
        }
    }
    close(OUTFILE);
    close(OUTFILEU);
    return 0;
}
