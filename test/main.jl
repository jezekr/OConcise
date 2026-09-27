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

include("../src/fillULKStatementList.jl")

texFilePath = ENV["OCONCISE"] * "/texFiles/test.tex"
typeSheetPath = ENV["OCONCISE"] * "/yamlFiles/ltbookOut.yaml"
target = "text.read"
matches = parseFileToJson(texFilePath,typeSheetPath,target)
formats = readTypesheetsIn([typeSheetPath])

for i in 1:length(matches)
    data = readJsonStringIn(matches[i])
    tptpTarget = "tptp.write"
    stmtList = checkProofs(data,formats,tptpTarget,fillULKStatementList)
    println(stmtList)
end

