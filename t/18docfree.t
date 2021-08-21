use v6;
use Test;

use LibXML;

plan 1;
for 1 .. 1000 {
  my LibXML::Document $doc .= new();
  $doc.documentElement = $doc.createElement("node" ~ $_);
  $doc .= new;
}
pass 'doc new/free sanity';

