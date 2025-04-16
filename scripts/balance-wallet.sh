source env.sh

cardano-cli query utxo --testnet-magic ${TESTNET_MAGIC} --address $(cat $WALLET_PATH/$1.addr)