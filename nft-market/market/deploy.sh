#!/bin/bash

# set -e

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

dfx identity use dan
DAN_PUBLIC_KEY="principal \"$( \
    dfx identity get-principal
)\""

dfx identity use fee
FEE_PUBLIC_KEY="principal \"$( \
    dfx identity get-principal
)\""

dfx identity use minting
MINTING_ACCOUNT=\"$(dfx ledger account-id)\"

AMOUNT=100_000_000_000_000


dfx identity use alice
dfx start --background
dfx canister --no-wallet create --all
dfx build

eval dfx canister --no-wallet install 1read
eval dfx canister --no-wallet install 2market 
eval dfx canister --no-wallet install 3ledger --argument "'(record {minting_account=$MINTING_ACCOUNT; initial_values=vec {record{$ALICE_ACCOUNT;record{e8s=$AMOUNT:nat64;}}}; max_message_size_bytes=null;transaction_window=opt record {secs=300:nat64;nanos=0:nat32};archive_options=null;send_whitelist=vec{};})'"
eval dfx canister --no-wallet install 4erc721 --argument="'(\"Test NFT 1\", \"NFT1\",$ALICE_PUBLIC_KEY)'"
eval dfx canister --no-wallet install 5erc20 --argument="'(\"Logo\", \"Test token\", \"tst\", 3, 1_000_000_000, $ALICE_PUBLIC_KEY, true, true)'"

eval dfx canister --no-wallet call 3ledger account_balance_dfx "'(record {account=$ALICE_ACCOUNT})'"
eval dfx canister --no-wallet call 3ledger account_balance_dfx "'(record {account=$BOB_ACCOUNT})'"

Read="principal \"$( \
    dfx canister --no-wallet id 1read
)\""
Market="principal \"$( \
    dfx canister --no-wallet id 2market
)\""
Ledger="principal \"$( \
    dfx canister --no-wallet id 3ledger
)\""
Erc721="principal \"$( \
    dfx canister --no-wallet id 4erc721
)\""
Erc20="principal \"$( \
    dfx canister --no-wallet id 5erc20
)\""


echo == Canisters ID
echo Read principal: $Read
echo Market principal: $Market
echo Ledger principal: $Ledger
echo Erc721 principal: $Erc721
echo Erc20 principal: $Erc20


echo == Init Canisters
eval dfx canister --no-wallet call 1read set_market "'($Market)'"

eval dfx canister --no-wallet call 2market setERC721 "'($Erc721)'"
eval dfx canister --no-wallet call 2market setRead "'($Read)'"

eval dfx canister --no-wallet call 4erc721 setFeePrice "'(1000)'"
eval dfx canister --no-wallet call 4erc721 setErc20 "'($Erc20)'"
eval dfx canister --no-wallet call 4erc721 setFeePool "'($FEE_PUBLIC_KEY)'"


echo == admin Alice Approve NFT canister transferFrom her ERC20 Token
eval dfx canister --no-wallet call 5erc20 approve "'($Erc721, 1_000_000)'"


eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/1\", \"token 1\", \"the 1 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/2\", \"token 2\", \"the 2 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/3\", \"token 3\", \"the 3 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/4\", \"token 4\", \"the 4 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/5\", \"token 5\", \"the 5 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/6\", \"token 6\", \"the 6 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/7\", \"token 7\", \"the 7 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/8\", \"token 8\", \"the 8 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/9\", \"token 9\", \"the 9 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/10\", \"token 10\", \"the 10 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/11\", \"token 11\", \"the 11 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/12\", \"token 12\", \"the 12 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/13\", \"token 13\", \"the 13 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/14\", \"token 14\", \"the 14 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/15\", \"token 15\", \"the 15 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/16\", \"token 16\", \"the 16 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/17\", \"token 17\", \"the 17 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/18\", \"token 18\", \"the 18 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/19\", \"token 19\", \"the 19 nft in here\")'"
eval dfx canister --no-wallet call 4erc721 mint "'($BOB_PUBLIC_KEY, \"a.link/20\", \"token 20\", \"the 20 nft in here\")'"


echo Alice $ALICE_PUBLIC_KEY
echo Bob $BOB_PUBLIC_KEY


echo == tokeninfo of erc721
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(1)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(2)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(3)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(4)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(5)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(6)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(7)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(8)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(9)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(10)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(11)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(12)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(13)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(14)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(15)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(16)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(17)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(18)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(19)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(20)'"


# bob 
echo == Bob pend 20 NFTs
dfx identity use bob
eval dfx canister --no-wallet call 4erc721 setApprovalForAll "'($Market, true)'"
eval dfx canister --no-wallet call 2market pend "'(16, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1800_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(3, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1900_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(6, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 300_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(17, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 900_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(8, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 100_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(20, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 800_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(9, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1600_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(2, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 500_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(14, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 700_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(11, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 100_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(7, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1300_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(12, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 2000_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(1, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1600_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(13, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1400_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(15, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 500_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(5, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 600_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(10, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1300_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(18, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 300_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(19, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1300_000_000:nat64)'"
eval dfx canister --no-wallet call 2market pend "'(4, \"a400af788053019125eb2aee55fafbee4f202e30ef336a5593f58bb09a653b5a\", 1900_000_000:nat64)'"

