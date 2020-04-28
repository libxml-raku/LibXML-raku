constant DocRoot = "https://libxml-raku.github.io/LibXML-raku";

sub map-link(Str() $link) {
    DocRoot ~ $link.substr(6).subst('::', '/', :g);
}

s:g/("](")("LibXML"<- [)]>*)(")")/{$0 ~ map-link($1) ~ $2}/;
