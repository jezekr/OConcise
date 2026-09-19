####################################################################################
############################# findType.jl #########################################
####################################################################################
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
# This programs traverses the subtree of nodes of type anyTimes, multiple, once or
# opt to get the original type(s).
# The type names containing "anyTimes", "multiple", "once" or "opt" are added
# automatically to the grammar with the ruleSetter program.
#
# input: data - the parse tree
#        node - the name of the node containing the type anyTimes, multiple, once
#               or opt
#        typed - original node types that are collected so far (recursive)
# output: typed - the original node type(s)


function findType(data::OrderedDict,node::String,typed::Array)
    if !haskey(data,node)
        throw(error(node * "is missing in data"))
    end
    if !haskey(data[node],"Type")
        throw(error(node * "has no type"))
    end
    nodeType = data[node]["Type"]
    if !(contains(nodeType,"anyTimes") ||  contains(nodeType,"multiple") || contains(nodeType,"once") || contains(nodeType,"opt"))
        push!(typed,node)
    else
        if haskey(data[node],"children")
            children = collect(values(data[node]["children"]))
            for child in children
                typed = findType(data,child,typed)
            end
        elseif haskey(data[node],"alternatives")
            # TODO take the alternative that is chosen
            alternatives = collect(values(data[node]["alternatives"]))
            typed = findType(data,alternatives[1],typed)
        end
    end
    return typed
end
