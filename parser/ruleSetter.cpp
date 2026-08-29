/* OConcise: ruleSetter
   Copyright (C) 2019-2026 Romana Ježek

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   This program sets the rules for parsing automatically.*/

#include <QList>
#include <QString>
#include <typeinfo>
#include "ruleSetter.h"

using namespace DynGenPar;

// since the OConciseparser parses every symbol, we add the literals and unicodes to the categoryNames.
void RuleSetter::setCategoryNames()
{
    //add the literals
    YAML::Node literals = streamedYamlTypesheet["TypeSheet"]["entries"]["literals"];
    int rangeMaximum = 0;
    assert(literals.IsSequence());
    for(YAML::Node production: literals)
    {
        if (production["productions"])
        {
            YAML::Node prod = production["productions"];
            assert(prod.IsSequence());
            for (auto item : prod)
            {
                if (item["field"])
                {
                    categoryNames << item["field"].as<QString>();
                }
                if (item["CRange"])
                {
                    YAML::Node ranges = item["CRange"];
                    int rangeEnd = 0;
                    for(YAML::const_iterator rangeit=ranges.begin(); rangeit!=ranges.end(); ++rangeit)
                    {
                        QString range = (*rangeit).as<QString>();
                        QStringList list = range.split("-");
                        int rangeEnd = list.last().toInt();
                        if (rangeEnd > rangeMaximum)
                        {
                            rangeMaximum = rangeEnd;
                        }
                    }
                }
            }
        }
    }
    for (int i=0; i<rangeMaximum; i++) categoryNames << QString(QChar(i));
    for (auto name: categoryNames)
    {
        literalNames << name;
    }
    // add imported categories
    YAML::Node imports = streamedYamlTypesheet["TypeSheet"]["Header"]["imports"];
    for (YAML::const_iterator it {imports.begin()}; it != imports.end(); it++)
    {
        const QString file = QString("../yamlFiles/") + (*it)["TypeSystem"].as<QString>() + QString("Out.yaml");
        YAML::Node importStream = streamTypesheet(file);
        QString cat = (*it)["Category"].as<QString>();
        categoryNames << cat;
    }
    // add the categories
    for (auto elem : streamedYamlTypesheet["TypeSheet"]["entries"]["categories"])
    {
        categoryNames << elem.first.as<QString>();
    }
}

