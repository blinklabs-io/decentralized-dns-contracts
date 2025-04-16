#!/bin/bash

source env.sh

USER=$1

cardano-cli conway address key-gen \
      --verification-key-file $WALLET_PATH/$USER.vkey \
      --signing-key-file $WALLET_PATH/$USER.skey

cardano-cli conway stake-address key-gen \
    --verification-key-file $WALLET_PATH/$USER-stake.vkey \
    --signing-key-file $WALLET_PATH/$USER-stake.skey

cardano-cli conway stake-address build \
    --testnet-magic ${TESTNET_MAGIC} \
    --stake-verification-key-file $WALLET_PATH/$USER-stake.vkey \
    --out-file $WALLET_PATH/$USER-stake.addr

cardano-cli conway address build \
    --payment-verification-key-file $WALLET_PATH/$USER.vkey \
    --stake-verification-key-file $WALLET_PATH/$USER-stake.vkey \
    --testnet-magic ${TESTNET_MAGIC} \
    --out-file $WALLET_PATH/$USER.addr
