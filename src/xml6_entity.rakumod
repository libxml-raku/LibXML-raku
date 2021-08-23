## untested. Just for fun
use NativeCall;
use LibXML::Enums;
use LibXML::Raw;
use LibXML::Raw::Defs :xmlCharP;

sub xml6_warn($) {...}
sub xmlMalloc($, $) {...}
sub xmlStrlen($, $) {...}
sub xmlStrndup($,$) {...}

sub xml6_entity_create(xmlCharP $name, int32 $type,
                   xmlCharP $ExternalID, xmlCharP $SystemID,
                   xmlCharP $content --> xmlEntity) {
    my xmlEntity $rv;

    $rv = xmlMalloc(nativesizeof(xmlEntity)) // do {
        xml6_warn("xml6_entity_create: malloc failed");
	return(xmlEntity);
    }
    xmlEntity.memset;
    $rv.type = XML_ENTITY_DECL;
    $rv.checked = 0;

    #
    # fill the structure.
    #
    $rv.etype = $type;
    $rv.name .= &xmlStrdup;
    $rv.ExternalID = xmlStrdup($_)
       with $ExternalID;
    $rv.SystemID = xmlStrdup($_)
       with $SystemID;

    with $content {
        $rv.length = .&xmlStrlen;
        $rv.content = .&xmlStrndup($rv.length);
     } else {
        $rv.length = 0;
        $rv.content = Nil;
    }

    $rv.URI = Nil;
    $rv.orig = Nil;
    $rv.owner = 0;

    $rv;
}
