#!/bin/bash

dfx stop
rm -rf .dfx

dfx identity use alice
ALICE_PUBLIC_KEY="principal \"$( \
    dfx identity get-principal
)\""
ALICE_ACCOUNT=\"$(dfx ledger account-id)\"

dfx identity use bob
BOB_PUBLIC_KEY="principal \"$( \
    dfx identity get-principal
)\""
BOB_ACCOUNT=\"$(dfx ledger account-id)\"


dfx identity use fee
FEE_PUBLIC_KEY="principal \"$( \
    dfx identity get-principal
)\""


dfx identity use alice
dfx start --background
dfx canister --no-wallet create --all
dfx build

eval dfx canister --no-wallet install market
#eval dfx canister --no-wallet install icNft --argument="'(\"Test NFT 1\", \"NFT1\",$ALICE_PUBLIC_KEY)'"
eval dfx canister --no-wallet install erc721 --argument="'(\"Test NFT 1\", \"NFT1\",$ALICE_PUBLIC_KEY)'"
eval dfx canister --no-wallet install erc20 --argument="'(\"Logo\", \"Test token\", \"tst\", 3, 1_000_000_000, $ALICE_PUBLIC_KEY, true, true)'"


Market="principal \"$( \
    dfx canister --no-wallet id market
)\""
#IcNft="principal \"$( \
#    dfx canister --no-wallet id icNft
#)\""
Erc721="principal \"$( \
    dfx canister --no-wallet id erc721
)\""
Erc20="principal \"$( \
    dfx canister --no-wallet id erc20
)\""

echo == Canisters ID
echo Market principal: $Market
#echo IcNft principal: $IcNft
echo Erc721 principal: $Erc721
echo Erc20 principal: $Erc20

echo == Init Canisters
#eval dfx canister --no-wallet call market setIcNFT "'($IcNft)'"
eval dfx canister --no-wallet call market setIcNFT "'($Erc721)'"
eval dfx canister --no-wallet call erc721 setFeePrice "'(1000)'"
eval dfx canister --no-wallet call erc721 setErc20 "'($Erc20)'"
eval dfx canister --no-wallet call erc721 setFeePool "'($FEE_PUBLIC_KEY)'"
echo == admin Alice Approve NFT canister transferFrom her ERC20 Token
eval dfx canister --no-wallet call erc20 approve "'($Erc721, 1_000_000)'"



echo == mint
eval dfx canister --no-wallet call erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/1\", \"token 1\", \"the 1 nft in here\")'"
echo == tokeninfo of erc721
eval dfx canister --no-wallet call erc721 tokenInfo "'(1)'"

# bob
echo == Bob list his nft
dfx identity use bob
eval dfx canister --no-wallet call erc721 setApprovalForAll "'($Market, true)'"
eval dfx canister --no-wallet call market listToken "'(1, 1, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1800_000_000:nat64)'"

echo == tokeninfo of ntf 0
eval dfx canister --no-wallet call erc721 tokenInfo "'(1)'"
eval dfx canister --no-wallet call market getSellOrder "'(1)'"


