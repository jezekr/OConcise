####################################################################################
########################### traverseTree.jl ########################################
####################################################################################
#
# This program traverses the parse tree
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

using OrderedCollections

include("getProduction.jl")
include("findTyped.jl")
include("getCatOutput.jl")
include("fillStatementList.jl")

function executeNodeFunction(nodeFunction::Function, data::OrderedDict, peekNode::String, transferContent::OrderedDict{String,Any})
    return nodeFunction(data,peekNode,transferContent)
end

function traverseTree(data::OrderedDict,formats::Vector{Any},target::String,nodeFunction::Function)
    a = keys(data)
    keyVec = collect(a)
    node = keyVec[1]
    transferContent = OrderedDict{String,Any}()
    alternatives = OrderedSet{String}()
    stack = []
    childNodes = []
    lastNodeVisited = nothing
    while node != nothing || !isempty(stack)
        # walk threw tree until you reach a leaf
        if node != nothing
            # add all the nodes to stack
            push!(stack,node)
            if haskey(data[node],"children")
                childNodes = collect(values(data[node]["children"]))
                if lastNodeVisited != nothing && findfirst(item -> item == lastNodeVisited,childNodes) != nothing
                    deleteat!(childNodes,1:findfirst(item -> item == lastNodeVisited,childNodes))
                end
                if !isempty(childNodes)
                    node = childNodes[1]
                else
                    node = nothing
                end
            elseif haskey(data[node],"alternatives")
                push!(alternatives,node)
                altNodes = collect(values(data[node]["alternatives"]))
                if lastNodeVisited != nothing && findfirst(item -> item == lastNodeVisited,altNodes) != nothing
                    deleteat!(altNodes,1:findfirst(item -> item == lastNodeVisited,altNodes))
                end
                if !isempty(altNodes)
                    node = altNodes[1]
                else
                    node = nothing
                end
            else
                node = nothing
            end
        else
            # collect the information of the peeked node
            peekNode = stack[end]
            peekChildrenNames = []
            if haskey(data[peekNode],"children")
                peekChildrenNames = collect(values(data[peekNode]["children"]))
            elseif haskey(data[peekNode],"alternatives")
                peekChildrenNames = collect(values(data[peekNode]["alternatives"]))
            end
            if !isempty(peekChildrenNames)
                if lastNodeVisited != peekChildrenNames[length(peekChildrenNames)]
                    # we go to the right most child because we pop from the last node
                    # # (left most) from the stack
                    ind = findfirst(item -> item == lastNodeVisited, peekChildrenNames)
                    node = peekChildrenNames[ind+1]
                else
                    # get the information of the category of the node from the typesheet
                    if haskey(data[peekNode],"children")
                        if !(contains(data[peekNode]["Type"],"anyTimes") ||  contains(data[peekNode]["Type"],"multiple") || contains(data[peekNode]["Type"],"once") || contains(data[peekNode]["Type"],"opt"))
                            production = getProduction(formats,data[peekNode]["Type"],target)
                            if !isempty(production)
                                transferContent[peekNode] = OrderedDict()
                                transferContent[peekNode]["content"] = []
                                transferContent = getCatOutput(data,formats,peekNode,production,peekChildrenNames,transferContent,target)
                                if isempty(transferContent[peekNode]["content"])
                                    delete!(transferContent,peekNode)
                                end
                            else
                                for format in formats
                                    if haskey(format["TypeSheet"]["entries"]["categories"],data[peekNode]["Type"])
                                        catInfo = format["TypeSheet"]["entries"]["categories"][data[peekNode]["Type"]]
                                        if "UnionSpec" in keys(catInfo["specifications"])
                                            if haskey(transferContent,peekChildrenNames[1]) && haskey(transferContent[peekChildrenNames[1]],"content")
                                                transferContent[peekNode] = OrderedDict()
                                                transferContent[peekNode]["content"] = []
                                                transferContent[peekNode]["content"] = transferContent[peekChildrenNames[1]]["content"]
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    elseif haskey(data[peekNode],"alternatives")
                        altCollections = []
                        transferContent[peekNode] = OrderedDict()
                        transferContent[peekNode]["alternatives"] = OrderedDict()
                        first = true
                        for alternative in peekChildrenNames
                            typed = findTyped(data,alternative,[])
                            if first
                                if !(alternative in typed)
                                    transferContent[alternative] = OrderedDict()
                                    transferContent[alternative]["content"] = []
                                    for typedNode in typed
                                        if haskey(transferContent,typedNode) && haskey(transferContent[typedNode],"content")
                                            push!(transferContent[alternative]["content"],join(transferContent[typedNode]["content"]))
                                        end
                                    end
                                end
                                #TODO Take the alternative that is chosen
                                if haskey(transferContent,alternative) && haskey(transferContent[alternative],"content")
                                    transferContent[peekNode]["content"] = join(transferContent[alternative]["content"])
                                end
                                first = false
                            end
                            if haskey(transferContent,alternative) && haskey(transferContent[alternative],"content")
                                transferContent[peekNode]["alternatives"][alternative] = OrderedDict()
                                transferContent[peekNode]["alternatives"][alternative]["content"] = join(transferContent[alternative]["content"])
                                delete!(transferContent,alternative)
                            end
                        end
                    end
                    if nodeFunction != nothing
                        executeNodeFunction(nodeFunction,data,peekNode,transferContent)
                    end
                    lastNodeVisited = pop!(stack)
                end
            elseif haskey(data[peekNode],"content")
                if !isempty(data[peekNode]["content"])
                    transferContent[peekNode] = OrderedDict()
                    transferContent[peekNode]["content"] = data[peekNode]["content"]
                end
                lastNodeVisited = pop!(stack)
            else
                throw(error(peekNode * " has neither children nor content"))
            end
        end
    end #while
end #function