QPair<RuleSet,Cat> RuleSetter::setRules()
{
    QString catName;
    Cat category;
    YAML::Node categories;
    setCategoryNames();
    if (streamedYamlTypesheet["TypeSheet"]["entries"]["categories"])
    {
        categories = streamedYamlTypesheet["TypeSheet"]["entries"]["categories"];
        for (YAML::const_iterator it {categories.begin()}; it != categories.end(); ++it)
        {
            QString catName = it->first.as<QString>();
            if (catName == "TimesExpression")
            {
                continue;
            }
            if (categoryNames.contains(catName))
            {
                if(typeid(Cat) == typeid(int))
                {
                    category = (Cat) categoryNames.indexOf(catName);
                }
                else
                {
                    category = (Cat) catName;
                }
            }
            else
            {
                continue;
            }
            YAML::Node prods;
            if (categories[catName.toStdString()])
            {
                YAML::Node categoryContent = categories[catName.toStdString()];
                // some categories have no productions (i.e. Unions)
                if (categoryContent["productions"])
                {
                    prods = categoryContent["productions"];
                    if (prods.IsNull())
                    {
                        rules[category] << (Rule());
                    }
                    else
                    {
                        assert(prods.IsMap());
                        for (YAML::const_iterator targetit {prods.begin()}; targetit != prods.end(); ++targetit)
                        {
                            if (target == targetit->first.as<QString>())
                            {
                                QString suffix = "";
                                Rule rule;
                                getRule(rule,catName,suffix,targetit->second);
                            }
                        }
                    }
                }
                else
                {
                    // if the union is a list and not a map, create for all category a rule and add it to rules
                    if (categoryContent["specifications"])
                    {
                        YAML::Node specs = categoryContent["specifications"];
                        if (specs.IsMap() && specs["UnionSpec"])
                        {
                            YAML::Node val = specs["UnionSpec"];
                            assert(val.IsSequence());
                            for (YAML::const_iterator vit = val.begin(); vit != val.end(); ++vit)
                            {
                                if ((*vit).IsScalar())
                                {
                                    if (!categoryNames.contains(vit->as<QString>()))
                                    {
                                        qFatal((*vit).as<QString>().toLatin1() + " not in the list");
                                    }
                                    if(typeid(Cat) == typeid(int))
                                    {
                                        rules[category] << (Rule() << (Cat) categoryNames.indexOf((*vit).as<QString>()));
                                    }
                                    else
                                    {
                                        rules[category] << (Rule() << (Cat) vit->as<QString>());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (streamedYamlTypesheet["TypeSheet"]["entries"]["literals"])
    {
        YAML::Node literals {streamedYamlTypesheet["TypeSheet"]["entries"]["literals"]};
        assert(literals.IsSequence());
        for (YAML::const_iterator litit {literals.begin()}; litit != literals.end(); ++litit)
        {
            if ((*litit)["productions"])
            {
                auto prods = (*litit)["productions"];
                assert(prods.IsSequence());
                for (YAML::const_iterator it {prods.begin()}; it != prods.end(); ++it)
                {
                    assert((*it).IsMap());
                    if ((*it)["field"])
                    {
                        QString litName {((*it)["field"]).as<QString>()};
                        if (litName.isEmpty())
                        {
                            qFatal("literal name is missing");
                        }
                        if (categoryNames.contains(litName))
                        {
                            if(typeid(Cat) == typeid(int))
                            {
                                category = (Cat) categoryNames.indexOf(litName);
                            }
                            else
                            {
                                category = (Cat) litName;
                            }
                        }
                        else
                        {
                            qFatal(litName.toLatin1() + " not in categories");
                            continue;
                        }
                        if ((*it)["target"])
                        {
                            QString t {(*it)["target"].as<QString>()};
                            if (target == t)
                            {
                                Rule rule;
                                QString suffix = "";
                                if ((*it)["productions"])
                                {
                                    getRule(rule,litName,suffix,(*it)["productions"]);
                                }
                                else if ((*it)["CRange"])
                                {
                                    QList<QString> ranges = (*it)["CRange"].as<QList<QString>>();
                                    for (int i = 0; i < ranges.size(); i++)
                                    {
                                        QString range {ranges[i]};
                                        QStringList rangeNrs = range.split('-');
                                        if (rangeNrs.size() != 2)
                                        {
                                            qFatal((*it)["field"].as<QString>().toLatin1() + ": range: " + range.toLatin1() + "is not a range!");
                                        }
                                        else
                                        {
                                            int rangeBegin {rangeNrs.at(0).toInt()};
                                            int rangeEnd {rangeNrs.at(1).toInt()};
                                            for (int j {rangeBegin}; j<=rangeEnd; j++)
                                            {
                                                Rule rule;
                                                if(typeid(Cat) == typeid(int))
                                                {
                                                    rule << (Cat) j;
                                                }
                                                else
                                                {
                                                    rule << (Cat) QString(QChar(j));
                                                }
                                                rules[category] << (Rule() << rule);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (streamedYamlTypesheet["TypeSheet"]["StartCategory"])
    {
        if (!categoryNames.contains(streamedYamlTypesheet["TypeSheet"]["StartCategory"].as<QString>()))
        {
            qFatal("startcategory name is not in the list");
        }
        if(typeid(Cat) == typeid(int))
        {
            startCat = (Cat) categoryNames.indexOf(streamedYamlTypesheet["TypeSheet"]["StartCategory"].as<QString>());
        }
        else
        {
            startCat = (Cat) streamedYamlTypesheet["TypeSheet"]["StartCategory"].as<QString>();
        }
    }
    return qMakePair(rules,startCat);
}

Rule RuleSetter::getRule(Rule &rule,const QString &catName,QString suffix,YAML::Node prods)
{
    QString fullName;
    QString matchChar;
    int tabooNr = 0;
    int exceptNr = 0;
    int expectNr = 0;
    if (!suffix.isEmpty())
    {
        fullName = catName+suffix;
    }
    else if (suffix.isEmpty())
    {
        fullName = catName;
    }
    else
    {
        //throw error "suffix neither empty nor not empty"
    }
    if (!categoryNames.contains(fullName))
    {
        //throw error fullName + " is not in the list"
    }
    Cat category;
    if (typeid(Cat) == typeid(int))
    {
        category = (Cat) categoryNames.indexOf(fullName);
    }
    else
    {
        category = (Cat) fullName;
    }
    if (catName.isEmpty())
    {
        //throw error "there is no category name"
    }
    YAML::Node specs;
    if (streamedYamlTypesheet["TypeSheet"]["entries"]["categories"][catName.toStdString()]["specifications"])
    {
        specs = streamedYamlTypesheet["TypeSheet"]["entries"]["categories"][catName.toStdString()]["specifications"];
    }
    if (prods.IsNull())
    {
        rules[category] << (Rule());
    }
    int i = 0;
    assert(prods.IsSequence());
    for (YAML::const_iterator iter {prods.begin()}; iter != prods.end(); ++iter)
    {
        if (!(*iter).IsScalar() && (*iter)["productions"])
        {
            Rule rule;
            QString suffix = "";
            YAML::Node newProds = (*iter)["productions"];
        }
        else if (!(*iter).IsScalar() && (*iter)["input"])
        {
            if (!categoryNames.contains(prods["input"].as<QString>()))
            {
                //throw error (prods["input"]).as<QString>() + "is not in the list")
            }
            rule << (Cat) categoryNames.indexOf(prods["input"].as<QString>());
            if (!rule.isEmpty())
            {
                rules[category] << (Rule() << rule);
            }
        }
        else if (!(*iter).IsScalar() && (*iter)["alternative"])
        {
            getRule(rule,catName,suffix,(*iter)["alternative"]);
            if ((*iter)["alternative"][0].IsScalar() || !((*iter)["alternative"][0]["alternative"]))
            {
                rules[category] << (Rule() << rule);
            }
        }
        else if (!(*iter).IsScalar() && (*iter)["or"])
        {
            Rule rule;
            if ((*iter)["or"][0].IsNull())
            {
                rules[category] << Rule();
            }
            else
            {
                getRule(rule,catName,suffix,(*iter)["or"]);
                if ((*iter)["or"][0].IsScalar() || !((*iter)["or"][0]["alternative"]))
                {
                    rules[category] << (Rule() << rule);
                }
            }
        }
        else if (!(*iter).IsScalar() && (*iter)["CatVar"])
        {
            if (specs.IsNull())
            {
                //throw error ("Rule "+catName+" contains a category variable but the category has no specifications")
            }
            assert(specs.IsMap());
            if (specs["UnionSpec"])
            {
                QString cat;
                YAML::Node specVals = specs["UnionSpec"];
                assert(specVals.IsSequence());
                for (YAML::const_iterator entryit {specVals.begin()}; entryit != specVals.end(); ++entryit)
                {
                    if ((*entryit).IsMap())
                    {
                        QString catAlias = entryit->begin()->first.as<QString>();
                        QString cat = (entryit->begin()->second).as<QString>();
                        if (((*iter)["CatVar"]).as<QString>() == catAlias)
                        {
                            if(typeid(Cat) == typeid(int))
                            {
                                rules[category] << (Rule() << (Cat) categoryNames.indexOf(cat));
                            }
                            else
                            {
                                rules[category] << (Rule() << (Cat) cat);
                            }
                        }
                    }
                    else
                    {
                        QString cat = (*entryit).second.as<QString>();
                        if (!categoryNames.contains(cat))
                        {
                            qFatal(cat.toLatin1() + " is not in the Catlist\n");
                        }
                        if(typeid(Cat) == typeid(int))
                        {
                            rule << (Cat) categoryNames.indexOf(cat);
                        }
                        else
                        {
                            rule << (Cat) cat;
                        }
                    }
                }
            }
            for  (YAML::const_iterator specit {specs.begin()}; specit != specs.end(); ++specit)
            {
                if (specit->first.as<QString>() != "UnionSpec")
                {
                    QString catVar = (*iter)["CatVar"].as<QString>();
                    YAML::Node catsAssignement = specit->second;
                    assert(catsAssignement.IsMap());
                    QList<Rule> tempRules;
                    for (YAML::const_iterator entryit {catsAssignement.begin()}; entryit != catsAssignement.end(); ++entryit)
                    {
                        QString catAlias = entryit->first.as<QString>();
                        if (catAlias == catVar)
                        {
                            auto assignedCats = entryit->second;
                            if (assignedCats.IsMap())
                            {
                                for (YAML::const_iterator catit {assignedCats.begin()}; catit != assignedCats.end(); ++catit)
                                {
                                    Rule r;
                                    r << (*catit).second.as<QString>();
                                    tempRules << r;
                                }
                            }
                            else
                            {
                                QString cat;
                                cat = entryit->second.as<QString>();
                                if (!categoryNames.contains(cat))
                                {
                                    qFatal(cat.toLatin1() + " is not in the Catlist\n");
                                }
                                if (tempRules.empty())
                                {
                                    if(typeid(Cat) == typeid(int))
                                    {
                                        rule << (Cat) categoryNames.indexOf(cat);
                                    }
                                    else
                                    {
                                        rule << (Cat) cat;
                                    }
                                }
                                else
                                {
                                    // since the rules[category] can contain more than one rule we have to add the current cat
                                    // to every rule of rules[category]
                                    // TODO: also for other entries, not only catVars!!
                                    for (int i=0; i < tempRules.size(); ++i)
                                    {
                                        if(typeid(Cat) == typeid(int))
                                        {
                                            tempRules[i] << (Cat) categoryNames.indexOf(cat);
                                        }
                                        else
                                        {
                                            tempRules[i] << (Cat) cat;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if (!tempRules.empty())
                    {
                        rules[category] = tempRules;
                    }
                }
            }
        }
        else if (!(*iter).IsScalar() && (*iter)["link"])
        {
            if (!categoryNames.contains((*iter)["link"].as<QString>()))
            {
                qFatal(((*iter)["link"]).as<QString>().toLatin1() + " is not in the Catlist\n");
            }
            YAML::const_iterator itNext = iter;
            ++itNext;
            if (itNext != prods.end())
            {
                if (!(*itNext).IsScalar() && (*itNext)["match"])
                {
                    matchChar = (*iter)["link"].as<QString>();
                    YAML::Node newProd = (*itNext)["match"];
                    for  (YAML::const_iterator elemit {newProd.begin()}; elemit != newProd.end(); ++elemit)
                    {
                        if (!(*elemit).IsScalar() && (*elemit)["Maximal"])
                        {
                        }
                        else if (!(*elemit).IsScalar() && (*elemit)["Expect"])
                        {
                            expectNr += 1;
                            QString suffix = "Expect" + QString::number(expectNr);
                            QString catNameExpect = catName + suffix;
                            categoryNames << catNameExpect;
                            QString suffix2 = "Expect" + QString::number(expectNr) + "_expect";
                            QString catNameCharExpect = catName + suffix2;
                            categoryNames << catNameCharExpect;
                            Rule r;
                            if (!rules.contains(catNameCharExpect))
                            {
                                rules[catNameCharExpect] << getRule(r,catName,suffix2,(*elemit)["Expect"]);
                            }
                            Rule ruleExp;
                            if(typeid(Cat) == typeid(int))
                            {
                                ruleExp << (Cat) categoryNames.indexOf(matchChar);
                                ruleExp.nextTokenConstraints.expect << (Cat) categoryNames.indexOf(catNameCharExpect);
                                rules[catNameExpect] << ruleExp;
                                rule << (Cat) categoryNames.indexOf(catNameExpect);
                            }
                            else
                            {
                                ruleExp << (Cat) matchChar;
                                ruleExp.nextTokenConstraints.expect << (Cat) catNameCharExpect;
                                rules[catNameExpect] << ruleExp;
                                rule << (Cat) catNameExpect;
                            }
                        }
                        else if (!(*elemit).IsScalar() && (*elemit)["Taboo"])
                        {
                            tabooNr += 1;
                            QString suffix = "Taboo" + QString::number(tabooNr);
                            QString catNameTaboo = catName + suffix;
                            categoryNames << catNameTaboo;
                            QString suffix2 = "Taboo" + QString::number(tabooNr) + "_taboo";
                            QString catNameCharTaboo = catName + suffix2;
                            categoryNames << catNameCharTaboo;
                            Rule r;
                            if (!rules.contains(catNameCharTaboo))
                            {
                                rules[catNameCharTaboo] << getRule(r,catName,suffix2,(*elemit)["Taboo"]);
                            }
                            Rule ruleTab;
                            if(typeid(Cat) == typeid(int))
                            {
                                ruleTab << (Cat) categoryNames.indexOf(matchChar);
                                ruleTab.nextTokenConstraints.taboo << (Cat) categoryNames.indexOf(catNameCharTaboo);
                                rules[catNameTaboo] << ruleTab;
                                rule << (Cat) categoryNames.indexOf(catNameTaboo);
                            }
                            else
                            {
                                ruleTab << (Cat) matchChar;
                                ruleTab.nextTokenConstraints.taboo << (Cat) catNameCharTaboo;
                                rules[catNameTaboo] << ruleTab;
                                rule << (Cat) catNameTaboo;
                            }
                        }
                        else if (!(*elemit).IsScalar() && (*elemit)["Except"])
                        {
                            exceptNr += 1;
                            QString suffix = "Except" + QString::number(exceptNr);
                            QString catNameExcept = catName + suffix;
                            categoryNames << catNameExcept;
                            QString suffix2 = "Except" + QString::number(exceptNr) + "_taboo";
                            QString catNameCharExcept = catName + suffix2;
                            categoryNames << catNameCharExcept;
                            Rule r;
                            if (!rules.contains(catNameCharExcept))
                            {
                                rules[catNameCharExcept] << getRule(r,catName,suffix2,(*elemit)["Except"]);
                            }
                            Rule ruleTab;
                            if(typeid(Cat) == typeid(int))
                            {
                                ruleTab << (Cat) categoryNames.indexOf(matchChar);
                                ruleTab.nextTokenConstraints.taboo << (Cat) categoryNames.indexOf(catNameCharExcept);
                                rules[catNameExcept] << ruleTab;
                                rule << (Cat) categoryNames.indexOf(catNameExcept);
                            }
                            else
                            {
                                ruleTab << (Cat) matchChar;
                                ruleTab.nextTokenConstraints.taboo << (Cat) catNameCharExcept;
                                rules[catNameExcept] << ruleTab;
                                rule << (Cat) catNameExcept;
                            }
                        }
                    }
                }
                else
                {
                    if(typeid(Cat) == typeid(int))
                    {
                        rule << (Cat) categoryNames.indexOf((*iter)["link"].as<QString>());
                    }
                    else
                    {
                        rule << (Cat) (*iter)["link"].as<QString>();
                    }
                }
            }
            else
            {
                if(typeid(Cat) == typeid(int))
                {
                    rule << (Cat) categoryNames.indexOf((*iter)["link"].as<QString>());
                }
                else
                {
                    rule << (Cat) (*iter)["link"].as<QString>();
                }
            }
        }
        else if (!(*iter).IsScalar() && (*iter)["once"])
        {
            onceNr += 1;
            QString suffix = "once" + QString::number(onceNr);
            categoryNames << (catName+suffix);
            if(typeid(Cat) == typeid(int))
            {
                rule << (Cat) categoryNames.indexOf(catName + suffix);
            }
            else
            {
                rule << (Cat) (catName + suffix);
            }
            YAML::Node newProds;
            newProds = (*iter)["once"];
            Rule rule3;
            getRule(rule3,catName,suffix,newProds);
        }
        else if (!(*iter).IsScalar() && (*iter)["optional"])
        {
            optNr += 1;
            QString suffix = "opt" + QString::number(optNr);
            categoryNames << (catName+suffix);
            if(typeid(Cat) == typeid(int))
            {
                rule << (Cat) categoryNames.indexOf(catName + suffix);
            }
            else
            {
                rule << (Cat) catName + suffix;
            }
            YAML::Node empt;
            YAML::Node opt1;
            YAML::Node opt2;
            opt1["alternative"] = (*iter)["optional"];
            opt2["or"].push_back(empt);
            YAML::Node newProds;
            newProds.push_back(opt1);
            newProds.push_back(opt2);
            Rule rule3;
            getRule(rule3,catName,suffix,newProds);
        }
        else if (!(*iter).IsScalar() && (*iter)["multiple"])
        {
            optNr += 1;
            suffix = "multiple" + QString::number(optNr);
            categoryNames << (catName+suffix);
            if(typeid(Cat) == typeid(int))
            {
                rule << (Cat) categoryNames.indexOf(catName+suffix);
            }
            else
            {
                rule << (Cat) (catName+suffix);
            }
            YAML::Node thisProd;
            thisProd = (*iter)["multiple"];
            Rule rule;
            YAML::Node newProds;
            YAML::Node added1;
            YAML::Node added2;
            for(auto el: thisProd)
            {
                YAML::Node elcopy;
                added1["alternative"].push_back(el);
                if (el["or"])
                {
                    for (auto item : el["or"])
                    {
                        elcopy["or"].push_back(item);
                    }
                    elcopy["or"].push_back(catName+suffix);
                    added2["or"].push_back(elcopy);
                }
                if (el["alternative"])
                {
                    for (auto item : el["alternative"])
                    {
                        elcopy["alternative"].push_back(item);
                    }
                    elcopy["alternative"].push_back(catName+suffix);
                    added2["or"].push_back(elcopy);
                }
            }
            newProds.push_back(added1);
            newProds.push_back(added2);
            getRule(rule,catName,suffix,newProds);
        }
        else if (!(*iter).IsScalar() && (*iter)["anyTimes"])
        {
            optNr += 1;
            suffix = "anyTimes" + QString::number(optNr);
            categoryNames << (catName+suffix);
            if(typeid(Cat) == typeid(int))
            {
                rule << (Cat) categoryNames.indexOf(catName+suffix);
            }
            else
            {
                rule << (Cat) (catName+suffix);
            }
            YAML::Node thisProd;
            thisProd = (*iter)["anyTimes"];
            Rule rule;
            YAML::Node newProds;
            YAML::Node empt;
            YAML::Node added1;
            YAML::Node added2;
            added1["alternative"].push_back(empt);
            for(auto el: thisProd)
            {
                if (el["or"])
                {
                    el["or"].push_back(catName+suffix);
                    added2["or"].push_back(el);
                }
                if (el["alternative"])
                {
                    el["alternative"].push_back(catName+suffix);
                    added2["or"].push_back(el);
                }
            }
            newProds.push_back(added1);
            newProds.push_back(added2);
            getRule(rule,catName,suffix,newProds);
        }
        if ((*iter).IsScalar())
        {
            QString q = (*iter).as<QString>();
            if (categoryNames.contains(q))
            {
                if(typeid(Cat) == typeid(int))
                {
                    rule << (Cat) categoryNames.indexOf(q);
                }
                else
                {
                    rule << (Cat) q;
                }
            }
        }
    } //endfor
    return rule;
}

void RuleSetter::printRulesToYaml(const QString &fileName)
{
    QFile file(fileName);
    QTextStream output(&file);
    output.setCodec(QTextCodec::codecForName("UTF-8"));
    file.open(QFile::WriteOnly | QFile::Text);
    assert(!rules.isEmpty());
    for(QHash<Cat, QList<DynGenPar::Rule> >::iterator rit {rules.begin()}; rit != rules.end(); rit++)
    {
        if (categoryNames.size() < rit.key()||rit.key() < 1)
        {
            // throw error
        }
        output << rit.key() << ":\n";
        int ruleNr = 0;
        for (QList<DynGenPar::Rule>::iterator rulesit {rit.value().begin()}; rulesit != rit.value().end(); rulesit++)
        {
            output <<  "  - rule" << QString::number(++ruleNr) << ":\n";
            if ((*rulesit).isEmpty())
            {
                output << "    - \"";
                output << "\"\n";
            }
            else
            {
                for (Rule::iterator ruleit = rulesit->begin(); ruleit != rulesit->end(); ruleit++)
                {
                    if (categoryNames.size() < *ruleit || rit.key() < 1)
                    {
                        //throw error
                    }
                    output << "    - \"";
                    output << (*ruleit) << (*ruleit).at(0).unicode();
                    output << "\"\n";
                }
            }
            if(!(*rulesit).nextTokenConstraints.taboo.isEmpty())
            {
                for(Cat taboo: (*rulesit).nextTokenConstraints.taboo)
                {
                    output << "    - taboo: \"" << taboo << "\"\n";
                }
            }
            if(!(*rulesit).nextTokenConstraints.expect.isEmpty())
            {
                for(Cat expected: (*rulesit).nextTokenConstraints.expect)
                {
                    output << "    - expected: \"" << expected << "\"\n";
                }
            }
            output << "\n";
        }
    }
    file.close();
}
