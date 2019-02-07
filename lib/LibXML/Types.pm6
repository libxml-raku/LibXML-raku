unit module LibXML::Types;

subset QName of Str is export(:QName) where /^[<ident>+ % <[-.]>]**1..2 % ':'$/;
