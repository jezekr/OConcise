######################################################################################
############################### createStatementList.jl ###############################
######################################################################################
#
# This program saves the theorems and proof steps in tptp format
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

global metaVariables = []

function fillStatementList(data::OrderedDict,peekNode::String,transferContent::OrderedDict{String,Any})
    if data[peekNode]["Type"] == "metaVariable"
        push!(metaVariables,join(transferContent[peekNode]["content"]))
    elseif data[peekNode]["Type"] == "theoremRow"
        tptpType = "axiom"
        if length(transferContent[peekNode]["content"]) != 2
          throw(error("the number of variables in the category is wrong: theoremRow"))
        end
        if isempty(stmtList[stmtList.name .== transferContent[peekNode]["content"][2], :])
            quant = ""
            first = true
            for var in metaVariables
              if first
                quant = "![" * var * ": text"
                first = false
              else
                quant = quant * "," * var * ": text"
              end
            end
            if !isempty(quant)
              quant *= "] : "
              global metaVariables = []
            end
            tptp = "tff('" * transferContent[peekNode]["content"][2] * "',axiom," * quant * "(" * replace(transferContent[peekNode]["content"][1], "\\b" => " ") * "))."
            push!(stmtList, (tptpType,transferContent[peekNode]["content"][2],[],tptp,[]))
        end
    elseif data[peekNode]["Type"] == "proof" && haskey(data[peekNode],"children")
        tptpType = "conjecture"
        premise = ""
        quant = ""
        first = true
        for var in metaVariables
          if first
            quant = "![" * var * ": text"
            first = false
          else
            quant = quant * "," * var * ": text"
          end
        end
        if !isempty(quant)
          quant *= "] : "
          global metaVariables = []
        end
        if length(transferContent[peekNode]["content"]) < 2 || length(transferContent[peekNode]["content"]) > 3
          throw(error("the number of variables in the category is wrong: proof"))
        elseif length(transferContent[peekNode]["content"]) == 2
            name = transferContent[peekNode]["content"][1]
            proofSteps = eval(Meta.parse(replace(transferContent[peekNode]["content"][2],"\\b" => " ")))
        elseif length(transferContent[peekNode]["content"]) == 3
            name = transferContent[peekNode]["content"][1]
            premise = replace(transferContent[peekNode]["content"][2],"\\b" => " ")
            proofSteps = eval(Meta.parse(replace(transferContent[peekNode]["content"][3],"\\b" => " ")))
        end
        for i in 1:length(proofSteps)
            if isempty(stmtList[stmtList.name .== name * "_step" * string(i), :])
                (arguments,conclusion) = proofSteps[i]
                if i == 1
                    tptp = "tff('" * name * "',theorem," * quant * "(" * premise
                else
                    push!(arguments,name * "_step" * string(i-1))
                end
                if !isempty(premise)
                    tptpStep = "tff('" * name * "_step" * string(i) * "',conjecture," * quant * "(" * premise * " => " * conclusion * "))."
                else
                    tptpStep = "tff('" * name * "_step" * string(i) * "',conjecture," * quant * "(" * conclusion * "))."
                end
                if i == length(proofSteps)
                    tptp *= " => " * conclusion * "))."
                    push!(stmtList,("theorem",name,[],tptp,[]))
                end
                push!(stmtList,(tptpType,name * "_step" * string(i),arguments,tptpStep,[]))
            end
        end
    end
end
