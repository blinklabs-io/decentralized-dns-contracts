#!/bin/bash

source env.sh

raw=$TX_PATH/mint-hello.raw
signed=$TX_PATH/mint-hello.sign

USER=$1
USER_ADDR=$(cat $WALLET_PATH/$USER.addr)

UTXO_IN=$(get_address_biggest_lovelace $USER_ADDR)
echo "UTXO_IN: $UTXO_IN"
CS=$(cardano-cli hash script --script-file $Validator_Path/hello-handshake.plutus)
TN=$(printf '%s' hello-handshake | xxd -p)

cardano-cli conway transaction build \
    --testnet-magic ${TESTNET_MAGIC} \
    --change-address $USER_ADDR \
    --tx-in $UTXO_IN \
    --tx-in-collateral $UTXO_IN \
    --mint "10 $CS.$TN" \
    --mint-script-file $Validator_Path/hello-handshake.plutus \
    --mint-redeemer-file $REDEEMER_PATH/hnsdata.json \
    --tx-out $USER_ADDR+5000000+"10 $CS.$TN" \
    --out-file $raw
cardano-cli conway transaction sign \
    --testnet-magic ${TESTNET_MAGIC} \
    --tx-body-file $raw \
    --out-file $signed \
    --signing-key-file $WALLET_PATH/$USER.skey

cardano-cli conway transaction submit \
    --testnet-magic ${TESTNET_MAGIC} \
    --tx-file $signed

tx_submitted $signed $USER_ADDR
