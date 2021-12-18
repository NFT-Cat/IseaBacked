#!/bin/bash

dfx stop
rm -rf .dfx

dfx start --background

dfx identity use alice
PUBLIC_KEY="principal \"$( \
    dfx identity get-principal
)\""

dfx canister --no-wallet create --all
dfx build
dfx canister --no-wallet install icpunks --argument="(\"ICPunks\", \"TT\", 10000, $PUBLIC_KEY)" -m reinstall
dfx canister --no-wallet install icpunks_storage --argument="($PUBLIC_KEY)" -m reinstall
dfx canister --no-wallet install icpunksWrapper --argument="(\"ICPunks\", \"TT\", \"symbol\", \"desc\", $PUBLIC_KEY)" -m reinstall

ICPUNKSID=$(dfx canister --no-wallet id icpunks)
STOREID=$(dfx canister --no-wallet id icpunks_storage)
ICPUNKSID="principal \"$ICPUNKSID\""
STOREID="principal \"$STOREID\""
ICPUNKSWRAPPERID=$(dfx canister --no-wallet id icpunksWrapper)
ICPUNKSWRAPPERID="principal \"$ICPUNKSWRAPPERID\""

dfx canister --no-wallet call icpunks set_storage_canister_id "(opt $STOREID)"
dfx canister --no-wallet call icpunks_storage setTokenCanisterId "($ICPUNKSID)"
dfx canister --no-wallet call icpunks add_genesis_record

dfx canister --no-wallet call icpunks mint "(record {name=\"icpunks1\"; url=\"http://baidu.com\"; desc=\"icpunksdesc\"; properties=vec{record{name=\"properName\"; value=\"properValue\"}}; data=vec{1:nat8}; contentType=\"icpunkscontent\" })"
dfx canister --no-wallet call icpunksWrapper packageTokenData "(\"rwlgt-iiaaa-aaaaa-aaaaa-cai\",1:nat32)"

dfx canister --no-wallet call icpunksWrapper wrap "(\"0a7469640000000000000000010100000001\")"

dfx canister --no-wallet call icpunks transfer_to "($ICPUNKSWRAPPERID, 1:nat)"

dfx canister --no-wallet call icpunksWrapper mint "(\"0a7469640000000000000000010100000001\", record{ filetype=\"jpg\"; attributes=vec{record{key=\"key\"; value=\"value\"}} })"

dfx canister --no-wallet call icpunksWrapper packageTokenData "(\"rrkah-fqaaa-aaaaa-aaaaq-cai\",1:nat32)"

dfx canister --no-wallet call icpunksWrapper unwrap "(\"0a7469640000000000000001010100000001\")"



