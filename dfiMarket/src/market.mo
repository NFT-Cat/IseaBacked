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
import Result "mo:base/Result";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Types "./types";
import Debug "mo:base/Debug";

// Use WICP or XTC as payment token
shared(msg) actor class Market(owner_: Principal, wicp_: Principal, storage_: Principal) = this {
    type Operation = Types.Operation;
    type TxRecord = Types.TxRecord;
    public type OrderStatus = Types.OrderStatus;

    type Order = {
        index: Nat;
        token: Principal; // token canister ID
        tokenIndex: Nat; // token index
        owner: Principal;
        var price: Nat; // can edit price after listing
        var status: OrderStatus; // upadte to #done after order execution
        createAt: Int;
    };

    type OrderExt = {
        index: Nat;
        token: Principal; // token canister ID
        tokenIndex: Nat; // token index
        owner: Principal;
        price: Nat; // can edit price after listing
        status: OrderStatus; // upadte to #done after order execution
        createAt: Int;
    };

    type Collection = {
        index: Nat;
        canisterId: Principal;
        creator: Principal;
        name: Text;
        desc: Text;
        var feeRate: Nat; // fee for NFT creator
        var orders: Nat; // current list orders num
        var historyOrders: Nat; // done orders num
        var volume: Nat; // total icp volume
    };

    type CollectionExt = {
        index: Nat;
        canisterId: Principal;
        creator: Principal;
        name: Text;
        desc: Text;
        feeRate: Nat; // fee for NFT creator
        orders: Nat; // current list orders num
        historyOrders: Nat; // done orders num
        volume: Nat; // total icp volume
    };

    // result type
    type TxReceipt      = Result.Result<Nat, Text>;
    type OrdersReceipt  = Result.Result<Nat, Text>;

    // TODO: add getMetadata to ic-nft
    type Metadata = {
        name: Text;
        desc: Text;
        totalSupply: Nat;
        owner: Principal;
    };
    type DIP721Actor  = actor {
        transferFrom : (from: Principal, to: Principal, tokenId: Nat) -> async Result.Result<Nat, Text>;
        ownerOf : query (tokenId: Nat) -> async Principal;
        getMetadata: query () -> async Metadata;
        balanceOf: query (who:Principal) -> async [Nat];
    };

    // DIP20 token actor
    type TxReceiptToken = Result.Result<Nat, {
        #InsufficientBalance;
        #InsufficientAllowance;
    }>;
    type TokenActor = actor {
        allowance: shared (owner: Principal, spender: Principal) -> async Nat;
        approve: shared (spender: Principal, value: Nat) -> async TxReceiptToken;
        balanceOf: (owner: Principal) -> async Nat;
        decimals: () -> async Nat8;
        name: () -> async Text;
        symbol: () -> async Text;
        totalSupply: () -> async Nat;
        transfer: shared (to: Principal, value: Nat) -> async TxReceiptToken;
        transferFrom: shared (from: Principal, to: Principal, value: Nat) -> async TxReceiptToken;
    };

    type StorageActor = actor {
        addRecord: shared (caller: Principal, op: Operation, timestamp: Time.Time) -> async Nat;
        addOrder:  shared (order: OrderExt) -> async Nat;
    };

    private stable var owner: Principal = owner_;
    private stable var wicp: TokenActor = actor(Principal.toText(wicp_));
    private stable var wicpFee: Nat = 10000; // 0.0001 WICP transfer fee
    private stable var storage: StorageActor = actor(Principal.toText(storage_));
    private stable var feeRate: Nat = 20000; // 20000/1e6 = 2%, fee for devs
    private stable var _1e6: Nat = 1_000_000;
    private stable var collectionIndex: Nat = 0;
    private stable var orderIndex: Nat = 0;
    private stable var txcounter: Nat = 0;
    private var collections = HashMap.HashMap<Principal, Collection>(1, Principal.equal, Principal.hash);
    private var orders = HashMap.HashMap<Nat, Order>(1, Nat.equal, Hash.hash);
    private var balances = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
    private stable var collections_entries : [(Principal, Collection)] = [];
    private stable var orders_entries : [(Nat, Order)] = [];
    private stable var balances_entries : [(Principal, Nat)] = [];

    // private helper functions
    private func _collectionExist(token: Principal): Bool {
        switch(collections.get(token)) {
            case(?v) { return true; };
            case(_) { return false; };
        };
    };

    private func _balanceOf(user: Principal): Nat {
        switch(balances.get(user)) {
            case(?v) { return v; };
            case(_) { return 0; };
        };
    };

    private func _transfer(from: Principal, to: Principal, amount: Nat) {
        assert(_balanceOf(from) > amount);
        let from_bal = _balanceOf(from);
        let to_bal = _balanceOf(to);
        balances.put(from, from_bal - amount);
        balances.put(to, to_bal + amount);
    };

    private func _updateCollection(c: Collection, new_orders: Nat, new_historyOrders: Nat, new_volume: Nat): Collection {
        c.orders := new_orders;
        c.historyOrders := new_historyOrders;
        c.volume := new_volume;
        return c;
    };

    private func _toCollectionExt(c: Collection): CollectionExt {
        {
            index = c.index;
            canisterId = c.canisterId;
            creator = c.creator;
            name = c.name;
            desc = c.desc;
            feeRate = c.feeRate;
            orders = c.orders;
            historyOrders = c.orders;
            volume = c.volume;
        }
    };

    private func _toOrderExt(o: Order): OrderExt {
        {
            index = o.index;
            token = o.token;
            tokenIndex = o.tokenIndex;
            owner = o.owner;
            price = o.price;
            status = o.status;
            createAt = o.createAt;
        }
    };

    // add a new collection, only the NFT creator or admin can do this
    public shared(msg) func addCollection(
        token: Principal,
        feeRate: Nat
        ): async Result.Result<Bool, Text> {
        let tokenActor: DIP721Actor = actor(Principal.toText(token));
        let metadata = await tokenActor.getMetadata();
        if (msg.caller != metadata.owner and msg.caller != owner)
            return #err("unauthorized");
        if (_collectionExist(token))
            return #err("collection exist");
        let newCollection: Collection = {
            index = collectionIndex;
            canisterId = token;
            creator = metadata.owner;
            name = metadata.name;
            desc = metadata.desc;
            var feeRate = feeRate;
            var orders = 0;
            var historyOrders = 0;
            var volume = 0;
        };
        collections.put(token, newCollection);
        collectionIndex += 1;
        return #ok(true);
    };

    public shared(msg) func updateCollectionFee(token:Principal, newFeeRate: Nat): async Result.Result<Bool, Text> {
        let tokenActor: DIP721Actor = actor(Principal.toText(token));
        let metadata = await tokenActor.getMetadata();
        if (msg.caller != metadata.owner and msg.caller == owner)
            return #err("unauthorized");
        var c: Collection  = switch(collections.get(token)) {
            case(?v) { v; };
            case(_) { return #err("collection not exist"); };
        };
        c.feeRate := newFeeRate;
        collections.put(token, c);
        return #ok(true);
    };

    // deposit WICP to canister
    public shared(msg) func deposit(amount: Nat): async TxReceipt {
        switch(await wicp.transferFrom(msg.caller, Principal.fromActor(this), amount)) {
            case(#ok(id)) { };
            case(#err(e)) { return #err("deposit fail"); };
        };
        let bal = _balanceOf(msg.caller);
        balances.put(msg.caller, bal + amount);
        ignore storage.addRecord(msg.caller, #deposit({from = msg.caller; to = Principal.fromActor(this); amount = amount}), Time.now());
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    // withdraw WICP from canister
    public shared(msg) func withdraw(amount: Nat): async TxReceipt {
        let bal = _balanceOf(msg.caller);
        if (bal < amount)
            return #err("insufficient balance");
        balances.put(msg.caller, bal - amount);
        switch(await wicp.transfer(msg.caller, amount - wicpFee)) {
            case(#ok(id)) { 
                // msg.caller == this canister
                ignore storage.addRecord(msg.caller, #withdraw({from = Principal.fromActor(this); to = msg.caller; amount = amount}), Time.now());
                txcounter += 1;
                return #ok(txcounter - 1);
			};
            case(#err(e)) {
                // transfer fail, restore user balance
                balances.put(msg.caller, bal);
                return #err("withdraw fail");
            };
        };
    };

    // creates a sell order
    public shared(msg) func listToken(token: Principal, tokenIndex: Nat, price: Nat) : async TxReceipt {
        var collection = switch(collections.get(token)) {
            case(?c) { c };
            case(_) { return #err("collection not exist"); };
        };
        let nftActor : DIP721Actor = actor(Principal.toText(token));
        if (msg.caller != (await nftActor.ownerOf(tokenIndex)))
            return #err("unauthorized");
        // transfer nft to market
        switch(await nftActor.transferFrom(msg.caller, Principal.fromActor(this), tokenIndex)) {
            case(#ok(id)) {};
            case(#err(e)) {
                return #err(e);
            };
        };
        // create sell order
        let order : Order = {
            index = orderIndex;
            token = token;
            tokenIndex = tokenIndex;
            owner = msg.caller;
            var price = price;
            var status = #open(txcounter);
            createAt = Time.now();
        };
        orders.put(orderIndex, order);
        orderIndex += 1;
        // update collection
        collection := _updateCollection(collection, collection.orders + 1, collection.historyOrders, collection.volume);
        collections.put(token, collection);
        // add record
        ignore storage.addRecord(msg.caller, #list({orderId = order.index; token = token; tokenIndex = tokenIndex; seller = msg.caller; price = price}), Time.now());
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    // cancel an order
    public shared(msg) func cancelOrder(orderId: Nat) : async TxReceipt {
        var order = switch(orders.get(orderId)){
            case(?o){ o };
            case(_){ return #err("order not found"); }; // no order
        };
        var collection = switch(collections.get(order.token)){
            case (?c){ c };
            case (_){ return #err("collection not exist"); };
        };
        switch(order.status) {
            case(#open(id)) { };
            case(_) {
                return #err("order not open");
            };
        };
        let nftActor : DIP721Actor = actor(Principal.toText(order.token));
        if (msg.caller != order.owner) // only owner can cancel order
            return #err("not order owner");
        // delete order
        orders.delete(orderId);
        // send nft to msg.caller from this canister
        switch(await nftActor.transferFrom(Principal.fromActor(this), msg.caller, order.tokenIndex)) {
            case(#ok(id)) {
                order.status := #cancel(txcounter);       
                ignore storage.addOrder(_toOrderExt(order));
                ignore storage.addRecord(msg.caller, #cancel({orderId = order.index; token = order.token; tokenIndex = order.tokenIndex; seller = msg.caller; price = order.price}), Time.now());
                // update collection
                collection := _updateCollection(collection, collection.orders - 1, collection.historyOrders, collection.volume);
                collections.put(order.token, collection);
                //count Tx
                txcounter += 1;
                return #ok(txcounter - 1);
            };
            case(#err(e)) {
                orders.put(orderId, order);
                return #err(e);
            };
        };
    };

    public shared(msg) func updatePrice(orderId: Nat, newPrice: Nat): async Result.Result<Bool, Text> {
        var order = switch(orders.get(orderId)){
            case(?o){ o };
            case(_){ return #err("order not exist") };
        };
        if (msg.caller != order.owner)
            return #err("unauthorized");
        switch(order.status) {
            case(#open(id)) { };
            case(_) {
                return #err("order not open");
            };
        };   
        order.price := newPrice; // update new price
        orders.put(orderId, order);
        return #ok(true);
    };

    // buy a listed NFT using the balance inside the market canister
    public shared(msg) func buy(orderId: Nat): async TxReceipt {
        var order = switch(orders.get(orderId)){
            case(?o){ o };
            case(_) { return #err("order not exist"); };
        };
        switch(order.status) {
            case(#open(id)) { };
            case(_) {
                return #err("order not open");
            };
        };
        if (_balanceOf(msg.caller) < order.price)
            return #err("balance insufficient");
        var collection = switch(collections.get(order.token)){
            case (?c){ c };
            case (_){ return #err("collection not exist"); };
        };
        
        // transfer WICP to devs
        let devFee = feeRate * order.price / _1e6;
        _transfer(msg.caller, owner, devFee);
        // transfer WICP to NFT creator
        let creatorFee = collection.feeRate * order.price / _1e6;
        _transfer(msg.caller, collection.creator, creatorFee);
        // transfer WICP to seller
        _transfer(msg.caller, order.owner, order.price - devFee - creatorFee);

        // update order status and transfer NFT to buyer
        let oldStatus = order.status;
        order.status := #done(txcounter);
        orders.put(order.index, order);
        let nftActor: DIP721Actor = actor(Principal.toText(order.token));
        switch(await nftActor.transferFrom(Principal.fromActor(this), msg.caller, order.tokenIndex)) {
            case(#ok(id)) {
                orders.delete(order.index);
                ignore storage.addOrder(_toOrderExt(order));
                ignore storage.addRecord(msg.caller, #buy({orderId = order.index; token = order.token; tokenIndex = order.tokenIndex; seller = order.owner; buyer = msg.caller; price = order.price}), Time.now());
                // update collection
                collection := _updateCollection(collection, collection.orders - 1, collection.historyOrders + 1, collection.volume + order.price);
                collections.put(order.token, collection);
                //count Tx
                txcounter += 1;
                return #ok(txcounter - 1);
            };
            case(#err(e)) {
                // refund buyer
                _transfer(owner, msg.caller, devFee);
                _transfer(collection.creator, msg.caller, creatorFee);
                _transfer(order.owner, msg.caller, order.price - devFee - creatorFee);
                order.status := oldStatus;
                orders.put(order.index, order);
                return #err("buy fail");
            };
        };
    };

    // buy a listed NFT using the balance outside the market canister
    // if lazyBuy fail, user need to withdraw wicp maunally.
    public shared(msg) func lazyBuy(orderId: Nat): async TxReceipt {
        var order = switch(orders.get(orderId)){
            case(?o){ o };
            case(_){ return #err("order not exist"); };
        };
        switch(order.status) {
            case(#open(id)) { };
            case(_) {
                return #err("order not open");
            };
        };

        //1. deposit
        switch(await wicp.transferFrom(msg.caller, Principal.fromActor(this), order.price)) {
            case(#ok(id)) { };
            case(#err(e)) { return #err("deposit fail"); };
        };
        let bal = _balanceOf(msg.caller);
        balances.put(msg.caller, bal + order.price);
        ignore storage.addRecord(msg.caller, #deposit({from = msg.caller; to = Principal.fromActor(this); amount = order.price}), Time.now());
        txcounter += 1;

        //2. buy a listed nft token
        var collection = switch(collections.get(order.token)){
            case (?c){ c };
            case (_){ return #err("collection not exist"); };
        };
        
        // transfer WICP to devs
        let devFee = feeRate * order.price / _1e6;
        _transfer(msg.caller, owner, devFee);
        // transfer WICP to NFT creator
        let creatorFee = collection.feeRate * order.price / _1e6;
        _transfer(msg.caller, collection.creator, creatorFee);
        // transfer WICP to seller
        _transfer(msg.caller, order.owner, order.price - devFee - creatorFee);

        // update order status and transfer NFT to buyer
        let oldStatus = order.status;
        order.status := #done(txcounter);
        orders.put(order.index, order);
        let nftActor: DIP721Actor = actor(Principal.toText(order.token));
        switch(await nftActor.transferFrom(Principal.fromActor(this), msg.caller, order.tokenIndex)) {
            case(#ok(id)) {
                orders.delete(order.index);
                ignore storage.addOrder(_toOrderExt(order));
                ignore storage.addRecord(msg.caller, #buy({orderId = order.index; token = order.token; tokenIndex = order.tokenIndex; seller = order.owner; buyer = msg.caller; price = order.price}), Time.now());
                // update collection
                collection := _updateCollection(collection, collection.orders - 1, collection.historyOrders + 1, collection.volume + order.price);
                collections.put(order.token, collection);
                //count Tx
                txcounter += 1;
                return #ok(txcounter - 1);
            };
            case(#err(e)) {
                // refund buyer
                _transfer(owner, msg.caller, devFee);
                _transfer(collection.creator, msg.caller, creatorFee);
                _transfer(order.owner, msg.caller, order.price - devFee - creatorFee);
                order.status := oldStatus;
                orders.put(order.index, order);
                return #err("NFT transfer failed");
            };
        };
    };

    // public query functions
    public query func getCollections() : async [CollectionExt]{
        var res : [CollectionExt] = [];
        for((_, c) in collections.entries()){
            res := Array.append(res, [_toCollectionExt(c)]);
        };
        res
    };

    public query func getCollection(collection_id : Principal) : async ?CollectionExt{
        do?{
            let res = collections.get(collection_id) !;
            _toCollectionExt(res)
        }
    };

    public query func getOpenOrders() : async [OrderExt]{
        var res : [OrderExt] = [];
        for((_, o) in orders.entries()){
            switch(o.status) {
                case(#open(id)) {
                    res := Array.append(res, [_toOrderExt(o)])
                };
                case(_) {};
            };
        };
        res
    };

    public query func getOrder(orderIndex : Nat) : async ?OrderExt{
        do?{
            let res = orders.get(orderIndex) !;
            _toOrderExt(res)
        }
    };

    public query(msg) func getUserOrders() : async [OrderExt]{
        var res : [OrderExt] = [];
        for((_, o) in orders.entries()){
            if(o.owner == msg.caller){
                res := Array.append(res, [_toOrderExt(o)])
            }
        };
        res
    };

    public query func getCollectionOrders(collection_id: Principal) : async Nat{
        switch(collections.get(collection_id)){
            case (?c){return c.orders};
            case (_){ return 0; };
        };
    };

    public query func getCollectionHistoryOrders(collection_id: Principal) : async Nat{
        switch(collections.get(collection_id)){
            case (?c){return c.historyOrders};
            case (_){ return 0; };
        };
    };

    public query func getCollectionVolume(collection_id: Principal) : async Nat {
        switch(collections.get(collection_id)){
            case (?c){return c.volume};
            case (_){ return 0; };
        };
    };

    public query func getTotalVolume() : async Nat {
        var totalVolume = 0;
        for((_, c) in collections.entries()){
            totalVolume += c.volume;
        };
        totalVolume
    };

    public shared(msg) func getUserNfts(): async [(Principal,[Nat])]{
        var size = collections.size();
        var res : [(Principal, [Nat])] = [];
        for((token, _) in collections.entries()) {
            let tokenActor: DIP721Actor = actor(Principal.toText(token));
            let nfts: [Nat] = await tokenActor.balanceOf(msg.caller);
            res := Array.append(res,[(token, nfts)]);
        };
        res
    };

	// system upgrade functions
	system func preupgrade(){
        collections_entries := Iter.toArray(collections.entries());
        orders_entries := Iter.toArray(orders.entries());
        balances_entries := Iter.toArray(balances.entries());
    };

    system func postupgrade(){
        collections := HashMap.fromIter<Principal, Collection>(
            collections_entries.vals(),
            collections_entries.size(),
            Principal.equal,
            Principal.hash
        );
        collections_entries := [];
        orders := HashMap.fromIter<Nat, Order>(
            orders_entries.vals(),
            orders_entries.size(),
            Nat.equal,
            Hash.hash
        );
        orders_entries := [];
        balances := HashMap.fromIter<Principal, Nat>(
            balances_entries.vals(),
            balances_entries.size(),
            Principal.equal,
            Principal.hash
        );
        balances_entries := [];
    };
}
