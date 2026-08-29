/* OConcise - CharacterTokenSource
   Copyright (C) 2026 Romana Ježek (University of Vienna)

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   The CharakterTokenSource reads the a text and
   creates a token for every symbol. The codec of the text
   is set to Utf-8.*/

#include "dyngenpar.h"
#include <QString>
#include <QList>
#include <QTextStream>
#include <QFile>
#include <QPair>

using namespace DynGenPar;

class CharacterTokenSource : public TokenSource
{
public:
    QList<QPair<DynGenPar::Cat,QString>> inputTokens;
    CharacterTokenSource(const QString &fileName) : TokenSource()
    {
        QIODevice *device;
        device = new QFile(fileName);
        device->open(QIODevice::ReadOnly);
        textStream = new QTextStream(device);
        textStream->setCodec("UTF-8");
        tree = Node();
        inputTokens = QList<QPair<Cat,QString>>();
        currPos = 0;
    }
    virtual ~CharacterTokenSource()
    {
        delete textStream;
    }
protected:
    virtual DynGenPar::Cat readToken();
private:
    QTextStream *textStream;
};
Q_DECLARE_TYPEINFO(CharacterTokenSource, Q_MOVABLE_TYPE);
