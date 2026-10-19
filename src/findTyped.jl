####################################################################################
############################# findTyped.jl #########################################
####################################################################################
#
# author: Romana Jezek
# date: 2026/07/18


function findTyped(data::OrderedDict,node::String,typed::Array)
    if !haskey(data,node)
        throw(error(node * "is missing in data"))
    end
    if !haskey(data[node],"Type")
        throw(error(node * "has no type"))
    end
    nodeType = data[node]["Type"]
    if !(contains(nodeType,"anyTimes") ||  contains(nodeType,"multiple") || contains(nodeType,"once") || contains(nodeType,"opt") || contains(nodeType,"options") || contains(nodeType,"Includes") || contains(nodeType,"Taboo") || contains(nodeType,"Expect"))
        push!(typed,node)
    elseif contains(nodeType,"Includes")
        cat = split(nodeType,"Includes")
        push!(typed,cat[1])
    else
        if haskey(data[node],"children")
            children = collect(values(data[node]["children"]))
            for child in children
                typed = findTyped(data,child,typed)
            end
        elseif haskey(data[node],"alternatives")
            # TODO take the alternative that is chosen
            alternatives = collect(values(data[node]["alternatives"]))
            typed = findTyped(data,alternatives[1],typed)
        end
    end
    return typed
end
