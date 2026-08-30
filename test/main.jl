##############################################################################
################################ main.jl #####################################
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


include("../src/OConcise.jl")
using .OConcise

matches = parseFileToJson(ENV["OCONCISE"] * "/texFiles/test.tex", ENV["OCONCISE"] * "/yamlFiles/ltbookOut.yaml","r")
formats = readTypesheetsIn([ENV["OCONCISE"] * "/yamlFiles/ltbookOut.yaml"])

for i in 1:length(matches)
    data = readJsonStringIn(matches[i])
    checkProofs(data,formats,"tptp")
    println(stmtList)
end

