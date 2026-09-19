##############################################################################
################################ OConcise.jl #################################
##############################################################################
#
# Copyright (C) 2026 Romana Ježek <office@romanajezek.at>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License, either 
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# This is the main file for the OConcise project
# The functions of the module that are useful for the user are
# exported
#
# The function parseFileToJson calls
# the parser, which parses the users file and the corresponding type
# sheet
# input: fileToParse - the file that should be parsed
#        typeSheet - the corresponding type sheet
#        target - the target name
# output: matches - a vector of DynGenPar matches
#
# The function readJsonFileIn transforms the parse tree in
# json format (saved into a file) into a Julia dictionary
# input: filePath - path of the json file (the output of the
#                   parser saved into a file)
# output: data - Julia dictionary containg nodes of the parse
#                tree
#
# The function readJsonStringIn transforms the parse tree in
# json format (saved into a String) into a Julia dictionary
# input: json - json string (the output of the parser)
# output: data - Julia dictionary containing nodes of the parse
#                tree
#
# The function readTypeSheetsIn loads the yaml type
# sheets into Julia dictionaries
# input: typesheets - array of paths of the yaml type sheets
# output: Julia dictionaries
#
# The function checkProofs traverses the parse tree applying
# the node function of the user. The node function should have the
# following properties:
#   - specific instructions how to transform nodes that contain
#     the axioms and proof steps into tptp formulas (this depends
#     on the type sheet grammar)
#   - save the axioms and proofs steps (also in tptp format)
#     into the stmt data frame (see fillULKStatementList.jl)
#     The stmt data frame should contain:
#     * tptpType: axiom, theorem or conjecture
#     * name: the name of the axiom, theorem or conjecture
#     * arguments (optional): arguments that are used for
#       a proof step
#     * tptp: the axiom, theorem or conjecture as tptp formula
# After the tree traversal the function calls the theorem prover
# Vampire to check the conjectures. The output of Vampire is
# saved into the column "output".

module OConcise

include("traverseTree.jl")
include("checkStatements.jl")

import YAML
import JSON
using OrderedCollections
using CxxWrap
using DataFrames
using DotEnv
DotEnv.load!()


@wrapmodule(() -> joinpath(ENV["OCONCISE"],"shared/callParser.so"))

export printCntToYaml, parseFileToJson, readJsonStringIn, readJsonFileIn, readTypesheetsIn, checkProofs, stmtList

function parseFileToJson(fileToParse::String,typeSheet::String,target::String)
    println("parse")
    matches = callParser(fileToParse,typeSheet,target)
    return matches
end

function readJsonFileIn(filePath::String)
    data = JSON.parsefile(filePath, dicttype=OrderedDict)
    return data
end

function readJsonStringIn(json::CxxWrap.StdLib.StdStringDereferenced)
    t = time()
    println("read JSON")
    data = JSON.parse(json,dicttype=OrderedDict)
    elapsed_time = time() - t
    println("JSON read in ", elapsed_time, " seconds")
    return data
end

function readTypesheetsIn(typesheets::Array{String})
    formats = []
    for typesheet in typesheets
        format = YAML.load_file(typesheet; dicttype=OrderedDict{String,Any})
        push!(formats,format)
    end
    return formats
end

function checkProofs(data::OrderedDict,formats::Vector{Any},tptpTarget::String,nodeFunction::Function)
    global stmtList = DataFrame(tptpType = "",name=[],arguments=[],tptp="",output=[])
    traverseTree(data,formats,tptpTarget,nodeFunction)
    checkStatements()
    return stmtList
end

end

