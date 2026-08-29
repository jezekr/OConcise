/* OConcise: OConciseParser
   Copyright (C) 2019-2026 Romana Ježek

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.*/

#include <yaml-cpp/yaml.h>
#include "qtyaml.h"
#include "dyngenpar.h"
#include "ruleSetter.h"

#include <QStringList>
#include <QString>
#include <QList>

using namespace DynGenPar;

class OConciseParser : public Parser
{
public:
    RuleSetter ruleSetter;
    OConciseParser(TokenSource *tokensource,const QString &fileName,const QString target,const QString &yamlTypesheet)
        : Parser(tokensource), ruleSetter(target,yamlTypesheet), inputSource(tokensource)
    {
        startCat = ruleSetter.startCat;
        rules = ruleSetter.rules;
        initCaches();
    }
    virtual ~OConciseParser()
    {
        delete inputSource;
    }
    QStringList printParseTreeToJson(Node tree);
protected:
    TokenSource *inputSource;
};
Q_DECLARE_TYPEINFO(OConciseParser, Q_MOVABLE_TYPE);
