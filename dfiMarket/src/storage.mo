/**
 * Module     : storage.mo
 * Copyright  : 2021 DFinance Team
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : DFinance Team <hello@dfinance.ai>
 * Stability  : Experimental
 */

// transaction history storage canister

import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Types "./types";

shared(msg) actor class Storage(_owner: Principal) {
    /// Update call operations
    public type Operation = Types.Operation;
    /// Update call operation record fields
    public type OpRecord = Types.TxRecord;
    public type OrderStatus = Types.OrderStatus;

    public type OrderExt = {
        index: Nat;
        token: Principal; // token canister ID
        tokenIndex: Nat; // token index
        owner: Principal;
        price: Nat; // can edit price after listing
        status: OrderStatus; // upadte to #done after order execution
        createAt: Int;
    };

    private stable var owner_ : Principal = _owner;
    private stable var market_canister_id_ : Principal = msg.caller;
    private stable var records: [OpRecord] = [];
    private stable var orders: [OrderExt] = [];
    private stable var currentTxIndex : Nat = 0;
    private stable var currentOrderIndex : Nat = 0;
    private var ops_acc = HashMap.HashMap<Principal, [Nat]>(1, Principal.equal, Principal.hash);
    private var orders_acc = HashMap.HashMap<Principal, [Nat]>(1, Principal.equal, Principal.hash);
    private stable var opsAccEntries: [(Principal, [Nat])] = [];
    private stable var ordersAccEntries: [(Principal, [Nat])] = [];

    public shared(msg) func clearData() : async Bool {
        assert(msg.caller == owner_);
        ops_acc := HashMap.HashMap<Principal, [Nat]>(1, Principal.equal, Principal.hash);
        return true;
    };

    public shared(msg) func setMarketCanisterId(token: Principal) : async Bool {
        assert(msg.caller == owner_);
        market_canister_id_ := token;
        return true;
    };

    private func _putOpsAcc(who: Principal, o: OpRecord) {
        switch (ops_acc.get(who)) {
            case (?op_acc) {
                var op_new : [Nat] = Array.append(op_acc, [o.index]);
                ops_acc.put(who, op_new);
            };
            case (_) {
                ops_acc.put(who, [o.index]);
            };   
        }
    };

    private func _putOrdsAcc(who: Principal, ord: OrderExt, idx: Nat) {
        switch (orders_acc.get(who)) {
            case (?ord_acc) {
                var ord_new : [Nat] = Array.append(ord_acc, [idx]);
                orders_acc.put(who, ord_new);
            };
            case (_) {
                orders_acc.put(who, [ord.index]);
            };   
        }
    };

    public shared(msg) func addRecord(caller: Principal, op: Operation, timestamp: Time.Time) : async Nat {
        assert(msg.caller == market_canister_id_);
        let o : OpRecord = {
            index = currentTxIndex;
            op = op;
            timestamp = timestamp;
        };
        currentTxIndex += 1;
        records := Array.append(records, [o]);
        _putOpsAcc(caller, o);
        return o.index;
    };
  
    public shared(msg) func addOrder(order: OrderExt) : async Nat {
        assert(msg.caller == market_canister_id_);
        orders := Array.append(orders, [order]);
        _putOrdsAcc(order.owner, order, currentOrderIndex);
        currentOrderIndex += 1; // position in orders array
        return currentOrderIndex - 1;
    };

    /*** Tx history query functions ***/
    /// Get History by index.
    public query func getTransaction(index: Nat) : async OpRecord {
        return records[index];
    };
   
    /// Get history
    public query func getTransactions(start: Nat, num: Nat) : async [OpRecord] {
        var ret: [OpRecord] = [];
        var i = start;
        while(i < start + num and i < records.size()) {
            ret := Array.append(ret, [records[i]]);
            i += 1;
        };
        return ret;
    };

    public query func getUserTransactionAmount(a: Principal) : async Nat {
        switch(ops_acc.get(a)) {
            case(?op_acc) { return op_acc.size(); };
            case(_) { return 0; };
        };
    };

    public query func getUserTransactions(a: Principal, start: Nat, num: Nat) : async [OpRecord] {
        let tx_indexs: [Nat] = switch (ops_acc.get(a)) {
            case (?op_acc) {
                op_acc
            };
            case (_) {
                []
            };
        };
        var ret: [OpRecord] = [];
        var i = start;
        while(i < start + num and i < tx_indexs.size()) {
            ret := Array.append(ret, [records[tx_indexs[i]]]);
            i += 1;
        };
        return ret;
    };

    /*** Orders query functions ***/
    // user history orders
    public query func getUserOrderAmount(a: Principal): async Nat {
        let order_indexs: [Nat] = switch(orders_acc.get(a)) {
            case (?or_acc) {
                or_acc
            };
            case (_) {
                []
            };
        };
        return order_indexs.size()
    };

    // user partial history orders 
    public query func getUserOrders(a: Principal, start: Nat, num: Nat): async [OrderExt] {
        let order_indexs: [Nat] = switch (orders_acc.get(a)) {
            case (?or_acc) {
                or_acc
            };
            case (_) {
                []
            };
        };
        var ret: [OrderExt] = [];
        var i = start;
        while(i < start + num and i < order_indexs.size()) {
            ret := Array.append(ret, [orders[order_indexs[i]]]);
            i += 1;
        };
        return ret;
    };
    
    /// Get all update call history.
    public query func allHistory() : async [OpRecord] {
        return records;
    };

    public query func marketCanisterId() : async Principal {
        return market_canister_id_;
    };

    public query func owner() : async Principal {
        return owner_;
    };

    public query func opAmount() : async Nat {
        return records.size();
    };

    public query func getCycles() : async Nat {
        return ExperimentalCycles.balance();
    };

    system func preupgrade() {
        opsAccEntries := Iter.toArray(ops_acc.entries());
        ordersAccEntries := Iter.toArray(orders_acc.entries());
    };

    system func postupgrade() {
        ops_acc := HashMap.fromIter<Principal, [Nat]>(opsAccEntries.vals(), 1, Principal.equal, Principal.hash);
        orders_acc := HashMap.fromIter<Principal, [Nat]>(ordersAccEntries.vals(), 1, Principal.equal, Principal.hash);
        opsAccEntries := [];
        ordersAccEntries := [];
    };
};