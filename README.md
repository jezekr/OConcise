# OConcise - Semantic analysis of mathematical text
OConcise is part of the [FMathL project](https://github.com/Computational-Mathematics-Vienna/FMathL). It combines the already existing concept of using grammar sheets for parsing natural mathematical language with the automatic formalization of parsed text and the verification of mathematical proofs. The grammar sheets are called Type Sheets and are written in Yaml format. The original version of Type Sheets (in .cnt format) is described in Kevin Koflers dissertation [Dynamic Gemeral Parsing and Natural Mathematical Language](https://utheses-gateway.univie.ac.at/apiFulltext/document/get/file/43156). A Yaml type sheet is provided here as an example (The grammar will be added soon).
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
To parse a document with a type sheet grammar you need the function **parseFileToJson(fileToParse,typeSheet,target)**, where "fileToParse" is the path of the document you want to parse, "typeSheet" is the path of the type sheet and "target" is the desired target in the Type Sheet. The output is a vector of parse trees, provided as Json strings. To transform the Json parse tree into a Julia dictionary you can run the function **readJsonStringIn(json)**, where "json" is the vector entry that contains the desired parse tree. If you have saved the parse tree to a file you can use the function **readJsonFileIn(filePath)**.
The **readTypeSheetsIn(typesheets)** function reads the Yaml Type Sheets into Julia dictionaries. The argument "typesheets" is an array of Type Sheet paths. The reason why it is an array is that Type Sheets can contain imported categories from other type sheets. The paths of these Type Sheets have to be added.
The function **checkProofs(data,formats,tptpTarget,nodeFunction)** is used to convert proof steps to TPTP format and check their correctness. To check the TPTP formulas, the theorem prover Vampire is used. Vampire's response can be "unsat" if the proof step is valid, "sat" if the proof step is not valid, or "time over" if no answer was found. The argument "nodeFunction" is the name of the function that is used to process the nodes. That means that you can add a function for your own specific needs. See **fillULKStatementList.jl** as an example. The function processes the parse tree nodes containting the axioms and proof steps in the book "Universallogik" (W.Neumaier,2020) and transforms them into TPTP formulas so that they can be checked with the theorem prover. **checkStatements()** calls Vampire to check the proof steps.






