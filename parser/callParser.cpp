/* OConcise - callParser
   Copyright (C) 2026 Romana Ježek (University of Vienna)

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details. */

#include <QString>
#include <QFile>
#include "dyngenpar.h"
#include "characterTokenSource.h"
#include "oconciseParser.h"
#include "jlcxx/jlcxx.hpp"


using namespace DynGenPar;

std::vector<std::string> callParser(const std::string &sourceFile,const std::string &typesheetName,const std::string &targetName)
{
    QString target {QString::fromStdString(targetName)};
    QString typeSheet {QString::fromStdString(typesheetName)};
    QString sourceFileName {QString::fromStdString(sourceFile)};

    CharacterTokenSource *tokensource = new CharacterTokenSource(sourceFileName);
    OConciseParser parser(tokensource,sourceFileName,target,typeSheet);

    int errorPos;
    Cat errorToken;
    QList<StackItem> stacks;
    QList<Match> matches = parser.parse(&errorPos, &errorToken, 0,&stacks, 0);
    int i = 0;
    std::cout << matches.size() << "\n";
    std::vector<std::string> vec = {};
    for (auto m:matches)
    {
        QString result = parser.printParseTreeToJson(m.tree).join("");
        std::string str = result.toStdString();
        vec.push_back(str);
        ++i;
    }
    return vec;
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.method("callParser", &callParser);
    mod.add_type<CharacterTokenSource>("CharacterTokenSource");
    mod.add_type<OConciseParser>("OConciseParser");
}
