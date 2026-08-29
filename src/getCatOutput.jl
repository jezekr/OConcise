####################################################################################
############################ getCatOutput.jl #######################################
####################################################################################
#
# this program transfers the read category content to the desired output
#
# Copyright (C) 2023-2026 Romana Ježek <office@romanajezek.at>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License, either 
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

global opt = false
global optContent = []

function getCatOutput(data::OrderedDict,formats::Vector{Any},peekNode::String,prod::Any,peekChildrenNames::Array,transferContent::OrderedDict{String,Any},target::String)
    if isa(prod,Array)
        for elem in prod
            getCatOutput(data,formats,peekNode,elem,peekChildrenNames,transferContent,target)
            if isa(elem, OrderedDict) && (elem == last(prod))
                global opt = false
                global optContent = []
            end
        end
    elseif isa(prod, OrderedDict)
        for (key,val) in prod
            if key == "link"
                if !haskey(data,peekNode)
                    throw(error(peekNode * "is missing in data"))
                end
                if !haskey(data[peekNode],"Type")
                    throw(error(peekNode * "has no type"))
                end
                cat = data[peekNode]["Type"]
                stop = false
                for childName in peekChildrenNames
                    typed = findTyped(data,childName,[])
                    matched = false
                    for typedNode in typed
                        childType = data[typedNode]["Type"]
                        if childType == prod[key]
                            matched = true
                            if haskey(transferContent,typedNode) && haskey(transferContent[typedNode],"content")
                                if !isempty(optContent)
                                    push!(transferContent[peekNode]["content"],join(optContent))
                                    global optContent = []
                                    global opt = false
                                end
                                push!(transferContent[peekNode]["content"],join(transferContent[typedNode]["content"]))
                                delete!(transferContent,typedNode)
                            end
                        end
                    end
                    if matched
                        ind = findfirst(item -> item == childName, peekChildrenNames)
                        deleteat!(peekChildrenNames, ind)
                        push!(peekChildrenNames,childName)
                        global alt = false
                        break
                    end
                end
            elseif key == "CatVar"
                stop = false
                if prod[key] == "String"
                    for childName in peekChildrenNames
                        if haskey(transferContent,childName) && haskey(transferContent[childName],"content")
                            push!(transferContent[peekNode]["content"],join(transferContent[childName]["content"]))
                            delete!(transferContent,childName)
                        end
                    end
                else
                    if !haskey(data,peekNode)
                        throw(error(peekNode * "is missing in data"))
                    end
                    if !haskey(data[peekNode],"Type")
                        throw(error(peekNode * "has no type"))
                    end
                    cat = data[peekNode]["Type"]
                    stop = false
                    for child in peekChildrenNames
                        typed = findTyped(data,child,[])
                        for typedNode in typed
                            nType = data[typedNode]["Type"]
                            for format in formats
                                if haskey(format, "TypeSheet") 
                                    if haskey(format["TypeSheet"],"entries")
                                        if haskey(format["TypeSheet"]["entries"],"categories")
                                            if haskey(format["TypeSheet"]["entries"]["categories"],cat)
                                                if haskey(format["TypeSheet"]["entries"]["categories"][cat],"specifications")
                                                    for spec in values(format["TypeSheet"]["entries"]["categories"][cat]["specifications"])
                                                        for (specKey,specVal) in spec
                                                            if nType == specVal && specKey == val
                                                                if haskey(transferContent,typedNode) && haskey(transferContent[typedNode],"content")
                                                                    if !isempty(optContent)
                                                                        push!(transferContent[peekNode]["content"],join(optContent))
                                                                        global optContent = []
                                                                        global opt = false
                                                                    end
                                                                    push!(transferContent[peekNode]["content"],join(transferContent[typedNode]["content"]))
                                                                    delete!(transferContent,typedNode)
                                                                    stop = true
                                                                    break
                                                                end
                                                            end
                                                        end
                                                        if stop
                                                            break
                                                        end
                                                    end
                                                end                          
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if stop
                            ind = findfirst(item -> item == child, peekChildrenNames)
                            deleteat!(peekChildrenNames,ind)
                            push!(peekChildrenNames,child)
                            global alt = false
                            break
                        end
                    end
                end
            elseif key == "optional"
                #this is necessary because optionals are always printed even if
                #there is no content in it, this can be changed in the grammatic
                #rules
                if length(peekChildrenNames) == 1 && data[peekChildrenNames[1]]["Type"] == "String" && isempty(data[peekChildrenNames[1]]["content"])
                    deleteat!(peekChildrenNames,1)
                else
                    global opt = true
                    global optContent = []
                    getCatOutput(data,formats,peekNode,prod[key],peekChildrenNames,transferContent,target)
                end
            elseif key == "once"
                getCatOutput(data,formats,peekNode,prod[key],peekChildrenNames,transferContent,target)
            elseif key == "anyTimes"
                getCatOutput(data,formats,peekNode,prod[key],peekChildrenNames,transferContent,target)
            elseif key == "multiple"
                getCatOutput(data,formats,peekNode,prod[key],peekChildrenNames,transferContent,target)
            elseif key == "match"
                matchCase = prod[key]
                # TODO: matchCases are not used at the moment
                if "Maximal" in keys(matchCase)
                elseif "Except" in keys(matchCase)
                elseif "Expect" in keys(matchCase)
                elseif "Taboo" in keys(matchCase)
                end
            elseif key == "alternative"
                global alt = true
                getCatOutput(data,formats,peekNode,prod[key],peekChildrenNames,transferContent,target)
            elseif key == "or"
                if alt
                    getCatOutput(data,formats,peekNode,prod[key],peekChildrenNames,transferContent,target)
                end
            elseif key == "function"
                for elem in prod[key]
                    if haskey(elem,"args")
                        getCatOutput(data,formats,peekNode,elem["args"],peekChildrenNames,transferContent,target)
                    end
                end
                for elem in prod[key]
                    if haskey(elem,"name")
                        if elem["name"] == "out"
                            if haskey(transferContent,peekNode)
                                if !haskey(transferContent,"out")
                                    transferContent["out"] = []
                                end
                                push!(transferContent["out"],join(transferContent[peekNode]["content"]))
                            end
                            # TODO: the following function names have been used in
                            # Concise and could be useful in the future
                        elseif elem["name"] == "save"
                        elseif elem["name"] == "toggleitalic"
                        elseif elem["name"] == "setFontSize"
                        elseif elem["name"] == "setColor"
                        elseif elem["name"] == "resetColor"
                        elseif elem["name"] == "setBold"
                        elseif elem["name"] == "resetAtribs"
                        elseif elem["name"] == "textRef"
                        elseif elem["name"] == "drawImage"
                        elseif elem["name"] == "drawShape"
                        elseif elem["name"] == "textURL"
                        end
                    end
                end
            end
        end
    elseif isa(prod, Number)
        push!(transferContent[peekNode]["content"],string(prod))
    elseif isa(prod, String)
        if contains(prod,"&")
            #check the escape rules and print the output of the rule
            format = formats[1]
            if haskey(format, "TypeSheet") 
                if haskey(format["TypeSheet"],"entries")
                    if haskey(format["TypeSheet"]["entries"],"literals")
                        for entry in format["TypeSheet"]["entries"]["literals"]
                            if "productions" in keys(entry)
                                literals = entry["productions"]
                                for lit in literals
                                    if "input" in keys(lit)
                                        if prod == lit["input"]
                                            if haskey(lit,"target")
                                                k = lit["target"]
                                                if k == target
                                                    if opt
                                                        push!(optContent,lit["output"])
                                                    else
                                                        push!(transferContent[peekNode]["content"],lit["output"])
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            if opt
                push!(optContent,prod)
            else
                push!(transferContent[peekNode]["content"],prod)
            end
            if !isempty(peekChildrenNames)
                childName = peekChildrenNames[1]
                if haskey(transferContent,childName) && haskey(transferContent[childName],"content") && transferContent[childName]["content"] == prod
                    deleteat!(peekChildrenNames, 1)
                    delete!(transferContent,childName)
                end
            end
        end
    elseif isa(prod,Char)
        if !isempty(peekChildrenNames)
            childName = peekChildrenNames[1]
            if haskey(transferContent,childName) && haskey(transferContent[childName],"content") && transferContent[childName]["content"] == string(prod)
                push!(transferContent[peekNode]["content"],prod)
                deleteat!(peekChildrenNames, 1)
                delete!(transferContent,childName)
            end
        end
    end
    return transferContent
end
