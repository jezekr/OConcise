#############################################################################################
################################## setup.jl #################################################
#############################################################################################
#
# This is the setup for the OConcise package
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


using Pkg

oconcisePath = pwd()
Pkg.develop("libcxxwrap_julia_jll")
import libcxxwrap_julia_jll
libcxxwrap_julia_jll.dev_jll()
pathVar = pathof(libcxxwrap_julia_jll)
jllPath = split(pathVar,"/src/")[1]
juliaPath = Sys.BINDIR
juliaPrefix = split(Sys.BINDIR,"/bin")[1]

if !isfile("$jllPath/override/libcxxwrap-julia/include/jlcxx/jlcxx.hpp")
  cd("$jllPath/override")
  run(`wget -O libcxxwrap.tar.gz https://github.com/JuliaInterop/libcxxwrap-julia/archive/refs/tags/v0.14.11.tar.gz`)
  run(`tar -xf libcxxwrap.tar.gz`)
  if Sys.iswindows()
    run(`rename libcxxwrap-julia-0.14.11 libcxxwrap-julia`)
    run(`del /f "*"`)
  else
    run(`mv libcxxwrap-julia-0.14.11 libcxxwrap-julia`)
    run(`rm -rf "*"`)
  end
  run(`cmake -D Julia_PREFIX=$juliaPrefix $jllPath/override/libcxxwrap-julia`)
  run(`cmake --build . --config Release`)
  cd(oconcisePath)
end

if !isfile("$oconcisePath/yaml-cpp/include/yaml-cpp/yaml.h")
  #install yaml-cpp
  if !isdir("$oconcisePath/yaml-cpp")
    run(`mkdir yaml-cpp`)
  end
  cd("yaml-cpp")
  run(`wget -O yaml-cpp.tar.gz https://github.com/jbeder/yaml-cpp/releases/download/yaml-cpp-0.9.0/yaml-cpp-yaml-cpp-0.9.0.tar.gz`)
  run(`tar -xf yaml-cpp.tar.gz`)  
  run(`mkdir build`)
  cd("build")
  run(`cmake ..`)
  run(`make`)
  cd(oconcisePath)
end

if !isfile("$oconcisePath/parser/qtyaml.h")
  run(`wget -O parser/qtyaml.h https://gist.githubusercontent.com/brcha/d392b2fe5f1e427cc8a6/raw/7cf1063ad74ec5d65dc200dd7df739794545bed6/qtyaml.h`)
end

if !isfile("$oconcisePath/parser/dyngenpar.cpp")
  if !isfile("$oconcisePath/parser/dyngenpar-12.tar.xz")
    run(`wget --tries=2 --timeout=200 -nc -P ./parser https://github.com/Computational-Mathematics-Vienna/FMathL/raw/refs/heads/main/dyngenpar-12.tar.xz`)
  end  
  run(`tar -xf  parser/dyngenpar-12.tar.xz -C ./parser dyngenpar-12/dyngenpar.cpp  --strip-components=1`)
end

if !isfile("$oconcisePath/parser/dyngenpar.h")
  if !isfile("$oconcisePath/parser/dyngenpar-12.tar.xz")
    run(`wget --tries=2 --timeout=100 -nc -P ./parser https://github.com/Computational-Mathematics-Vienna/FMathL/raw/refs/heads/main/dyngenpar-12.tar.xz`)
  end  
  run(`tar -xf  parser/dyngenpar-12.tar.xz -C ./parser dyngenpar-12/dyngenpar.h  --strip-components=1`)
end

if !isfile("$oconcisePath/parser/priorityqueue.h")
  if !isfile("$oconcisePath/parser/dyngenpar-12.tar.xz")
    run(`wget --tries=2 --timeout=100 -nc -P ./parser https://github.com/Computational-Mathematics-Vienna/FMathL/raw/refs/heads/main/dyngenpar-12.tar.xz`)
  end  
  run(`tar -xf  parser/dyngenpar-12.tar.xz -C ./parser dyngenpar-12/priorityqueue.h  --strip-components=1`)
end

if isfile("$oconcisePath/parser/dyngenpar-12.tar.xz")
  if Sys.iswindows()
    run(`del $oconcisePath/parser/dyngenpar-12.tar.xz`)
  else
    run(`rm $oconcisePath/parser/dyngenpar-12.tar.xz`)
  end
end

if !isfile("$oconcisePath/shared/callParser.so")
  #create shared file callParser.so, you must install qt and save the directory in the system variable QTPATH (e.g. /usr/include/x86_64-linux-gnu/qt5)
  QTPATH = ENV["QTPATH"]
  run(`g++ -std=c++20 -shared -fPIC parser/dyngenpar.cpp parser/characterTokenSource.cpp parser/ruleSetter.cpp parser/oconciseParser.cpp parser/callParser.cpp -I/yaml-cpp/include -Lyaml-cpp/build -lyaml-cpp -lQt5Core -I$QTPATH/QtCore -I$QTPATH -I$jllPath/override/libcxxwrap-julia/include -I$juliaPrefix/include/julia -o ./shared/callParser.so`)
end

if !isfile("$oconcisePath/vampire/vampire")
  if Sys.iswindows()
      if Sys.ARCH == :x86_64
        run(`wget -O vampire/vampire.zip https://github.com/vprover/vampire/releases/download/v5.1.0/vampire-Windows-X64.zip`)      
      elseif Sys.ARCH == :aarch64
        run(`wget -O vampire/vampire.zip https://github.com/vprover/vampire/releases/download/v5.1.0/vampire-Windows-ARM64.zip`)
      end
  elseif Sys.islinux()
      if Sys.ARCH == :x86_64
        run(`wget -O vampire/vampire.zip https://github.com/vprover/vampire/releases/download/v5.1.0/vampire-Linux-X64.zip`)
      elseif Sys.ARCH == :aarch64
        run(`wget -O vampire/vampire.zip https://github.com/vprover/vampire/releases/download/v5.1.0/vampire-Linux-ARM64.zip`)
      end
  elseif Sys.isapple()
      if Sys.ARCH == :x86_64
        run(`wget -O vampire/vampire.zip https://github.com/vprover/vampire/releases/download/v5.1.0/vampire-macOS-X64.zip`)
      elseif Sys.ARCH == :aarch64
        run(`wget -O vampire/vampire.zip https://github.com/vprover/vampire/releases/download/v5.1.0/vampire-macOS-ARM64.zip`)
      end
  end
  run(`unzip vampire/vampire.zip -d vampire`)
  if Sys.iswindows()
    run(`del vampire/vampire.zip`)
  else
    run(`rm vampire/vampire.zip`)
  end
end

# install necessary packages
Pkg.add("YAML")
Pkg.add("JSON")
Pkg.add("CxxWrap")
Pkg.add("OrderedCollections")
Pkg.add("DataFrames")
Pkg.add("DotEnv")

#create .env file for environment variable OCONCISE
fileName = ".env"
open(fileName, "w") do io                   
  write(io, "OCONCISE=" * oconcisePath)
end
