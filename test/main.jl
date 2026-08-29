##############################################################################
################################ main.jl #####################################
##############################################################################
#
# author: Romana Jezek
# date: 08/2026


include("../src/OConcise.jl")
using .OConcise

matches = parseFileToJson(ENV["OCONCISE"] * "/texFiles/test.tex", ENV["OCONCISE"] * "/yamlFiles/ltbookOut.yaml","r")
formats = readTypesheetsIn([ENV["OCONCISE"] * "/yamlFiles/ltbookOut.yaml"])

for i in 1:length(matches)
    data = readJsonStringIn(matches[i])
    checkProofs(data,formats,"tptp")
    println(stmtList)
end

