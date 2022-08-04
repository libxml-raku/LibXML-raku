use v6.d;
unit role LibXML::_Rawish[::RawType, *@handles];

# Pre-cache attribute object. Since role body is invoked for each role consumption we'd have
# exactly one copy per class.
my $attr := ::?CLASS.^attributes.grep('$!raw').head;

# Similarly, pre-cache attribute value. This makes sense **only** if immutability of $.raw is guaranteed.
has RawType $!_raw = $attr.get_value(self);

# We cannot apply `handles` directly on _raw because @handles are not known at compile time.
# But we can take advantage of the fact that role body is executed when role is getting specialized.

for @handles -> $handles {
    my &delegate = anon method (|c) is raw is hidden-from-backtrace {
        (self.defined ?? $!_raw !! RawType)."$handles"(|c)
    }
    &delegate.set_name($handles);
    ::?CLASS.^add_method($handles, &delegate);
}

# Ensure that .raw on each LibXML::Node descendant class reports the right raw type
multi method raw(::?CLASS:U:) { RawType }