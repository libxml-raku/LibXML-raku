SRC=src
TRAVIS=https://travis-ci.org/p6-xml/LibXML-raku

all : lib

lib : resources/libraries/libxml6.so

# 'all', with compilation warnings and debug symbols enabled
debug :
	make "DBG=-Wall -g"  all

resources/libraries/libxml6.so : $(SRC)/dom.o $(SRC)/domXPath.o $(SRC)/xml6_parser_ctx.o  $(SRC)/xml6_config.o $(SRC)/xml6_doc.o $(SRC)/xml6_entity.o $(SRC)/xml6_gbl.o $(SRC)/xml6_input.o $(SRC)/xml6_node.o $(SRC)/xml6_ns.o $(SRC)/xml6_sax.o $(SRC)/xml6_ref.o  $(SRC)/xml6_reader.o $(SRC)/xml6_xpath.o
	gcc -shared -fPIC  -O3  -Wl,-rpath,"//home/david/git/rakudo/install/lib" -o resources/libraries/libxml6.so \
        $(SRC)/dom.o  $(SRC)/domXPath.o $(SRC)/xml6_parser_ctx.o $(SRC)/xml6_config.o $(SRC)/xml6_doc.o $(SRC)/xml6_entity.o $(SRC)/xml6_gbl.o $(SRC)/xml6_input.o $(SRC)/xml6_node.o $(SRC)/xml6_ns.o $(SRC)/xml6_sax.o $(SRC)/xml6_ref.o  $(SRC)/xml6_reader.o $(SRC)/xml6_xpath.o \
        -lxml2 

$(SRC)/dom.o : $(SRC)/dom.c $(SRC)/dom.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/dom.o $(SRC)/dom.c -I/usr/include/libxml2 $(DBG)

$(SRC)/domXPath.o : $(SRC)/domXPath.c $(SRC)/domXPath.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/domXPath.o $(SRC)/domXPath.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_parser_ctx.o : $(SRC)/xml6_parser_ctx.c $(SRC)/xml6_parser_ctx.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_parser_ctx.o $(SRC)/xml6_parser_ctx.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_config.o : $(SRC)/xml6_config.c $(SRC)/xml6_config.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_config.o $(SRC)/xml6_config.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_doc.o : $(SRC)/xml6_doc.c $(SRC)/xml6_doc.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_doc.o $(SRC)/xml6_doc.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_entity.o : $(SRC)/xml6_entity.c $(SRC)/xml6_entity.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_entity.o $(SRC)/xml6_entity.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_gbl.o : $(SRC)/xml6_gbl.c $(SRC)/xml6_gbl.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_gbl.o $(SRC)/xml6_gbl.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_input.o : $(SRC)/xml6_input.c $(SRC)/xml6_input.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_input.o $(SRC)/xml6_input.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_node.o : $(SRC)/xml6_node.c $(SRC)/xml6_node.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_node.o $(SRC)/xml6_node.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_ns.o : $(SRC)/xml6_ns.c $(SRC)/xml6_ns.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_ns.o $(SRC)/xml6_ns.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_sax.o : $(SRC)/xml6_sax.c $(SRC)/xml6_sax.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_sax.o $(SRC)/xml6_sax.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_ref.o : $(SRC)/xml6_ref.c $(SRC)/xml6_ref.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_ref.o $(SRC)/xml6_ref.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_reader.o : $(SRC)/xml6_reader.c $(SRC)/xml6_reader.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_reader.o $(SRC)/xml6_reader.c -I/usr/include/libxml2 $(DBG)

$(SRC)/xml6_xpath.o : $(SRC)/xml6_xpath.c $(SRC)/xml6_xpath.h
	gcc -I $(SRC) -c -fPIC -Wextra -Wall -Wno-unused-parameter -Wno-unused-function -Wno-missing-braces -Werror=pointer-arith -O3   -D_REENTRANT -D_FILE_OFFSET_BITS=64 -fPIC -DMVM_HEAPSNAPSHOT_FORMAT=2 -o $(SRC)/xml6_xpath.o $(SRC)/xml6_xpath.c -I/usr/include/libxml2 $(DBG)

test : all
	@prove -e"perl6 -I ." t

loudtest : all
	@prove -e"perl6 -I ." -v t

xtest : all
	@prove -e"perl6 -I ." -r t xt

clean :
	@rm -f $(SRC)/xml6_*.o $(SRC)/dom.o $(SRC)/domXPath.o resources/libraries/*libxml6.so

realclean : clean
	@rm -f README.md Makefile docs/*.md docs/*/*.md

doc : README.md docs/Attr.md docs/Attr/Map.md docs/CDATA.md docs/Comment.md docs/Config.md docs/Document.md docs/DocumentFragment.md\
      docs/Dtd.md docs/Element.md docs/ErrorHandling.md docs/InputCallback.md docs/Item.md docs/Namespace.md docs/Native.md\
      docs/Node.md docs/Node/List.md docs/Node/Set.md docs/PI.md docs/RelaxNG.md docs/Text.md docs/Pattern.md\
      docs/Parser.md docs/PushParser.md docs/RegExp.md docs/Reader.md docs/Schema.md docs/XPath/Context.md docs/XPath/Expression.md

README.md : lib/LibXML.rakumod
	(\
	    echo '[![Build Status]($(TRAVIS).svg?branch=master)]($(TRAVIS))'; \
            echo '';\
            perl6 -I . --doc=Markdown lib/LibXML.rakumod \
            | raku -p -n etc/resolve-links.raku \
        ) | tee docs/index.md > README.md

docs/%.md : lib/LibXML/%.rakumod
	raku -I . --doc=Markdown $< \
	| raku -p -n etc/resolve-links.raku \
        > $@

docs/Attr.md : lib/LibXML/Attr.rakumod

docs/Attr/Map.md : lib/LibXML/Attr/Map.rakumod

docs/Comment.md : lib/LibXML/Comment.rakumod

docs/Config.md : lib/LibXML/Config.rakumod

docs/CDATA.md : lib/LibXML/CDATA.rakumod

docs/Document.md : lib/LibXML/Document.rakumod

docs/DocumentFragment.md : lib/LibXML/DocumentFragment.rakumod

docs/Dtd.md : lib/LibXML/Dtd.rakumod

docs/Element.md : lib/LibXML/Element.rakumod

docs/ErrorHandling.md : lib/LibXML/ErrorHandling.rakumod

docs/InputCallback.md : lib/LibXML/InputCallback.rakumod

docs/Item.md : lib/LibXML/Item.rakumod

docs/Namespace.md : lib/LibXML/Namespace.rakumod

docs/Native.md : lib/LibXML/Native.rakumod

docs/Node.md : lib/LibXML/Node.rakumod

docs/Node/List.md : lib/LibXML/Node/List.rakumod

docs/Node/Set.md : lib/LibXML/Node/Set.rakumod

docs/PI.md : lib/LibXML/PI.rakumod

docs/Parser.md : lib/LibXML/Parser.rakumod

docs/PushParser.md : lib/LibXML/PushParser.rakumod

docs/Pattern.md : lib/LibXML/Pattern.rakumod

docs/RegExp.md : lib/LibXML/RegExp.rakumod

docs/Reader.md : lib/LibXML/Reader.rakumod

docs/Schema.md : lib/LibXML/Schema.rakumod

docs/RelaxNG.md : lib/LibXML/RelaxNG.rakumod

docs/Text.md : lib/LibXML/Text.rakumod

docs/XPath/Context.md : lib/LibXML/XPath/Context.rakumod

docs/XPath/Expression.md : lib/LibXML/XPath/Expression.rakumod
