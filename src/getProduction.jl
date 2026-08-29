####################################################################################
########################### getProduction.jl #######################################
####################################################################################
#
# this program collects the entries of the category production
#
# Copyright (C) 2024-2026 Romana Ježek <office@romanajezek.at>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License, either 
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.


function getProduction(formats::Vector{Any},nodeType::String,target::String)
    production = []
    isLit = false
    format = formats[1]
    if haskey(format, "TypeSheet") 
        if haskey(format["TypeSheet"],"entries")
            if haskey(format["TypeSheet"]["entries"],"literals")
                for entry in format["TypeSheet"]["entries"]["literals"]
                    if "productions" in keys(entry)
                        literals = entry["productions"]
                        for lit in literals
                            if "field" in keys(lit)
                                if nodeType == lit["field"]
                                    isLit = true
                                    if haskey(lit,"target")
                                        if lit["target"] == target
                                            if haskey(lit,"productions")
                                                production = lit["productions"]
                                                break
                                            elseif haskey(lit,"CRange")
                                                xRange = []
                                                # loop over the ranges of ascii symbols
                                                # #that is listed in the type sheet
                                                for range in lit["CRange"]
                                                    splittedRange = split(range,"-")
                                                    from = splittedRange[1]
                                                    to = splittedRange[2]
                                                    #urange is the range of the ascii 
                                                    #symbols
                                                    for ascii in parse(Int,from):parse(Int,to)
                                                        push!(xRange,ascii)
                                                    end
                                                end
                                                first = true
                                                for ascii in xRange
                                                    if first
                                                        alternative = OrderedDict()
                                                        alternative["alternative"] = [Char(ascii)]
                                                        push!(production,alternative)
                                                        first = false
                                                    else
                                                        alternative = OrderedDict()
                                                        alternative["or"] = [Char(ascii)]
                                                        push!(production,alternative)
                                                    end
                                                end
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
            if !isLit
                if haskey(format["TypeSheet"]["entries"],"categories")
                    if haskey(format["TypeSheet"]["entries"]["categories"],nodeType)
                        catInfo = format["TypeSheet"]["entries"]["categories"][nodeType]
                        if haskey(catInfo,"productions")
                            productions = catInfo["productions"]
                            if haskey(productions,target)
                                production = productions[target]
                            end
                        end
                    end
                end
            end
        end
    end
    return production
end
