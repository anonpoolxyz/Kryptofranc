#!/bin/bash
echo "-----------------------------------------------------------"
echo "bitFranc Installer: WINDOWS version 1.1"
echo "Options:"
echo "  - git=yes": will clone bitcoin and recompile all
echo "-----------------------------------------------------------"

sudo apt-get --assume-yes update
sudo apt-get --assume-yes upgrade
sudo apt-get --assume-yes install git
sudo apt-get --assume-yes install build-essential
sudo apt-get --assume-yes install qt5-default qttools5-dev-tools
sudo apt-get --assume-yes install autoconf libtool pkg-config libboost-all-dev libssl-dev libprotobuf-dev protobuf-compiler libevent-dev libqt4-dev libcanberra-gtk-module

if [ $opt -git yes ]; then
  git clone https://github.com/bitcoin/bitcoin.git
fi

sudo cp -r bitcoin ~/
sudo cp assets_installer/bitfranc_replace/modaloverlay.ui ~/bitcoin/src/qt/forms/
sudo cp assets_installer/bitfranc_replace/overviewpage.ui ~/bitcoin/src/qt/forms/
sudo cp assets_installer/bitfranc_replace/guiutil.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/update-translations.py ~/bitcoin/contrib/devtools/
sudo cp assets_installer/bitfranc_replace/bitcoin-cli.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/bitcoind.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/init.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/key.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/net.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/util.h ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/validation.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/addressbookpage.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/askpassphrasedialog.cpp ~/bitcoin/src/qt/forms/
sudo cp assets_installer/bitfranc_replace/bitcoin.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/bitcoingui.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/blockchain.cpp ~/bitcoin/src/rpc/
sudo cp assets_installer/bitfranc_replace/db.cpp ~/bitcoin/src/wallet/
sudo cp assets_installer/bitfranc_replace/editaddressdialog.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/feature_help.py ~/bitcoin/test/functional/
sudo cp assets_installer/bitfranc_replace/interface_bitcoin_cli.py ~/bitcoin/test/functional/
sudo cp assets_installer/bitfranc_replace/interface_rest.py ~/bitcoin/test/functional/
sudo cp assets_installer/bitfranc_replace/intro.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/mempool_persist.py ~/bitcoin/test/functional/
sudo cp assets_installer/bitfranc_replace/mining.cpp ~/bitcoin/src/rpc/
sudo cp assets_installer/bitfranc_replace/mininode.py ~/bitcoin/test/functional/test_framework/
sudo cp assets_installer/bitfranc_replace/misc.cpp ~/bitcoin/src/rpc/
sudo cp assets_installer/bitfranc_replace/net2.cpp ~/bitcoin/src/rpc/
sudo mv ~/bitcoin/test/functional/net2.cpp ~/bitcoin/src/rpc/net.cpp
sudo cp assets_installer/bitfranc_replace/openuridialog.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/paymentserver.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/rawtransaction.cpp ~/bitcoin/src/rpc/
sudo cp assets_installer/bitfranc_replace/rpcdump.cpp ~/bitcoin/src/wallet/
sudo cp assets_installer/bitfranc_replace/rpc_fundrawtransaction.py ~/bitcoin/test/functional/
sudo cp assets_installer/bitfranc_replace/rpc_rawtransaction.py ~/bitcoin/test/functional/
sudo cp assets_installer/bitfranc_replace/rpcwallet.cpp ~/bitcoin/src/wallet/
sudo cp assets_installer/bitfranc_replace/sendcoinsdialog.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/server.cpp ~/bitcoin/src/rpc/
sudo cp assets_installer/bitfranc_replace/test_runner.py ~/bitcoin/test/functional/
sudo cp assets_installer/bitfranc_replace/utilitydialog.cpp ~/bitcoin/src/qt/
sudo cp assets_installer/bitfranc_replace/wallettests.cpp ~/bitcoin/src/qt/test/
sudo cp assets_installer/bitfranc_replace/wallet_tests.cpp ~/bitcoin/src/wallet/test/
sudo cp assets_installer/bitfranc_replace/amount.h ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/chainparams.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/chainparamsbase.cpp ~/bitcoin/src/
sudo cp assets_installer/bitfranc_replace/pow.cpp ~/bitcoin/src/

sudo rm -rf ~/bitcoin/src/qt/locale
sudo cp -R assets_installer/locale ~/bitcoin/src/qt/
sudo cp assets_installer/bitcoin.png ~/bitcoin/src/qt/res/icons/bitcoin.png
sudo cp assets_installer/bitcoin.ico ~/bitcoin/src/qt/res/icons/bitcoin.ico

sudo mkdir ~/bitcoin/db4/
cd ~/bitcoin/db4
sudo wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
sudo tar -xzvf db-4.8.30.NC.tar.gz
rm -rf db-4.8.30.NC.tar.gz
DB4_PATH=$PWD
cd db-4.8.30.NC/build_unix
sudo ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$DB4_PATH
sudo make install

cd ~/bitcoin/depends
sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
sudo make HOST=x86_64-w64-mingw32
cd ~/bitcoin/

sudo ./autogen.sh
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site
sudo ./configure LDFLAGS="-L$DB4_PATH/lib/" CPPFLAGS="-I$DB4_PATH/include/"
sed -i -e 's/bitcoin/bitFranc/g' ~/bitcoin/src/config/bitcoin-config.h
sed -i -e 's/Bitcoin/BitFranc/g' ~/bitcoin/src/config/bitcoin-config.h
sed -i -e 's/BITCOIN/BITFRANC/g' ~/bitcoin/src/config/bitcoin-config.h
sed -i -e 's/bitcoins/bitFrancs/g' ~/bitcoin/src/config/bitcoin-config.h
sed -i -e 's/Bitcoins/BitFrancs/g' ~/bitcoin/src/config/bitcoin-config.h
sed -i -e 's/BITCOINS/BITFRANCS/g' ~/bitcoin/src/config/bitcoin-config.h

sudo make

sudo mv ~/bitcoin/src/bitcoind ~/bitcoin/src/bitfrancd
sudo mv ~/bitcoin/src/bitcoin-tx ~/bitcoin/src/bitfranc-tx
sudo mv ~/bitcoin/src/bitcoin-cli ~/bitcoin/src/bitfranc-cli
sudo mv ~/bitcoin/src/qt/bitcoin-qt ~/bitcoin/src/qt/bitfranc-qt
