/* OConcise: OConciseParser
   Copyright (C) 2019-2026 Romana Ježek

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.*/

#include "oconciseParser.h"

QStringList OConciseParser::printParseTreeToJson(Node node)
{
    QStringList result;
    QList<Node> nodeStack;
    QList<QPair<Cat,Alternative>> alternativeStack;
    QList<int> altNrs;
    QList<int> nodeNrs;
    QPair<Cat,Alternative> alt;
    int nodeNr = 1;
    int childNr = 1;
    int altNr = 0;
    int chNr = 0;
    nodeStack.push_back(node);
    nodeNrs.push_back(nodeNr);
    int currentNode = nodeNr;
    bool firstNode = true;
    result << "{\n";
    while (!nodeStack.isEmpty() || !alternativeStack.isEmpty())
    {
        if (nodeNrs.contains(currentNode))
        {
            assert(!nodeStack.isEmpty());
            node = nodeStack.takeFirst();
            assert(!nodeNrs.isEmpty());
            nodeNr = nodeNrs.takeFirst();
            if (node.children.size() > 1)
            {
                if (!firstNode)
                {
                    result << ",\n";
                }
                result << "\"node" << QString::number(nodeNr) << "\": {\n";
                result << "  \"Type\": \"" << node.cat << "\",\n";
                result << "  \"alternatives\": {\n";
                chNr = 0;
                bool firstAlt = true;
                for (Alternative alternative: node.children)
                {
                    if (!firstAlt)
                    {
                        result << ",\n";
                    }
                    result << "    \"alternative" << QString::number(++chNr) << "\": \"node" << QString::number(++childNr) << "\"";
                    alternativeStack.push_back(qMakePair(node.cat,alternative));
                    altNrs.push_back(childNr);
                    firstAlt = false;
                }
                result << "    \n}"; // close alternatives
                result << "  \n}"; // close node entries
            }
            else
            {
                if (node.data.isNull() && !node.children.at(0).isEmpty())
                {
                    if (!firstNode)
                    {
                        result << ",\n";
                    }
                    result << "\"node" << QString::number(nodeNr) << "\": {\n";
                    result << "  \"Type\": \"" << node.cat << "\",\n";
                    result << "  \"children\": {\n";
                    chNr = 0;
                    bool firstChild = true;
                    for (Node child: node.children.at(0))
                    {
                        if (!firstChild)
                        {
                            result << ",\n";
                        }
                        result << "    \"child" << QString::number(++chNr) << "\": \"node" << QString::number(++childNr) << "\"";
                        nodeStack.push_back(child);
                        nodeNrs.push_back(childNr);
                        firstChild = false;
                    }
                    result << "    \n}";  // close children
                    result << "  \n}"; // close node entries
                }
                else
                {
                    if (!firstNode)
                    {
                        result << ",\n";
                    }
                    result << "\"node" << QString::number(nodeNr) << "\": {\n";
                    result << "  \"Type\": \"String\"" << ",\n";
                    if (node.data == "\t" || node.data == "\\")
                    {
                        result << "  \"content\": \"" << "\\" << node.data.toString() << "\"\n";
                    }
                    else
                    {
                        result << "  \"content\": \"" << node.data.toString() << "\"\n";
                    }
                    result << "  \n}";
                }
            }
        }
        else if (altNrs.contains(currentNode))
        {
            assert(!alternativeStack.isEmpty());
            alt = alternativeStack.takeFirst();
            assert(!altNrs.isEmpty());
            altNr = altNrs.takeFirst();
            if (!firstNode)
            {
                result << ",\n";
            }
            result << "\"node" << QString::number(altNr) << "\": {\n";
            result << "  \"Type\": \"" << alt.first << "\",\n";
            result << "  \"children\": {\n";
            chNr = 0;
            bool firstChild = true;
            for (Node node: alt.second)
            {
                if (!firstChild)
                {
                    result << ",\n";
                }
                result << "    \"child" << QString::number(++chNr) << "\": \"node" << QString::number(++childNr) << "\"";
                nodeStack.push_back(node);
                nodeNrs.push_back(childNr);
                firstChild = false;
            }
            result << "    \n}";  // close children
            result << "  \n}"; // close node entries
        }
        firstNode = false;
        currentNode++;
    }
    result << "\n}";
    return result;
}
