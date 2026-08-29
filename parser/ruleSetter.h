/* OConcise: ruleSetter
   Copyright (C) 2019-2026 Romana Ježek

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   This program sets the rules for parsing automatically.*/

#include <yaml-cpp/yaml.h>
#include "qtyaml.h"
#include "dyngenpar.h"

#include <QString>
#include <QStringList>
#include <QTextStream>
#include <QTextCodec>
#include <fstream>
#include <QFile>

using namespace DynGenPar;

struct RuleSetter
{
    RuleSetter(const QString &target,const QString &yamlTypesheet) :
        target(target)
    {
        streamedYamlTypesheet = streamTypesheet(yamlTypesheet);
        QPair rs = setRules();
        rules = rs.first;
        startCat = rs.second;
    }
    QPair<RuleSet,Cat> setRules();
    void printRulesToYaml(const QString &fileName);
    YAML::Node streamTypesheet(const QString &yamlFileName)
    {
        QFile file(yamlFileName);
        if (file.open(QFile::ReadOnly | QFile::Text))
        {
            QTextStream in(&file);
            QString yamlContent = in.readAll();
            return YAML::Load(yamlContent.toStdString());
        }
        else
        {
            qFatal("yamlTypeSheet " + yamlFileName.toLatin1() + " could not be opened!");
        }
        return YAML::Node();
    }
    RuleSet rules;
    Cat startCat;
    QStringList categoryNames;
    QStringList literalNames;
    int optNr = 0;
    int onceNr = 0;
private:
    void setCategoryNames();
    Rule getRule(Rule &rule,const QString& catName,QString suffix,YAML::Node prods);
    QString target;
    YAML::Node streamedYamlTypesheet;
};
Q_DECLARE_TYPEINFO(RuleSetter, Q_MOVABLE_TYPE);
