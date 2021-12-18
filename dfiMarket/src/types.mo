/**
 * Module     : types.mo
 * Copyright  : 2021 Mixlabs
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : Mixlabs Team <hello@dfinance.ai>
 * Stability  : Experimental
 */

import Time "mo:base/Time";

module {
    public type Operation = {
        #deposit : {
            from: Principal;
            to: Principal;
            amount: Nat;
        };
        #withdraw : {
            from: Principal;
            to: Principal;
            amount: Nat;
        };
        #list : {
            orderId: Nat;
            token: Principal;
            tokenIndex: Nat;
            seller: Principal;
            price: Nat;
        };
        #cancel : {
            orderId: Nat;
            token: Principal;
            tokenIndex: Nat;
            seller: Principal;
            price: Nat;
        };
        #buy : {
            orderId: Nat;
            token: Principal;
            tokenIndex: Nat;
            seller: Principal;
            buyer: Principal;
            price: Nat;
        };
    };
    public type TxRecord = {
        index: Nat;
        op: Operation;
        timestamp: Int;
    };

    public type OrderStatus = {
        #open: Nat; // list tx id
        #cancel: Nat; // cancel tx id
        #done: Nat; // buy tx id
    };
};