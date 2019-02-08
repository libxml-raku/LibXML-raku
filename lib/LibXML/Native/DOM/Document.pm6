unit role LibXML::Native::DOM::Document;

use LibXML::Native::DOM::Node;

my constant Node = LibXML::Native::DOM::Node;

use LibXML::Enums;
use NativeCall;

method GetRootElement  { ... }
method SetRootElement  { ... }

method documentElement is rw {
    Proxy.new(
        FETCH => sub ($) { self.GetRootElement },
        STORE => sub ($, Node $e) {
            self.removeChild($_) with self.GetRootElement;
            self.SetRootElement($e);
        });
}
