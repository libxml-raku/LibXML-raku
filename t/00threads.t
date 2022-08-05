use Test;
plan 1;
use LibXML::Config;
use LibXML::Element;
use LibXML::Raw;

LibXML::Config.use-global;

# low level threading tests

INIT my \MAX_THREADS = %*ENV<MAX_THREADS> || 10;
INIT my \MAX_LOOP = %*ENV<MAX_LOOP> || 50;

sub blat(&r, :$n = MAX_THREADS) {
    (^$n).race(:batch(1)).map(&r);
}

sub trundle(&r, :$n = MAX_THREADS) {
    (^$n).map(&r);
}

unless LibXML::Config.have-threads {
    skip-rest 'This libxml library does not have threading enabled';
    exit 0;
}

subtest 'configs', {
    my @configs = (^MAX_THREADS).map: {LibXML::Config.new};

    {
        my $passing = True;
        for (^MAX_LOOP) -> $i {
            my @ok = blat(
                -> $j {
                    given @configs[$j] {
                        .tag-expansion = ($i + $j + 1) %% 2;
                        # do a little work
                        my LibXML::Element $e .= new('elem' ~ $i ~ '_' ~ $j);
                        .tag-expansion == ($i + $j + 1) %% 2;
                    }
                }
            );
            $passing = False unless @ok.all.so;
        }
        ok $passing, 'tag expansion gobal';
    }       

    {
        my $passing = True;
        for (^MAX_LOOP) -> $i {
            my @ok = blat(
                -> $j {
                    given @configs[$j] {
                        .keep-blanks = ($i + $j + 1) %% 2;
                        # do a little work
                        my LibXML::Element $e .= new('elem' ~ $i ~ '_' ~ $j);
                        .keep-blanks == ($i + $j + 1) %% 2;
                    }
                }
            );
            $passing = False unless @ok.all.so;
        }
        ok $passing, 'keep blanks gobal';
    }       


    {
        my $passing = True;
        my $max-errors = @configs.map(*.max-errors).sum;
        for (^MAX_LOOP) -> $i {
            my @ok = blat(
                -> $j {
                    given @configs[$j] {
                        .skip-xml-declaration = ($i + $j) %% 2;
                        .tag-expansion = ($i + $j + 1) %% 2;
                        .max-errors += $j + .skip-xml-declaration + .tag-expansion;
                        .skip-xml-declaration !== .tag-expansion;
                    }
                }
            );
            $passing = False unless @ok.all.so;
        }
        ok $passing, 'tag-expansion vs skip-xml-declaration';

        my $total = @configs.map({.max-errors}).sum;
        is $total, $max-errors + MAX_LOOP * (MAX_THREADS * (MAX_THREADS+1) div 2);
    }

}
