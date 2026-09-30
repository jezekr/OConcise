# OConcise - Semantic analysis of mathematical text
OConcise is part of the [FMathL project](https://github.com/Computational-Mathematics-Vienna/FMathL). It combines the already existing concept of using grammar sheets for parsing natural mathematical language (see [Concise](https://www.mat.univie.ac.at/~dferi/concise.html)) with the automatic formalization of parsed text and the verification of mathematical proofs. The grammar sheets are called Type Sheets and are written in Yaml format. The original version of Type Sheets (in .cnt format) is described in Kevin Koflers dissertation [Dynamic Gemeral Parsing and Natural Mathematical Language](https://utheses-gateway.univie.ac.at/apiFulltext/document/get/file/43156). A Yaml type sheet is provided here as an example (The grammar will be added soon).  
The parser [DynGenPar](http://www.tigen.org/kevin.kofler/fmathl/dyngenpar/dyngenpar-12.tar.xz) is used to parse the text with the type sheet grammar. The Type Sheets are automatically converted into the input grammar of DynGenPar. To verify proofs in mathematical text we transform the parsed axioms and proofsteps into [TPTP](https://www.tptp.org/) and use the automatic theorem prover [Vampire](https://github.com/vprover/vampire) for verification.

## Prerequisites:

You need Julia, Cmake 3.15 or higher, Qt 5, wget and the g++ compiler, version 10 or higher, to run the setup. 

## How to use OConcise:

### Installation:
1. In the main directory run the setup with Julia (the installation path must be saved into the system variable PATH):  
`julia setup.jl`  
The setup installs yaml-cpp, a  Yaml parser and emitter in C++, the parser DynGenPar and the theorem prover Vampire.  
The yaml-cpp licence can be found here: [https://github.com/jbeder/yaml-cpp/blob/master/LICENSE](https://github.com/jbeder/yaml-cpp/blob/master/LICENSE).  
The Vampire licence can be found here: [https://github.com/vprover/vampire/blob/master/LICENCE](https://github.com/vprover/vampire/blob/master/LICENCE).  
2. To test the installation run the test file:
`julia test/main.jl`  
The output should be a data frame containing axioms and proof steps and the answer of the theorem prover Vampire for the checked proof step.  

### Where you find what you need:
The type sheets are stored in the **yamlFiles** directory.  
A test file can be found in the **test** directory.

### Type sheets:
The grammar of the YAML type sheets is very similar to the original .cnt grammar:

**Tokens**: characters  
**Start category**: TypeSheet  
**Productions**:  
```
##hchar ::= \x00 . . . \x09 | \x0B . . . \x0C | \x0E . . . \xFFFF
##char ::= ##hchar | \n
##letter ::= A . . . Z | a . . . z
##digit ::= 0 . . . 9
##blanks ::= \x00
##eol ::=  \n
##line ::= (##hchar)*
##id ::= ##letter (##letter|##digit)*
##digits ::= (##digit)+
##foreignword ::= (##hchar \ :)+
##ws ::= \x20
##vertBar ::= \x7c
##minus ::= \x2D
##tab ::= ##ws##ws##ws##ws
##doubleQuote ::= \x22
##and ::= \x26
##plus ::= \x2B
##slash ::= \x2F
##sbracketl ::= \x5B
##sbracketr ::= \x5D
##cbracketl ::= \x7B
##cbracketr ::= \x7D
#TypeSheet ::= Typesheet: ##eol ##ws Header: ##eol #Header [##ws Targets: ##eol #Targets] [##ws StartCategory: ##ws #StartCategory] ##eol entries: ##eol #EntryLink [##ws postcomments: ##vertBar ##eol #CommentLink][##eol]
#Header ::= ##ws ##ws Typesystem: ##ws #Id ##eol ##ws ##ws language: ##ws #Id ##eol ##ws ##ws authority: ##ws #Id [##eol ##ws ##ws imports: ##eol #ImportLink] comments: ##ws ##vertBar ##eol #CommentLink [##ws ##ws translations: ##eol #TranslationLink]
#Id ::= ##id
#PosInt ::= ##digits
#ForeignId ::= ##foreignword
#ImportLink ::= ##ws ##ws ##ws ##minus ##ws TypeSystem: ##ws #Id ##eol ##tab Category: ##ws #Id ##eol [#ImportLink]
#TranslationLink ::= [##ws ##ws precomments: ##ws ##vertBar ##eol #CommentLink ##eol] ##ws ##ws language: ##ws #Id ##eol ##ws ##ws ##ws ids: ##eol #IdTranslationLink [#TranslationLink]
#IdTranslationLink ::= ##ws ##ws ##ws ForeignId: ##ws #ForeignId ##eol ##tab Id: ##ws #Id ##eol [#IdTranslationLink]
#CommentLink ::= #Comment [##eol #CommentLink]
#Comment ::= #Line
#Line ::= ##line
#Targets ::= [##ws ##ws precomments: ##ws ##vertBar #CommentLink ##eol] ##ws ##ws targets: ##eol #TargetLink ##eol
#TargetLink ::= #Target [#TargetLink]
#Target ::= ##ws ##ws ##minus ##ws sequence: ##ws ##sbracketl #FieldLink ##sbracketr ##eol ##tab vars: ##ws ##sbracketl #VarLink ##sbracketr ##eol [##tab comment: ##ws ##vertBar ##eol #Comment ##eol]
#FieldLink ::= #Id [.#FieldLink]
#VarLink ::= #Id [,#VarLink]
#StartCategory ::= #Id
#EntryLink ::= ##ws ##ws (#LitDef | #CatDef ) ##eol [#EntryLink]
#LitDef ::= [##ws ##ws ##minus ##ws preComments: ##ws ##vertBar ##eol #CommentLink ##eol] ##ws ##ws ##minus ##ws productions: ##eol #LitLink
#LitLink ::= #LitProduction [#LitLink]
#LitProduction → ##ws ##ws ##ws ##minus ##ws target: ##ws #Id ##eol ##tab field: ##ws #Id ##eol ##tab Substitution: ##eol #Substitution [##tab comments: ##ws ##vertBar ##eol #CommentLink ##eol]
| ##ws ##ws ##ws ##minus ##ws target: ##ws #Id ##eol ##tab field: ##ws #Id ##eol ##tab productions: ##ws ##sbracketl #AlternativeLink ##sbracketr [##tab comments: ##ws ##vertBar ##eol #CommentLink ##eol]
| ##ws ##ws ##ws ##minus ##ws target: ##ws Id ##eol ##tab field: ##ws #Id ##eol ##tab CRange: ##eol #CRangeLink [##tab comments: ##ws ##vertBar ##eol #CommentLink ##eol]
#Substitution ::= ##tab input: ##eol #CharLink ##tab output: ##eol #OutCharLink 
#CRange ::= #PosInt-#PosInt ##eol
#CRangeLink ::= ##tab ##minus ##ws #CRange ##eol [#CRangeLink]
#Char ::= ##litchar
#CharLink ::= #doubleQuote #Char [#CharLink] ##doubleQuote
#OutChar ::= ##outchar
#OutCharLink ::= ##doubleQuote #OutChar [#OutCharLink] #doubleQuote
#Alternative ::=  ##sbracketl #ElementLink ##sbracketr
#AlternativeLink ::= ##cbracketl alternative: #Alternative ##cbracketr [,#OrLink]
#OrLink ::= ##cbracketl or: #Alternative ##cbracketr [,#OrLink]
#ElementLink ::= #Element [,#ElementLink]
#LiteralLink ::= ##doubleQuote #Char [#LiteralLink] ##doubleQuote
#Element ::= ##cbracketl CatVar: ##ws #CatVar ##cbracketr | ##cbracketl link: ##ws #LitVar ##cbracketr | #LiteralLink | ##cbracketl LitId: ##ws #LitId ##cbracketr
| ##cbracketl function: ##eol #Function ##cbracketr | #Blanks | #LineBreak
| ##cbracketl optional: ##sbracketl #AlternativeLink ##sbracketr ##cbracketr | ##cbracketl once: ##sbracketl #AlternativeLink ##sbracketr ##cbracketr
| ##cbracketl anyTimes: ##sbracketl #AlternativeLink ##sbracketr ##cbracketr | ##cbracketl multiple: ##sbracketl #AlternativeLink ##sbracketr ##cbracketr
#Blanks ::= ##doubleQuote ##blanks ##doubleQuote
#LineBreak ::= ##doubleQuote \n ##doubleQuote
#MatchCase ::= #Maximal | #Expect | #Taboo | #Except
#Maximal ::= ##cbracketl Maximal: ##ws ##doubleQuote ##and ##plus ##doubleQuote ##cbracketr
#Expect ::= ##cbracketl Expect: ##ws #Element ##cbracketr
#Taboo ::= ##cbracketl Taboo: ##ws #Element ##cbracketr
#Except ::= ##cbracketl Except: ##ws #Element ##cbracketr
#CatVar ::= #CatVarRec | #CatVarName | #CatVarId
#CatVarRec ::= #Id
#CatVarName ::= #Id
#CatVarId ::= #Id
#LitVar ::= #Id
#LitId ::=  ##sbracketl #ElementLink ##sbracketr
#FunArg ::= ##sbracketl #ElementLink ##sbracketr
#FunArgs ::= ##minus ##ws args: ##eol #FunArgLink
#FunArgLink ::= ##minus ##ws ##FunArg [#FunArgLink]
#Function ::= name: ##ws #Id [#FunArgLink]
#CatDef ::= [##tab precomments: ##ws #CommentLink ##eol] ##ws Category: #Id ##eol [##tab extends: ##eol #Id ##eol] [##tab postComments: ##ws ##vertBar ##eol #CommentLink ##eol] ##tab specifications: ##eol #SpecLink [##tab productions: ##eol #CatLink [##eol ##tab irregular: ##eol #IrrLink]]
#SpecLink ::= #Spec [#SpecLink]
#Spec ::= #AllOfSpec | #OneOfSpec | #SomeOfSpec | #OptionalSpec | #FixedSpec | #OnlySpec
| #SomeOfTypeSpec | #ItselfSpec | #ArraySpec | #IndexSpec | #TemplateSpec | #NothingElseSpec
| #NothingSpec | #UnionSpec | #AtomicSpec | #CompleteSpec
#AllOfSpec ::= ##tab ##ws ##minus ##ws AllOfSpec: ##eol #EqLink
#OneOfSpec ::= ##tab ##ws ##minus ##ws OneOfSpec: ##eol #EqLink
#SomeOfSpec ::= ##tab ##ws ##minus ##ws SomeOfSpec: ##eol #EqLink
#OptionalSpec ::= ##tab ##ws ##minus ##ws OptionalSpec: ##eol #EqLink
#FixedSpec ::= ##tab ##ws ##minus ##ws FixedSpec: ##eol #EqLink
#OnlySpec ::= ##tab ##ws ##minus ##ws OnlySpec: ##eol #EqLink
#SomeOfTypeSpec ::= ##tab ##ws ##minus ##ws SomeOfTypeSpec: ##eol #EqLink
#ItselfSpec ::= ##tab ##ws ##minus ##ws ItselfSpec: ##eol #EqLink #NameLink
#ArraySpec ::= ##tab ##ws ##minus ##ws ArraySpec: ##eol #EqLink
#IndexSpec ::= ##tab ##ws ##minus ##ws IndexSpec: ##eol #EqLink
#TemplateSpec ::= ##tab ##ws ##minus ##ws TemplateSpec: ##eol #EqLink
#NothingElseSpec ::= ##tab ##ws ##minus ##ws NothingElseSpec: ##eol #EqLink
#NothingSpec ::= ##tab ##ws ##minus ##ws NothingSpec: ##eol #EqLink
#UnionSpec ::= ##tab ##ws ##minus ##ws UnionSpec: ##eol #EqLink
#AtomicSpec ::= ##tab ##ws ##minus ##ws AtomicSpec: ##eol #EqLink
#CompleteSpec ::= ##tab ##ws ##minus ##ws CompleteSpec: ##eol #EqLink
#EqLink ::= ##tab ##ws ##ws [##minus ##ws #Id : ##eol ##tab ##ws ##ws ##ws] ##minus ##ws #Id : ##ws #Id ##eol [#Comment ##eol] [#EqLink]
#NameLink ::= ##minus ##ws [#Id : ##ws] #Id ##eol [#NameLink]
#CatLink ::= #CatProduction [#CatLink]
#CatProduction ::= ##tab ##ws #Id : ##eol [##sbracketl #AlternativeLink ##sbracketr]  [##tab ##ws comments: ##ws ##vertBar ##eol #CommentLink ##eol]
#IrrLink ::= #IrrProduction [#IrrLink]
#IrrProduction ::= ##tab ##ws #Id : ##eol ##tab ##ws ##ws #Id : ##eol [##sbracketl #AlternativeLink ##sbracketr] [##tab ##ws ##ws comments: ##ws ##vertBar ##eol #CommentLink ##eol]






