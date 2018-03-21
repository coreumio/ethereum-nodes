#!/bin/bash

RPCPORT=8545
WSPORT=8546
if [[ "${ROOT}" == "" ]] ; then ROOT="/geth" ; fi
[[ "${UNLOCK_ACCOUNT}" != "" ]] || UNLOCK_ACCOUNT="0x913da4198e6be1d5f5e4a40d0667f70c0b5430eb"

ROOT=$(readlink -f $ROOT)

source ./common_start.sh

node_start() {
  # geth is dumb and won't let us run it in the background, and nohup redirects to file when run in a script
  nohup geth \
    --networkid 12346 \
    --datadir "${ROOT}/chain" \
    --keystore "${ROOT}/keys" \
    --password "${ROOT}/password.txt" \
    --unlock "${UNLOCK_ACCOUNT}" \
    --verbosity ${GETH_VERBOSITY:-2} --mine \
    --ws --wsapi eth,net,web3,personal,txpool --wsaddr 0.0.0.0 --wsport $WSPORT --wsorigins '*' \
    --rpc --rpcapi eth,net,web3,personal,miner,txpool --rpcaddr 0.0.0.0 --rpcport $RPCPORT --rpccorsdomain '*' \
    --targetgaslimit 6500000 < /dev/null > $ROOT/geth.log 2>&1 &
  NODE_PID=$!

  tail -F $ROOT/geth.log 2>/dev/null &
  TAIL_PID=$!
}

setup_chain_dir() {
  # to enable volume mounts to persist data, we need to take some specific
  # actions, detecting when one is present and new, vs present and old
  # vs not present
  if [ ! -d ${ROOT}/chain ]; then
    echo "${ROOT}/chain not mounted, transactions will be ephemeral"
    mv ${ROOT}/chain-template ${ROOT}/chain
  else
    # Chain dir exists
    if [ -d /geth/chain/geth/chaindata ]; then
      echo "${ROOT}/chain-template mounted and has prior blockchain state, restored"
    else
      echo "${ROOT}/chain-template mounted, but uninitialized. Copying chaindata template"
      mv ${ROOT}/chain-template/* ${ROOT}/chain
    fi
  fi
}

start
