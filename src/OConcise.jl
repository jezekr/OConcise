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

