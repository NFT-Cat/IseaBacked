import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import TrieSet "mo:base/TrieSet";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Types "./types";
import Debug "mo:base/Debug";

shared(msg) actor class Market() = this {
    type Operation = Types.Operation;
    type OpRecord = Types.OpRecord;
    type NFTStatus = {
        #pendingOrder;  // 挂单展示状态
        #alreadyOrder: (Principal, Time.Time);    // 下单锁定状态
    };

    type NFT = {
        tokenId: Nat;
        owner: Principal;
        var status: NFTStatus;
        var receive: Text;
        var price: Nat64;
        pendTime: Time.Time;
    };

    type NFTExt = {
        tokenId: Nat;
        owner: Principal;
        status: NFTStatus;
        receive: Text;
        price: Nat64;
        pendTime: Time.Time;
    };

    type DealNFT = {
        index: Nat;
        tokenId: Nat;
        nftFrom: Principal;
        nftTo: Principal;
        icpBlockId: Nat64;
        icpTo: Text;
        price: Nat64;
        pendTime: Time.Time;
        dealTime: Time.Time;
    };

    type NftSort = {
        #pendTimeUp;        // 最早上架时间排序
        #pendTimeDown;      // 最新上架时间排序
        #priceUp;           // 价格排序由低到高
        #priceDown;         // 价格排序由高到低
        #tokenIdUp;         // NFT id 由小到大
        #tokenIdDown;       // NFT id 由大到小
    };

    type DealSort = {
        #dealTimeUp;
        #dealTimeDown;
        #dealPriceUp;
        #dealPriceDown;
        #dealTokenIdUp;
        #dealTokenIdDown;
    };

    type ERC721Actor = actor {
        transferFrom : (from: Principal, to: Principal, tokenId: Nat) -> async Bool;
        ownerOf : query (tokenId: Nat) -> async Principal;
        transfer : (to: Principal, tokenId: Nat) -> async Bool;
    };

    type ReadActor = actor {
        is_payed : query (blockNum: Nat64, subAcc: ?[Nat8], from: Principal, to: Text, value: Nat64, index: Nat) -> async Bool;
    };

    private stable let LEDGER : Principal = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
    private stable let INTERNEL : Time.Time = 5*60*1_000_000_000;
    private stable var admin : Principal = msg.caller;
    private stable var erc721Canister : Principal = msg.caller;
    private stable var readCanister : Principal = msg.caller;
    private stable var ops : [OpRecord] = [];
    private stable var dealNfts : [DealNFT] = [];
    private var nfts = HashMap.HashMap<Nat, NFT>(1, Nat.equal, Hash.hash);
    private stable var nftsEntries: [(Nat, NFT)] = [];

    private func addRecord(
        caller: Principal, op: Operation, from: Principal, to: Principal, tokenId: Nat,
        tokenPrice: Nat64, fee: Nat64, timestamp: Time.Time
    ) {
        let index = ops.size();
        let o : OpRecord = {
            caller; op; index; from; to; tokenId; tokenPrice; fee; timestamp;
        };
        ops := Array.append(ops, [o]);
    };

    private func _nftExt(n: NFT) : NFTExt {
        return {
            tokenId = n.tokenId;
            owner = n.owner;
            status = n.status;
            receive = n.receive;
            price = n.price;
            pendTime = n.pendTime;
        };
    };

    public shared(msg) func setERC721(canisterId: Principal) : async Bool {
        assert(msg.caller == admin);
        erc721Canister := canisterId;
        return true;
    };

    public shared(msg) func setRead(canisterId: Principal) : async Bool {
        assert(msg.caller == admin);
        readCanister := canisterId;
        return true;
    };

    public shared(msg) func pend(id: Nat, receive: Text, price: Nat64) : async Bool {
        let erc721 : ERC721Actor = actor(Principal.toText(erc721Canister));
          Debug.print("1312321");
            Debug.print(Principal.toText(msg.caller));

        assert(msg.caller == (await erc721.ownerOf(id)));
        assert(await erc721.transferFrom(msg.caller, Principal.fromActor(this), id));
        let nft : NFT = {
            tokenId = id;
            owner = msg.caller;
            var status = #pendingOrder;
            var receive = receive;
            var price = price;
            pendTime = Time.now();
        };
        nfts.put(id, nft);
        addRecord(msg.caller, #pend, msg.caller, Principal.fromActor(this), id, price, 0, Time.now());
        return true;
    };

    public shared(msg) func withdraw(id: Nat) : async Bool {
        switch (nfts.get(id)) {
            case (?nft) {
                if (nft.owner != msg.caller or nft.status != #pendingOrder) { return false; };
                let erc721: ERC721Actor = actor(Principal.toText(erc721Canister));
                assert(await erc721.transferFrom(Principal.fromActor(this), msg.caller, id));
                nfts.delete(id);
                addRecord(msg.caller, #withdraw, Principal.fromActor(this), msg.caller, id, 0, 0, Time.now());
                return true;
            };
            case (_) {
                return false;
            };
        }
    };

    public shared(msg) func order(id: Nat) : async Bool {
        switch (nfts.get(id)) {
            case (?nft) {
                if (nft.status != #pendingOrder) { return false; };
                nft.status := #alreadyOrder (msg.caller, Time.now());
                nfts.put(id, nft);
                addRecord(msg.caller, #order, nft.owner, msg.caller, id, 0, 0, Time.now());
                return true;
            };
            case (_) {
                return false;
            };
        }
    };

    public shared(msg) func recall(id: Nat) : async Bool {
        assert(msg.caller == admin);
        switch (nfts.get(id)) {
            case (?nft) {
                switch (nft.status) {
                    case (#pendingOrder) {
                        return false;
                    };
                    case (#alreadyOrder (p, t)) {
                        assert(Time.now() > t + INTERNEL);
                        nft.status := #pendingOrder;
                        nfts.put(id, nft);
                        addRecord(msg.caller, #recall, p, nft.owner, id, nft.price, 0, Time.now());
                        return true;
                    };
                }
            };
            case (_) {
                return false;
            };
        }
    };

    public shared(msg) func deal(id: Nat, blockid: Nat64, subAcc: ?[Nat8]) : async Bool {
        switch (nfts.get(id)) {
            case (?nft) {
                switch (nft.status) {
                    case (#pendingOrder) {
                        return false;
                    };
                    case (#alreadyOrder (p, t)) {
                        assert(p == msg.caller);
                        let read : ReadActor = actor(Principal.toText(readCanister));
                        let erc721: ERC721Actor = actor(Principal.toText(erc721Canister));
                        assert(await read.is_payed(blockid, subAcc, msg.caller, nft.receive, nft.price, id));
                        assert(await erc721.transferFrom(Principal.fromActor(this), msg.caller, id));
                        nfts.delete(id);
                        let dn: DealNFT = {
                            index = dealNfts.size();
                            tokenId = id;
                            nftFrom = nft.owner;
                            nftTo = msg.caller;
                            icpBlockId = blockid;
                            icpTo = nft.receive;
                            price = nft.price;
                            pendTime = nft.pendTime;
                            dealTime = Time.now();
                        };
                        dealNfts := Array.append(dealNfts, [dn]);
                        addRecord(msg.caller, #deal, Principal.fromActor(this), msg.caller, id, nft.price, 0, Time.now());
                        return true;
                    };
                }
            };
            case (_) {
                return false;
            };
        }
    };

    public query func getNFTList(start: Nat, num: Nat, s: NftSort, above: Nat64, under: Nat64) : async ([NFTExt], Nat) {
        var list: [NFTExt] = [];
        for ((k, v) in nfts.entries()) {
            if (v.price >= above and v.price <= under) {
                list := Array.append<NFTExt>(list, [_nftExt(v)]);
            };
        };

        var sorted: [NFTExt] = [];
        switch (s) {
            case (#pendTimeUp) {
                func order (a: NFTExt, b: NFTExt) : Order.Order {
                    return Int.compare(a.pendTime, b.pendTime);
                };
                sorted := Array.sort(list, order);
            };
            case (#pendTimeDown) {
                func order (a: NFTExt, b: NFTExt) : Order.Order {
                    return Int.compare(b.pendTime, a.pendTime);
                };
                sorted := Array.sort(list, order);
            };
            case (#priceUp) {
                func order (a: NFTExt, b: NFTExt) : Order.Order {
                    return Nat64.compare(a.price, b.price);
                };
                sorted := Array.sort(list, order);
            };
            case (#priceDown) {
                func order (a: NFTExt, b: NFTExt) : Order.Order {
                    return Nat64.compare(b.price, a.price);
                };
                sorted := Array.sort(list, order);
            };
            case (#tokenIdUp) {
                func order (a: NFTExt, b: NFTExt) : Order.Order {
                    return Nat.compare(a.tokenId, b.tokenId);
                };
                sorted := Array.sort(list, order);
            };
            case (#tokenIdDown) {
                func order (a: NFTExt, b: NFTExt) : Order.Order {
                    return Nat.compare(b.tokenId, a.tokenId);
                };
                sorted := Array.sort(list, order);            };
        };

        let limit: Nat = if(start + num > sorted.size()) {
            sorted.size() - start
        } else {
            num
        };
        var ret: [NFTExt] = [];
        for (i in Iter.range(0, limit-1)) {
            ret := Array.append<NFTExt>(ret, [sorted[start+i]]);
        };
        (ret, sorted.size())
    };

    public query func getDealNFTList(start: Nat, num: Nat, s: DealSort) : async ([DealNFT], Nat) {
        var sorted: [DealNFT] = [];
        switch (s) {
            case (#dealTimeUp) {
                func order (a: DealNFT, b: DealNFT) : Order.Order {
                    return Int.compare(a.dealTime, b.dealTime);
                };
                sorted := Array.sort(dealNfts, order);
            };
            case (#dealTimeDown) {
                func order (a: DealNFT, b: DealNFT) : Order.Order {
                    return Int.compare(b.dealTime, a.dealTime);
                };
                sorted := Array.sort(dealNfts, order);
            };
            case (#dealPriceUp) {
                func order (a: DealNFT, b: DealNFT) : Order.Order {
                    return Nat64.compare(a.price, b.price);
                };
                sorted := Array.sort(dealNfts, order);
            };
            case (#dealPriceDown) {
                func order (a: DealNFT, b: DealNFT) : Order.Order {
                    return Nat64.compare(b.price, a.price);
                };
                sorted := Array.sort(dealNfts, order);
            };
            case (#dealTokenIdUp) {
                func order (a: DealNFT, b: DealNFT) : Order.Order {
                    return Nat.compare(a.tokenId, b.tokenId);
                };
                sorted := Array.sort(dealNfts, order);
            };
            case (#dealTokenIdDown) {
                func order (a: DealNFT, b: DealNFT) : Order.Order {
                    return Nat.compare(b.tokenId, a.tokenId);
                };
                sorted := Array.sort(dealNfts, order);
            };
        };

        let limit: Nat = if(start + num > sorted.size()) {
            sorted.size() - start
        } else {
            num
        };
        var ret: [DealNFT] = [];
        for (i in Iter.range(0, limit-1)) {
            ret := Array.append<DealNFT>(ret, [sorted[start+i]]);
        };
        (ret, sorted.size())
    };

    public query func getNFTListByUser(owner: Principal, start: Nat, num: Nat, s: NftSort) : async ([NFTExt], Nat) {
        var list: [NFTExt] = [];
        for ((k, v) in nfts.entries()) {
            if (v.owner == owner) {
                list := Array.append<NFTExt>(list, [_nftExt(v)]);
            };
        };
        let limit: Nat = if(start + num > list.size()) {
            list.size() - start
        } else {
            num
        };
        var ret: [NFTExt] = [];
        for (i in Iter.range(0, limit-1)) {
            ret := Array.append<NFTExt>(ret, [list[start+i]]);
        };
        (ret, list.size())
    };

    public query func getNFT(tokenId: Nat) : async NFTExt {
        switch (nfts.get(tokenId)) {
            case (?v) {
                return _nftExt(v);
            };
            case (_) {
                throw Error.reject("NFT not in market");
            };
        }
    };

    system func preupgrade() {
        nftsEntries := Iter.toArray(nfts.entries());
    };

    system func postupgrade() {
        nfts := HashMap.fromIter<Nat, NFT>(nftsEntries.vals(), 1, Nat.equal, Hash.hash);
        nftsEntries := [];
    };
};
