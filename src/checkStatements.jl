###############################################################################
############################# checkStatements.jl###############################
###############################################################################
#
# This program checks every conjecture in the list with vampire theorem prover
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

using DataFrames

function checkStatements()
    vampirePath = ENV["OCONCISE"] * "/vampire"    
    if isempty(stmtList)
        throw(error("the statement list is empty!"))
    end
    if !isfile(vampirePath * "/vampire")
        throw(error("vampire is not installed!"))
    end
    if !isdir(vampirePath * "/tptpFiles")
        mkpath(vampirePath * "/tptpFiles")
    end    
    i = 0
    for (index, row) in enumerate(eachrow(stmtList))
        if row.tptpType == "conjecture"
            i += 1
            fileName = vampirePath * "/tptpFiles/tptpFile_" * string(i)
            open(fileName, "w") do io
                if isfile(vampirePath * "/tptpFiles/definitions")
                  write(io,"include('definitions').\n")
                end
                for argument in row.arguments                    
                    write(io,replace(join(filter(:name => ==(argument), stmtList).tptp),"conjecture" => "axiom"))
                    write(io, "\n")
                end
                write(io,join(row.tptp))
            end
            output = ""
            try
                output = read(open(pipeline(`$vampirePath/vampire --input_syntax tptp --output_mode smtcomp $fileName`) ),String)             
            catch e
                println("An error occured: ", e)
            end
            global stmtList[index, :output] = output
        end
    end
end
