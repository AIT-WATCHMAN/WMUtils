#!/bin/bash

# Since system dependencies, especially on clusters, are a pain
# Lets just pre-install everything (except GCC for now).
# Assume one modules loads a good version of gcc

# Todo:
# --help, -h
# interactive mode
# Minimum gcc

# CLEANSE! -- maybe not
#[ "$(env | /bin/sed -r -e '/^(PWD|SHLVL|_)=/d')" ] && exec -c $0

function install(){
  help $@
  procuse=$(getnproc $@)
  # End testing
  export CC="$(command -v gcc)"
  export CXX="$(command -v g++)"
  
  # Check requirements; Git && GCC
  if ! [ -x "$(command -v gcc)" ]; then
    echo "gcc not installed"
    exit 1
  fi
  if ! [ -x "$(command -v git)" ]; then
    echo "git not installed"
    exit 1
  fi
  
  skipping=false
  skip_cmake=false
  skip_python=false
  skip_root=false
  skip_geant=false
  skip_ratpac=false
  skip_sibyl=false
  for element in $@;
  do
    if [ "$skipping" = true ]
    then
      if [ $element == "cmake" ]
      then
        skip_cmake=true
      fi
      if [ $element == "python" ]
      then
        skip_python=true
      fi
      if [ $element == "root" ]
      then
        skip_root=true
      fi
      if [ $element == "geant4" ]
      then
        skip_geant=true
      fi
      if [ $element == "ratpac" ]
      then
        skip_ratpac=true
      fi
      if [ $element == "sibyl" ]
      then
        skip_sibyl=true
      fi
    fi
    if [ $element == "--skip" ]
    then
      skipping=true;
    fi
  done
  
  boolOnly=false
  for element in $@;
  do
    if [ "$boolOnly" = true ]
    then
      if [ $element == "cmake" ]
      then
        skip_cmake=false
      fi
      if [ $element == "python" ]
      then
        skip_python=false
      fi
      if [ $element == "root" ]
      then
        skip_root=false
      fi
      if [ $element == "geant4" ]
      then
        skip_geant=false
      fi
      if [ $element == "ratpac" ]
      then
        skip_ratpac=false
      fi
      if [ $element == "sibyl" ]
      then
        skip_sibyl=false
      fi
    fi
    if [ $element == "--only" ]
    then
      # Only will overwrite the skipping rules
      boolOnly=true
      skip_cmake=true
      skip_python=true
      skip_root=true
      skip_geant=true
      skip_ratpac=true
    fi
  done
  
  prefix=$(pwd)/local
  mkdir -p $prefix/bin
  export PATH=$prefix/bin:$PATH
  export LD_LIBRARY_PATH=$prefix/lib:$LD_LIBRARY_PATH
  
  # Install cmake
  if ! [ "$skip_cmake" = true ]
  then
    git clone https://github.com/Kitware/CMake.git cmake_src
    mkdir -p cmake_build
    #mkdir -p cmake
    cd cmake_build
    ../cmake_src/bootstrap --prefix=../local && make -j$procuse && make install
    cd ../
    rm -rf cmake_src cmake_build
  fi
  
  # Install python
  if ! [ "$skip_python" = true ]
  then
    git clone https://github.com/python/cpython.git --single-branch --branch 3.7 python_src
    cd python_src
    ./configure --prefix=$prefix --enable-shared
    make -j$procuse
    make install
    cd ../
    rm -rf python_src
    python3 -m pip install --upgrade pip
    python3 -m pip install numpy scipy matplotlib PyOpenGL \
      PyQt5 Markdown uproot pyqtgraph docopt
  fi
  
  # Install root
  if ! [ "$skip_root" = true ]
  then
    #git clone https://github.com/root-project/root.git --single-branch --branch v6-18-00-patches root_src
    git clone https://github.com/root-project/root.git --single-branch --branch v6-18-00 root_src
    mkdir -p root_build
    cd root_build
    cmake -D minuit2=ON -DCMAKE_INSTALL_PREFIX=$prefix -DPYTHON_EXECUTABLE=$(command -v python3) ../root_src
    make -j$procuse
    make install
    cd ../
    rm -rf root_src root_build
  fi
  
  # Install Geant4
  if ! [ "$skip_geant" = true ]
  then
    git clone https://github.com/geant4/geant4.git --single-branch --branch geant4-10.4-release geant_src
    mkdir -p geant_build
    cd geant_build
    cmake -DCMAKE_INSTALL_PREFIX=$prefix ../geant_src -DGEANT4_BUILD_EXPAT=OFF -DGEANT4_BUILD_MULTITHREADED=OFF -DGEANT4_USE_QT=ON -DGEANT4_INSTALL_DATA=ON -DGEANT4_INSTALL_DATA_TIMEOUT=15000
    make -j$procuse
    make install
    cd ../
    rm -rf geant_src geant_build
  fi
  
  # Install rat-pac
  #if [ $(root-config --version) ]
  if ! [ "$skip_ratpac" = true ]
  then
    source $prefix/bin/thisroot.sh
    source $prefix/bin/geant4.sh
    git clone https://github.com/ait-watchman/rat-pac.git ratpac
    cd ratpac
    cmake . -Bbuild
    cmake --build build -- -j$procuse
    source ratpac.sh
    cd ../
  fi

  #if ! [ "$skip_sibyl" = true ]
  #then
  #  source $prefix/bin/thisroot.sh
  #  source $prefix/bin/geant4.sh
  #  python3 -m pip install --user git+https://github.com/ait-watchman/sibyl@miles#egg=sibyl
  #fi
  
  outfile="env.sh"
  printf "export PATH=$prefix/bin:\$PATH\n" > $outfile
  printf "export LD_LIBRARY_PATH=$prefix/lib:\$LD_LIBRARY_PATH\n" >> $outfile
  printf "pushd $prefix/bin 2>&1 >/dev/null\nsource thisroot.sh\nsource geant4.sh\npopd 2>&1 >/dev/null\n" >> $outfile
  printf "source $prefix/../ratpac/ratpac.sh" >> $outfile
}

function help()
{
  for element in $@
  do
    if [[ $element =~ "-h" ]];
    then
      printf "Watchman Installer -- in progress\n"
      exit 0
    fi
  done
}

function getnproc()
{
  local nproc=1
  for element in $@
  do
    if [[ $element =~ "-j" ]];
    then
      nproc=$(echo $element | sed -e 's/-j//g')
    fi
  done
  echo $nproc
}

install $@