echo == tokeninfo of ntfs
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(1)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(2)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(3)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(4)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(5)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(6)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(7)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(8)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(9)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(10)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(11)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(12)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(13)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(14)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(15)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(16)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(17)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(18)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(19)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(20)'"

# alice
echo == Alice deal 10 NFTs
dfx identity use alice
eval dfx canister --no-wallet call 2market order "'(5)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=505523022:nat64;amount=record{e8s=600_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(5:nat,1:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(4)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=405523022:nat64;amount=record{e8s=1900_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(4:nat,2:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(18)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=1805523022:nat64;amount=record{e8s=300_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(18:nat,3:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(15)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=1505523022:nat64;amount=record{e8s=500_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(15:nat,4:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(13)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=1305523022:nat64;amount=record{e8s=1400_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(13:nat,5:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(10)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=1005523022:nat64;amount=record{e8s=1300_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(10:nat,6:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(11)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=1105523022:nat64;amount=record{e8s=100_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(11:nat,7:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(20)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=2005523022:nat64;amount=record{e8s=800_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(20:nat,8:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(8)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=805523022:nat64;amount=record{e8s=100_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(8:nat,9:nat64,null)'"

eval dfx canister --no-wallet call 2market order "'(9)'"
eval dfx canister --no-wallet call 3ledger send_dfx "'(record {memo=905523022:nat64;amount=record{e8s=1600_000_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=$BOB_ACCOUNT;created_at_time=null})'"
eval dfx canister --no-wallet call 2market deal "'(9:nat,10:nat64,null)'"


echo == tokenInfo
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(1)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(2)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(3)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(4)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(5)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(6)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(7)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(8)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(9)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(10)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(11)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(12)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(13)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(14)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(15)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(16)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(17)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(18)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(19)'"
eval dfx canister --no-wallet call 4erc721 tokenInfo "'(20)'"

echo $ALICE_PUBLIC_KEY
echo $BOB_PUBLIC_KEY

eval dfx canister --no-wallet call 3ledger account_balance_dfx "'(record {account=$ALICE_ACCOUNT})'"
eval dfx canister --no-wallet call 3ledger account_balance_dfx "'(record {account=$BOB_ACCOUNT})'"

echo == getNFTIdList all ==
echo == getNFTIdList pendTimeUp
eval dfx canister --no-wallet call 2market getNFTList "'(0:nat, 999:nat, variant{pendTimeUp}, 0:nat64, 999_999_999_999:nat64)'"
echo == getNFTIdList pendTimeDown
eval dfx canister --no-wallet call 2market getNFTList "'(0:nat, 999:nat, variant{pendTimeDown}, 0:nat64, 999_999_999_999:nat64)'"
echo == getNFTIdList priceUp
eval dfx canister --no-wallet call 2market getNFTList "'(0:nat, 999:nat, variant{priceUp}, 0:nat64, 999_999_999_999:nat64)'"
echo == getNFTIdList priceDown
eval dfx canister --no-wallet call 2market getNFTList "'(0:nat, 999:nat, variant{priceDown}, 0:nat64, 999_999_999_999:nat64)'"
echo == getNFTIdList tokenIdUp
eval dfx canister --no-wallet call 2market getNFTList "'(0:nat, 999:nat, variant{tokenIdUp}, 0:nat64, 999_999_999_999:nat64)'"
echo == getNFTIdList tokenIdDown
eval dfx canister --no-wallet call 2market getNFTList "'(0:nat, 999:nat, variant{tokenIdDown}, 0:nat64, 999_999_999_999:nat64)'"

echo == getNFTIdList get 5 nft from 10 pend nft. price from 4 icp to 20 icp
eval dfx canister --no-wallet call 2market getNFTList "'(0:nat, 5:nat, variant{priceUp}, 400_000_000:nat64, 2_000_000_000:nat64)'"

echo == getDealNFTList all == 
echo == getNFTIdList dealTimeUp
eval dfx canister --no-wallet call 2market getDealNFTList "'(0:nat, 999:nat, variant{dealTimeUp})'"
echo == getNFTIdList dealTimeDown
eval dfx canister --no-wallet call 2market getDealNFTList "'(0:nat, 999:nat, variant{dealTimeDown})'"
echo == getNFTIdList dealPriceUp
eval dfx canister --no-wallet call 2market getDealNFTList "'(0:nat, 999:nat, variant{dealPriceUp})'"
echo == getNFTIdList dealPriceDown
eval dfx canister --no-wallet call 2market getDealNFTList "'(0:nat, 999:nat, variant{dealPriceDown})'"
echo == getNFTIdList dealTokenIdUp
eval dfx canister --no-wallet call 2market getDealNFTList "'(0:nat, 999:nat, variant{dealTokenIdUp})'"
echo == getNFTIdList dealTokenIdDown
eval dfx canister --no-wallet call 2market getDealNFTList "'(0:nat, 999:nat, variant{dealTokenIdDown})'"