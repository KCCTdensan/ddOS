set -e

## edk2
cd edk2
source ./edksetup.sh > /dev/null
sed -ie '/ACTIVE_PLATFORM/ s/=.*$/= ddLoaderPkg\/ddLoaderPkg.dsc/g;
         /TARGET_ARCH/ s/=.*$/= X64/g;
         /TOOL_CHAIN_TAG/ s/=.*$/= CLANG38/g;
         s/\r//g' Conf/target.txt
sed -ie '/CLANG38/ s/-flto//g;
         s/\r//g' Conf/tools_def.txt
cd ..

## auto create symlink

if [ -d src/loader ];then
  ln -s ../src/loader edk2/ddLoaderPkg
fi

set +e
