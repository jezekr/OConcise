##############################################################################
################################ OConcise.jl #################################
##############################################################################
#
# author: Romana Jezek
# date: 2026/04/26

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

function checkProofs(data::OrderedDict,formats::Vector{Any},tptpTarget::String)
    global stmtList = DataFrame(tptpType = "",name=[],arguments=[],tptp="",output=[])
    traverseTree(data,formats,tptpTarget,fillStatementList)
    checkStatements()
end

end

