/* OConcise - CharacterTokenSource
   Copyright (C) 2026 Romana Ježek (University of Vienna)

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details. */

#include "characterTokenSource.h"

Cat CharacterTokenSource::readToken()
{
    if (textStream->atEnd()) return Cat();
    Cat cat;
    QString tokenString;
    tokenString = textStream->read(1);
    if (textStream->atEnd())
    {
        return Cat();
    }
    else
    {
        cat = tokenString;
    }
    if (!tokenString.isEmpty())
    {
        inputTokens << qMakePair(cat,tokenString);
        tree = Node(cat);
        tree.data = tokenString.trimmed();
        return cat;
    }
    return Cat();
}
