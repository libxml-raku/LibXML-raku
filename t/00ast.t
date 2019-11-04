use Test;
use LibXML;
use LibXML::Document;
my LibXML::Document $doc .= parse: :file<example/dromeds.xml>;
is-deeply $doc.ast, "#document"
                        => [
                            :dromedaries[
                                     :species[:name<Camel>, :humps["1 or 2"], :disposition["Cranky"]],
                                     :species[:name<Llama>, :humps["1 (sort of)"], :disposition["Aloof"]],
                                     :species[:name<Alpaca>, :humps["(see Llama)"], :disposition["Friendly"]]
                                 ]
                        ];

$doc .= parse: :file<example/ns.xml>;
is-deeply $doc.ast, "#document"
                        => [
                            :dromedaries[
                                     :xmlns("urn:camels"),
                                     "xmlns:mam" => "urn:mammals",
                                     :species["Camelid"],
                                     "mam:legs" => ["xmlns:a" => "urn:a",
                                                    "xml:lang" => "en",
                                                    :yyy("zzz"),
                                                    "a:xxx" => "foo", "4"]
                                 ]
                        ];
done-testing;
