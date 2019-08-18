use v6;
#  -- DO NOT EDIT --
# generated by: etc/generator.p6 

unit module LibXML::Native::Gen::xpath;
# XML Path Language implementation:
#    API for the XML Path Language implementation  XML Path Language implementation XPath is a language for addressing parts of an XML document, designed to be used by both XSLT and XPointer
use LibXML::Native::Defs :LIB, :xmlCharP;

enum xmlXPathError is export (
    XPATH_ENCODING_ERROR => 20,
    XPATH_EXPRESSION_OK => 0,
    XPATH_EXPR_ERROR => 7,
    XPATH_FORBID_VARIABLE_ERROR => 24,
    XPATH_INVALID_ARITY => 12,
    XPATH_INVALID_CHAR_ERROR => 21,
    XPATH_INVALID_CTXT => 22,
    XPATH_INVALID_CTXT_POSITION => 14,
    XPATH_INVALID_CTXT_SIZE => 13,
    XPATH_INVALID_OPERAND => 10,
    XPATH_INVALID_PREDICATE_ERROR => 6,
    XPATH_INVALID_TYPE => 11,
    XPATH_MEMORY_ERROR => 15,
    XPATH_NUMBER_ERROR => 1,
    XPATH_STACK_ERROR => 23,
    XPATH_START_LITERAL_ERROR => 3,
    XPATH_UNCLOSED_ERROR => 8,
    XPATH_UNDEF_PREFIX_ERROR => 19,
    XPATH_UNDEF_VARIABLE_ERROR => 5,
    XPATH_UNFINISHED_LITERAL_ERROR => 2,
    XPATH_UNKNOWN_FUNC_ERROR => 9,
    XPATH_VARIABLE_REF_ERROR => 4,
    XPTR_RESOURCE_ERROR => 17,
    XPTR_SUB_RESOURCE_ERROR => 18,
    XPTR_SYNTAX_ERROR => 16,
)

enum xmlXPathObjectType is export (
    XPATH_BOOLEAN => 2,
    XPATH_LOCATIONSET => 7,
    XPATH_NODESET => 1,
    XPATH_NUMBER => 3,
    XPATH_POINT => 5,
    XPATH_RANGE => 6,
    XPATH_STRING => 4,
    XPATH_UNDEFINED => 0,
    XPATH_USERS => 8,
    XPATH_XSLT_TREE => 9,
)

class xmlNodeSet is repr('CStruct') {
    has int32 $.nodeNr; # number of nodes in the set
    has int32 $.nodeMax; # size of the array as allocated
    has xmlNodePtr * $.nodeTab; # array of nodes in no particular order @@ with_ns to check wether namespace nodes should be looked at @@
    method XPathCastNodeSetToBoolean( --> int32) is native(LIB) is symbol('xmlXPathCastNodeSetToBoolean') {*};
    method XPathCastNodeSetToNumber( --> num64) is native(LIB) is symbol('xmlXPathCastNodeSetToNumber') {*};
    method XPathCastNodeSetToString( --> xmlCharP) is native(LIB) is symbol('xmlXPathCastNodeSetToString') {*};
    method XPathDifference(xmlNodeSet $nodes2 --> xmlNodeSet) is native(LIB) is symbol('xmlXPathDifference') {*};
    method XPathDistinct( --> xmlNodeSet) is native(LIB) is symbol('xmlXPathDistinct') {*};
    method XPathDistinctSorted( --> xmlNodeSet) is native(LIB) is symbol('xmlXPathDistinctSorted') {*};
    method XPathFree() is native(LIB) is symbol('xmlXPathFreeNodeSet') {*};
    method XPathHasSameNodes(xmlNodeSet $nodes2 --> int32) is native(LIB) is symbol('xmlXPathHasSameNodes') {*};
    method XPathIntersection(xmlNodeSet $nodes2 --> xmlNodeSet) is native(LIB) is symbol('xmlXPathIntersection') {*};
    method XPathLeading(xmlNodeSet $nodes2 --> xmlNodeSet) is native(LIB) is symbol('xmlXPathLeading') {*};
    method XPathLeadingSorted(xmlNodeSet $nodes2 --> xmlNodeSet) is native(LIB) is symbol('xmlXPathLeadingSorted') {*};
    method XPathNewNodeSetList( --> xmlXPathObject) is native(LIB) is symbol('xmlXPathNewNodeSetList') {*};
    method XPathNodeLeading(xmlNode $node --> xmlNodeSet) is native(LIB) is symbol('xmlXPathNodeLeading') {*};
    method XPathNodeLeadingSorted(xmlNode $node --> xmlNodeSet) is native(LIB) is symbol('xmlXPathNodeLeadingSorted') {*};
    method XPathNodeSetAdd(xmlNode $val --> int32) is native(LIB) is symbol('xmlXPathNodeSetAdd') {*};
    method XPathNodeSetAddNs(xmlNode $node, xmlNs $ns --> int32) is native(LIB) is symbol('xmlXPathNodeSetAddNs') {*};
    method XPathNodeSetAddUnique(xmlNode $val --> int32) is native(LIB) is symbol('xmlXPathNodeSetAddUnique') {*};
    method XPathNodeSetContains(xmlNode $val --> int32) is native(LIB) is symbol('xmlXPathNodeSetContains') {*};
    method XPathNodeSetDel(xmlNode $val) is native(LIB) is symbol('xmlXPathNodeSetDel') {*};
    method XPathNodeSetMerge(xmlNodeSet $val2 --> xmlNodeSet) is native(LIB) is symbol('xmlXPathNodeSetMerge') {*};
    method XPathNodeSetRemove(int32 $val) is native(LIB) is symbol('xmlXPathNodeSetRemove') {*};
    method XPathNodeSetSort() is native(LIB) is symbol('xmlXPathNodeSetSort') {*};
    method XPathNodeTrailing(xmlNode $node --> xmlNodeSet) is native(LIB) is symbol('xmlXPathNodeTrailing') {*};
    method XPathNodeTrailingSorted(xmlNode $node --> xmlNodeSet) is native(LIB) is symbol('xmlXPathNodeTrailingSorted') {*};
    method XPathTrailing(xmlNodeSet $nodes2 --> xmlNodeSet) is native(LIB) is symbol('xmlXPathTrailing') {*};
    method XPathTrailingSorted(xmlNodeSet $nodes2 --> xmlNodeSet) is native(LIB) is symbol('xmlXPathTrailingSorted') {*};
    method XPathWrap( --> xmlXPathObject) is native(LIB) is symbol('xmlXPathWrapNodeSet') {*};
    method XPtrNewLocationSet( --> xmlXPathObject) is native(LIB) is symbol('xmlXPtrNewLocationSetNodeSet') {*};
}

