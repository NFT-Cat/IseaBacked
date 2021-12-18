# market

文档见 飞书

```sh
平台测试币： vfk4z-qqaaa-aaaah-aaura-cai
NFT token： vcl2n-5iaaa-aaaah-aaurq-cai
Read :     vxmla-4aaaa-aaaah-aausa-cai
Market:    vqnnu-ryaaa-aaaah-aausq-cai
平台测试币faucet： 634oh-lyaaa-aaaah-aavoq-cai
```

```sh
dfx canister --no-wallet --network ic call aanaa-xaaaa-aaaah-aaeiq-cai wallet_create_canister '(record {cycles = 2_000_000_000_000:nat64; controller = opt principal "ulmxr-7dfyg-ai4fx-oetdh-pmgpb-z7xef-anifu-jegto-6n4j3-bd7yv-7qe"})'

dfx canister --no-wallet --network ic install token --argument='("https://api.test.com/1", "IC Test Token", "IT", 8, 1_000_000_000_000_000_00, principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae", true, true)' -m=reinstall

dfx canister --no-wallet --network ic call token transfer '(principal "634oh-lyaaa-aaaah-aavoq-cai", 1_000_000_00000000)'

dfx canister --no-wallet --network ic call token transfer '(principal "rh3q4-dgbxv-wufjt-dgurw-nkfc5-r377h-xrepu-ocoxm-qpwnu-3nooe-5qe", 1_000_000_00000000)'


eval dfx canister --no-wallet --network ic install token_ERC721 --argument="'(\"iSea\", \"iSea\", principal \"yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae\")'" -m=reinstall

eval dfx canister --no-wallet --network ic install read -m=reinstall

eval dfx canister --no-wallet --network ic install market -m=reinstall


eval dfx canister --no-wallet --network ic call read set_market "'(principal \"vqnnu-ryaaa-aaaah-aausq-cai\")'"

eval dfx canister --no-wallet --network ic call market setERC721 "'(principal \"vcl2n-5iaaa-aaaah-aaurq-cai\")'"


eval dfx canister --no-wallet --network ic call market setRead "'(principal \"vxmla-4aaaa-aaaah-aausa-cai\")'"

eval dfx canister --no-wallet --network ic call token_ERC721 setFeePrice "'(100_000_000)'"
eval dfx canister --no-wallet --network ic call token_ERC721 setErc20 "'(principal \"vfk4z-qqaaa-aaaah-aaura-cai\")'"

# nftfee
eval dfx canister --no-wallet --network ic call token_ERC721 setFeePool "'(principal \"6zbhs-5qdi7-6xt24-q2hl3-ofwic-yvy2y-uzd5s-idyjl-nwhbs-y4s2u-hae\")'"

eval dfx canister --no-wallet --network ic call token approve "'(principal \"vcl2n-5iaaa-aaaah-aaurq-cai\", 1_000_000_00_000)'"

eval dfx canister --no-wallet --network ic  call token_ERC721 mint "'(principal \"yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae\", \"a.link/1\", \"token 1\", \"the 1 nft in here\")'"

eval dfx canister --no-wallet --network ic call token_ERC721 tokenInfo "'(1)'"

eval dfx canister --no-wallet --network ic call token_ERC721 setApprovalForAll "'(principal \"vqnnu-ryaaa-aaaah-aausq-cai\", true)'"

eval dfx canister --no-wallet --network ic call market pend "'(1, \"a3a6b204465c2f53c60ae18f5761acbd868b7705f888ccc2955eabbb5942d991\", 10_000:nat64)'"


eval dfx canister --no-wallet --network ic call token_ERC721 tokenInfo "'(1)'"

eval dfx canister --no-wallet --network ic call ryjl3-tyaaa-aaaaa-aaaba-cai send_dfx "'(record {memo=105523022:nat64;amount=record{e8s=10_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to=\"a3a6b204465c2f53c60ae18f5761acbd868b7705f888ccc2955eabbb5942d991\";created_at_time=null})'"

730_961

eval dfx canister --no-wallet --network ic call market deal "'(1:nat,730_961:nat64,null)'"


sudo dfx canister --no-wallet --network ic install faucet --argument='(principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae")' -m=reinstall
Installing code for canister faucet, with canister_id 634oh-lyaaa-aaaah-aavoq-cai

dfx canister --no-wallet --network ic call vfk4z-qqaaa-aaaah-aaura-cai transfer '(principal "634oh-lyaaa-aaaah-aavoq-cai", 1000000000000000:nat)'
(variant { 24_860 = 11 : nat })

```


## 成交
1. 查询订单
```sh
dfx canister --no-wallet --network ic call 2market getNFT '(1:nat)' --query  
(
  record {
    status = variant { pendingOrder };
    tokenId = 1 : nat;
    receive = "a3a6b204465c2f53c60ae18f5761acbd868b7705f888ccc2955eabbb5942d991";
    pendTime = 1_632_577_677_688_032_653 : int;
    owner = principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae";
    price = 10_000 : nat64;
  },
）


dfx canister --no-wallet --network ic call vqnnu-ryaaa-aaaah-aausq-cai order '(1:nat)'
dfx canister --no-wallet --network ic call ryjl3-tyaaa-aaaaa-aaaba-cai send_dfx '(record {memo=105523022:nat64;amount=record{e8s=10_000:nat64};fee=record{e8s=10000:nat64};from_subaccount=null;to="a3a6b204465c2f53c60ae18f5761acbd868b7705f888ccc2955eabbb5942d991";created_at_time=null})'
(899_996 : nat64)

dfx canister --no-wallet --network ic call vqnnu-ryaaa-aaaah-aausq-cai deal '(1:nat,899996:nat64,null)'

The Replica returned an error: code 4, message: "Canister yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae does not exist"


dfx canister --no-wallet --network ic call vqnnu-ryaaa-aaaah-aausq-cai setRead '(principal "vxmla-4aaaa-aaaah-aausa-cai")'

dfx canister --no-wallet --network ic call vqnnu-ryaaa-aaaah-aausq-cai deal '(1:nat,899996:nat64,null)'                   
(true)


dfx canister --no-wallet --network ic call 2market getNFT '(1:nat)' --query  
The Replica returned an error: code 4, message: "NFT not in market"


dfx canister --no-wallet --network ic call vqnnu-ryaaa-aaaah-aausq-cai getDealNFTList '(0:nat, 100:nat, variant {dealPriceDown})' 
(
  vec {
    record {
      tokenId = 1 : nat;
      pendTime = 1_632_577_677_688_032_653 : int;
      icpBlockId = 899_996 : nat64;
      nftTo = principal "zr7lj-j4xfc-imd3p-jo44j-kwai4-iyxb3-jiuwb-aldpj-ry6cj-y7ram-yqe";
      nftFrom = principal "yhy6j-huy54-mkzda-m26hc-yklb3-dzz4l-i2ykq-kr7tx-dhxyf-v2c2g-tae";
      icpTo = "a3a6b204465c2f53c60ae18f5761acbd868b7705f888ccc2955eabbb5942d991";
      index = 0 : nat;
      price = 10_000 : nat64;
      dealTime = 1_634_033_642_726_429_582 : int;
    };
  },
  1 : nat,
)


dfx canister --no-wallet --network ic call vcl2n-5iaaa-aaaah-aaurq-cai ownerOf '(1:nat)'
(principal "zr7lj-j4xfc-imd3p-jo44j-kwai4-iyxb3-jiuwb-aldpj-ry6cj-y7ram-yqe")


sudo dfx canister --no-wallet --network ic install 2market -m=upgrade


```


