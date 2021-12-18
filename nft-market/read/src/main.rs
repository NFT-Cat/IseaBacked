use dfn_core::api::call_with_cleanup;
use dfn_protobuf::protobuf;
use ic_types::{CanisterId, PrincipalId};
use candid::{candid_method, Nat};
use ledger_canister::{account_identifier::{AccountIdentifier, Subaccount}, BlockRes, BlockHeight, Memo, Transfer};
use lazy_static::lazy_static;
use std::sync::RwLock;
use std::collections::HashSet;
use ic_cdk::{export::{Principal, candid}, api};
use ic_cdk_macros::*;

const LEDGER_CANISTER_ID: CanisterId = CanisterId::from_u64(2);
const NFTMEMO: u64 = 0x54464Eu64; // "NFT"
const MEMO_PLACEHOLD: u64 = 100_000_000;
static mut MARKET: CanisterId = CanisterId::from_u64(0);
static mut ADMIN: Principal = Principal::anonymous();
lazy_static! {
    static ref BLOCKUSED: RwLock<HashSet<BlockHeight>> = RwLock::new(HashSet::new());
}

#[init]
fn init() {
    unsafe {
        ADMIN = api::caller();
    }
}

#[update]
#[candid_method(update)]
fn set_market(market: CanisterId) {
    unsafe {
        assert_eq!(api::caller(), ADMIN, "Only admin can set market.");
        MARKET = market;
    }
}

#[update]
#[candid_method(update)]
async fn is_payed(block_height: BlockHeight, from_subaccount: Option<Subaccount>, from: PrincipalId, to: AccountIdentifier, value: u64, index: Nat) -> bool {
    unsafe {
        assert_eq!(api::caller(), MARKET.get().into(), "only Market canister can call this.");
    }
    assert_eq!(BLOCKUSED.read().unwrap().contains(&block_height), false, "The buy transaction has already been minted.");
    let memo: Nat = index * Nat::from(MEMO_PLACEHOLD) + Nat::from(NFTMEMO);
    
    let res: Result<BlockRes, (Option<i32>, String)> = call_with_cleanup(
        LEDGER_CANISTER_ID,
        "block_pb",
        protobuf,
        block_height
    )
    .await;
    BLOCKUSED.write().unwrap().insert(block_height);
    let block = res.unwrap().0.unwrap().unwrap().decode().expect("unable to decode block");  
    let (from_origin, to_origin, amount_origin) = match block.transaction().transfer {
        Transfer::Send {
            from, to, amount, ..
        } => (from, to, amount),
        _ => panic!("Notification failed transfer must be of type send"),
    };
    let Memo(_memo) = block.transaction().memo;
    let memo_origin = Nat::from(_memo);
    let from_account = AccountIdentifier::new(from, from_subaccount);
    assert_eq!((from_account, to, value, memo), (from_origin, to_origin, amount_origin.get_e8s(), memo_origin), "sender and recipient must match the specified block");
    return true;
}

#[cfg(not(any(target_arch = "wasm32", test)))]
fn main() {
    candid::export_service!();
    std::print!("{}", __export_service());
}

#[cfg(any(target_arch = "wasm32", test))]
fn main() {}