class xmlXPathAxis is repr('CStruct') {
    has xmlCharP $.name; # the axis name
    has xmlXPathAxisFunc $.func; # the search function
}

class xmlXPathCompExpr is repr('CPointer') {
    sub xmlXPathCompile(xmlCharP $str --> xmlXPathCompExpr) is native(LIB) is export {*};

    method CompiledEval(xmlXPathContext $ctx --> xmlXPathObject) is native(LIB) is symbol('xmlXPathCompiledEval') {*};
    method CompiledEvalToBoolean(xmlXPathContext $ctxt --> int32) is native(LIB) is symbol('xmlXPathCompiledEvalToBoolean') {*};
    method Free() is native(LIB) is symbol('xmlXPathFreeCompExpr') {*};
}

class xmlXPathContext is repr('CStruct') {
    has xmlDoc $.doc; # The current document
    has xmlNode $.node; # The current node
    has int32 $.nb_variables_unused; # unused (hash table)
    has int32 $.max_variables_unused; # unused (hash table)
    has xmlHashTable $.varHash; # Hash table of defined variables
    has int32 $.nb_types; # number of defined types
    has int32 $.max_types; # max number of types
    has xmlXPathType $.types; # Array of defined types
    has int32 $.nb_funcs_unused; # unused (hash table)
    has int32 $.max_funcs_unused; # unused (hash table)
    has xmlHashTable $.funcHash; # Hash table of defined funcs
    has int32 $.nb_axis; # number of defined axis
    has int32 $.max_axis; # max number of axis
    has xmlXPathAxis $.axis; # Array of defined axis the namespace nodes of the context node
    has xmlNsPtr * $.namespaces; # Array of namespaces
    has int32 $.nsNr; # number of namespace in scope
    has Pointer $.user; # function to free extra variables
    has int32 $.contextSize; # the context size
    has int32 $.proximityPosition; # the proximity position extra stuff for XPointer
    has int32 $.xptr; # is this an XPointer context?
    has xmlNode $.here; # for here()
    has xmlNode $.origin; # for origin() the set of namespace declarations in scope for the expression
    has xmlHashTable $.nsHash; # The namespaces hash table
    has xmlXPathVariableLookupFunc $.varLookupFunc; # variable lookup func
    has Pointer $.varLookupData; # variable lookup data Possibility to link in an extra item
    has Pointer $.extra; # needed for XSLT The function name and URI when calling a function
    has xmlCharP $.function;
    has xmlCharP $.functionURI; # function lookup function and data
    has xmlXPathFuncLookupFunc $.funcLookupFunc; # function lookup func
    has Pointer $.funcLookupData; # function lookup data temporary namespace lists kept for walking the namespace axis
    has xmlNsPtr * $.tmpNsList; # Array of namespaces
    has int32 $.tmpNsNr; # number of namespaces in scope error reporting mechanism
    has Pointer $.userData; # user specific data block
    has xmlStructuredErrorFunc $.error; # the callback in case of errors
    has xmlError $.lastError; # the last error
    has xmlNode $.debugNode; # the source node XSLT dictionary
    has xmlDict $.dict; # dictionary if any
    has int32 $.flags; # flags to control compilation Cache for reusal of XPath objects
    has Pointer $.cache;
    method SetCache(int32 $active, int32 $value, int32 $options --> int32) is native(LIB) is symbol('xmlXPathContextSetCache') {*};
    method CtxtCompile(xmlCharP $str --> xmlXPathCompExpr) is native(LIB) is symbol('xmlXPathCtxtCompile') {*};
    method EvalPredicate(xmlXPathObject $res --> int32) is native(LIB) is symbol('xmlXPathEvalPredicate') {*};
    method Free() is native(LIB) is symbol('xmlXPathFreeContext') {*};
    method FunctionLookup(xmlCharP $name --> xmlXPathFunction) is native(LIB) is symbol('xmlXPathFunctionLookup') {*};
    method FunctionLookupNS(xmlCharP $name, xmlCharP $ns_uri --> xmlXPathFunction) is native(LIB) is symbol('xmlXPathFunctionLookupNS') {*};
    method NsLookup(xmlCharP $prefix --> xmlCharP) is native(LIB) is symbol('xmlXPathNsLookup') {*};
    method RegisterAllFunctions() is native(LIB) is symbol('xmlXPathRegisterAllFunctions') {*};
    method RegisterFunc(xmlCharP $name, xmlXPathFunction $f --> int32) is native(LIB) is symbol('xmlXPathRegisterFunc') {*};
    method RegisterFuncLookup(xmlXPathFuncLookupFunc $f, Pointer $funcCtxt) is native(LIB) is symbol('xmlXPathRegisterFuncLookup') {*};
    method RegisterFuncNS(xmlCharP $name, xmlCharP $ns_uri, xmlXPathFunction $f --> int32) is native(LIB) is symbol('xmlXPathRegisterFuncNS') {*};
    method RegisterNs(xmlCharP $prefix, xmlCharP $ns_uri --> int32) is native(LIB) is symbol('xmlXPathRegisterNs') {*};
    method RegisterVariable(xmlCharP $name, xmlXPathObject $value --> int32) is native(LIB) is symbol('xmlXPathRegisterVariable') {*};
    method RegisterVariableLookup(xmlXPathVariableLookupFunc $f, Pointer $data) is native(LIB) is symbol('xmlXPathRegisterVariableLookup') {*};
    method RegisterVariableNS(xmlCharP $name, xmlCharP $ns_uri, xmlXPathObject $value --> int32) is native(LIB) is symbol('xmlXPathRegisterVariableNS') {*};
    method RegisteredFuncsCleanup() is native(LIB) is symbol('xmlXPathRegisteredFuncsCleanup') {*};
    method RegisteredNsCleanup() is native(LIB) is symbol('xmlXPathRegisteredNsCleanup') {*};
    method RegisteredVariablesCleanup() is native(LIB) is symbol('xmlXPathRegisteredVariablesCleanup') {*};
    method VariableLookup(xmlCharP $name --> xmlXPathObject) is native(LIB) is symbol('xmlXPathVariableLookup') {*};
    method VariableLookupNS(xmlCharP $name, xmlCharP $ns_uri --> xmlXPathObject) is native(LIB) is symbol('xmlXPathVariableLookupNS') {*};
}

class xmlXPathFunct is repr('CStruct') {
    has xmlCharP $.name; # the function name
    has xmlXPathEvalFunc $.func; # the evaluation function
}

class xmlXPathObject is repr('CStruct') {
    has xmlXPathObjectType $.type;
    has xmlNodeSet $.nodesetval;
    has int32 $.boolval;
    has num64 $.floatval;
    has xmlCharP $.stringval;
    has Pointer $.user;
    has int32 $.index;
    has Pointer $.user2;
    has int32 $.index2;

    sub xmlXPathEval(xmlCharP $str, xmlXPathContext $ctx --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathEvalExpression(xmlCharP $str, xmlXPathContext $ctxt --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathNewBoolean(int32 $val --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathNewCString(Str $val --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathNewFloat(num64 $val --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathNewString(xmlCharP $val --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathWrapCString(Str $val --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathWrapExternal(Pointer $val --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPathWrapString(xmlCharP $val --> xmlXPathObject) is native(LIB) is export {*};
    sub xmlXPtrEval(xmlCharP $str, xmlXPathContext $ctx --> xmlXPathObject) is native(LIB) is export {*};

    method ShellPrintXPathResult() is native(LIB) is symbol('xmlShellPrintXPathResult') {*};
    method CastToBoolean( --> int32) is native(LIB) is symbol('xmlXPathCastToBoolean') {*};
    method CastToNumber( --> num64) is native(LIB) is symbol('xmlXPathCastToNumber') {*};
    method CastToString( --> xmlCharP) is native(LIB) is symbol('xmlXPathCastToString') {*};
    method ConvertBoolean( --> xmlXPathObject) is native(LIB) is symbol('xmlXPathConvertBoolean') {*};
    method ConvertNumber( --> xmlXPathObject) is native(LIB) is symbol('xmlXPathConvertNumber') {*};
    method ConvertString( --> xmlXPathObject) is native(LIB) is symbol('xmlXPathConvertString') {*};
    method FreeNodeSetList() is native(LIB) is symbol('xmlXPathFreeNodeSetList') {*};
    method Free() is native(LIB) is symbol('xmlXPathFreeObject') {*};
    method Copy( --> xmlXPathObject) is native(LIB) is symbol('xmlXPathObjectCopy') {*};
    method PtrBuildNodeList( --> xmlNode) is native(LIB) is symbol('xmlXPtrBuildNodeList') {*};
    method PtrLocationSetCreate( --> xmlLocationSet) is native(LIB) is symbol('xmlXPtrLocationSetCreate') {*};
    method PtrNewRangePointNode(xmlNode $end --> xmlXPathObject) is native(LIB) is symbol('xmlXPtrNewRangePointNode') {*};
    method PtrNewRangePoints(xmlXPathObject $end --> xmlXPathObject) is native(LIB) is symbol('xmlXPtrNewRangePoints') {*};
}

class xmlXPathParserContext is repr('CStruct') {
    has xmlCharP $.cur; # the current char being parsed
    has xmlCharP $.base; # the full expression
    has int32 $.error; # error code
    has xmlXPathContext $.context; # the evaluation context
    has xmlXPathObject $.value; # the current value
    has int32 $.valueNr; # number of values stacked
    has int32 $.valueMax; # max number of values stacked
    has xmlXPathObjectPtr * $.valueTab; # stack of values
    has xmlXPathCompExpr $.comp; # the precompiled expression
    has int32 $.xptr; # it this an XPointer expression
    has xmlNode $.ancestor; # used for walking preceding axis
    has int32 $.valueFrame; # used to limit Pop on the stack

    sub xmlXPathNewParserContext(xmlCharP $str, xmlXPathContext $ctxt --> xmlXPathParserContext) is native(LIB) is export {*};

    method valuePop( --> xmlXPathObject) is native(LIB) {*};
    method valuePush(xmlXPathObject $value --> int32) is native(LIB) {*};
    method AddValues() is native(LIB) is symbol('xmlXPathAddValues') {*};
    method BooleanFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathBooleanFunction') {*};
    method CeilingFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathCeilingFunction') {*};
    method CompareValues(int32 $inf, int32 $strict --> int32) is native(LIB) is symbol('xmlXPathCompareValues') {*};
    method ConcatFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathConcatFunction') {*};
    method ContainsFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathContainsFunction') {*};
    method CountFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathCountFunction') {*};
    method DivValues() is native(LIB) is symbol('xmlXPathDivValues') {*};
    method EqualValues( --> int32) is native(LIB) is symbol('xmlXPathEqualValues') {*};
    method Err(int32 $error) is native(LIB) is symbol('xmlXPathErr') {*};
    method EvalExpr() is native(LIB) is symbol('xmlXPathEvalExpr') {*};
    method EvaluatePredicateResult(xmlXPathObject $res --> int32) is native(LIB) is symbol('xmlXPathEvaluatePredicateResult') {*};
    method FalseFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathFalseFunction') {*};
    method FloorFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathFloorFunction') {*};
    method Free() is native(LIB) is symbol('xmlXPathFreeParserContext') {*};
    method IdFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathIdFunction') {*};
    method LangFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathLangFunction') {*};
    method LastFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathLastFunction') {*};
    method LocalNameFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathLocalNameFunction') {*};
    method ModValues() is native(LIB) is symbol('xmlXPathModValues') {*};
    method MultValues() is native(LIB) is symbol('xmlXPathMultValues') {*};
    method NamespaceURIFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathNamespaceURIFunction') {*};
    method NextAncestor(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextAncestor') {*};
    method NextAncestorOrSelf(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextAncestorOrSelf') {*};
    method NextAttribute(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextAttribute') {*};
    method NextChild(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextChild') {*};
    method NextDescendant(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextDescendant') {*};
    method NextDescendantOrSelf(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextDescendantOrSelf') {*};
    method NextFollowing(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextFollowing') {*};
    method NextFollowingSibling(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextFollowingSibling') {*};
    method NextNamespace(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextNamespace') {*};
    method NextParent(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextParent') {*};
    method NextPreceding(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextPreceding') {*};
    method NextPrecedingSibling(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextPrecedingSibling') {*};
    method NextSelf(xmlNode $cur --> xmlNode) is native(LIB) is symbol('xmlXPathNextSelf') {*};
    method NormalizeFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathNormalizeFunction') {*};
    method NotEqualValues( --> int32) is native(LIB) is symbol('xmlXPathNotEqualValues') {*};
    method NotFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathNotFunction') {*};
    method NumberFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathNumberFunction') {*};
    method ParseNCName( --> xmlCharP) is native(LIB) is symbol('xmlXPathParseNCName') {*};
    method ParseName( --> xmlCharP) is native(LIB) is symbol('xmlXPathParseName') {*};
    method PopBoolean( --> int32) is native(LIB) is symbol('xmlXPathPopBoolean') {*};
    method PopExternal( --> Pointer) is native(LIB) is symbol('xmlXPathPopExternal') {*};
    method PopNodeSet( --> xmlNodeSet) is native(LIB) is symbol('xmlXPathPopNodeSet') {*};
    method PopNumber( --> num64) is native(LIB) is symbol('xmlXPathPopNumber') {*};
    method PopString( --> xmlCharP) is native(LIB) is symbol('xmlXPathPopString') {*};
    method PositionFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathPositionFunction') {*};
    method Root() is native(LIB) is symbol('xmlXPathRoot') {*};
    method RoundFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathRoundFunction') {*};
    method StartsWithFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathStartsWithFunction') {*};
    method StringFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathStringFunction') {*};
    method StringLengthFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathStringLengthFunction') {*};
    method SubValues() is native(LIB) is symbol('xmlXPathSubValues') {*};
    method SubstringAfterFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathSubstringAfterFunction') {*};
    method SubstringBeforeFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathSubstringBeforeFunction') {*};
    method SubstringFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathSubstringFunction') {*};
    method SumFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathSumFunction') {*};
    method TranslateFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathTranslateFunction') {*};
    method TrueFunction(int32 $nargs) is native(LIB) is symbol('xmlXPathTrueFunction') {*};
    method ValueFlipSign() is native(LIB) is symbol('xmlXPathValueFlipSign') {*};
    method Patherror(Str $file, int32 $line, int32 $no) is native(LIB) is symbol('xmlXPatherror') {*};
    method PtrEvalRangePredicate() is native(LIB) is symbol('xmlXPtrEvalRangePredicate') {*};
    method PtrRangeToFunction(int32 $nargs) is native(LIB) is symbol('xmlXPtrRangeToFunction') {*};
}

class xmlXPathType is repr('CStruct') {
    has xmlCharP $.name; # the type name
    has xmlXPathConvertFunc $.func; # the conversion function
}

class xmlXPathVariable is repr('CStruct') {
    has xmlCharP $.name; # the variable name
    has xmlXPathObject $.value; # the value
}

sub xmlXPathCastBooleanToNumber(int32 $val --> num64) is native(LIB) is export {*};
sub xmlXPathCastBooleanToString(int32 $val --> xmlCharP) is native(LIB) is export {*};
sub xmlXPathCastNumberToBoolean(num64 $val --> int32) is native(LIB) is export {*};
sub xmlXPathCastNumberToString(num64 $val --> xmlCharP) is native(LIB) is export {*};
sub xmlXPathCastStringToBoolean(xmlCharP $val --> int32) is native(LIB) is export {*};
sub xmlXPathCastStringToNumber(xmlCharP $val --> num64) is native(LIB) is export {*};
sub xmlXPathInit() is native(LIB) is export {*};
sub xmlXPathIsInf(num64 $val --> int32) is native(LIB) is export {*};
sub xmlXPathIsNaN(num64 $val --> int32) is native(LIB) is export {*};