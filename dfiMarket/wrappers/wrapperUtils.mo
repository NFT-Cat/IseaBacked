
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";

module WrapperUtils = {

    public type TokenIdentifier  = Text;
      public type TokenIndex = Nat32;
      public type TokenObj = {
        index : TokenIndex;
        canister : [Nat8];
      };

    public module TokenIdentifier = {
        private let tds : [Nat8] = [10, 116, 105, 100]; //b"\x0Atid"
        public let equal = Text.equal;
        public let hash = Text.hash;
        /*
        public func fromText(t : Text, i : TokenIndex) : TokenIdentifier {
          return fromPrincipal(Principal.fromText(t), i);
        };
        public func fromPrincipal(p : Principal, i : TokenIndex) : TokenIdentifier {
          return fromBlob(Principal.toBlob(p), i);
        };
        public func fromBlob(b : Blob, i : TokenIndex) : TokenIdentifier {
          return fromBytes(Blob.toArray(b), i);
        };
        public func fromBytes(c : [Nat8], i : TokenIndex) : TokenIdentifier {
          let bytes : [Nat8] = Array.append(Array.append(tds, c), nat32tobytes(i));
          return Hex.encode(Array.append(crc, bytes));
        };
        */
        //Coz can't get principal directly, we can compare the bytes
        public func isPrincipal(tid : TokenIdentifier, p : Principal) : Bool {
          let tobj = decode(tid);
          return Blob.equal(Blob.fromArray(tobj.canister), Principal.toBlob(p));
        };
        public func getIndex(tid : TokenIdentifier) : TokenIndex {
          let tobj = decode(tid);
          tobj.index;
        };
        public func decode(tid : TokenIdentifier) : TokenObj {
          let bytes = Blob.toArray(Principal.toBlob(Principal.fromText(tid)));
          var index : Nat8 = 0;
          var _canister : [Nat8] = [];
          var _token_index : [Nat8] = [];
          var _tdscheck : [Nat8] = [];
          var length : Nat8 = 0;
          for (b in bytes.vals()) {
            length += 1;
            if (length <= 4) {
              _tdscheck := Array.append(_tdscheck, [b]);
            };
            if (length == 4) {
              if (Array.equal(_tdscheck, tds, Nat8.equal) == false) {
                return {
                  index = 0;
                  canister = bytes;
                };
              };
            };
          };
          for (b in bytes.vals()) {
            index += 1;
            if (index >= 5) {
              if (index <= (length - 4)) {
                _canister := Array.append(_canister, [b]);
              } else {
                _token_index := Array.append(_token_index, [b]);
              };
            };
          };
          let v : TokenObj = {
            index = bytestonat32(_token_index);
            canister = _canister;
          };
          return v;
        };

        private func bytestonat32(b : [Nat8]) : Nat32 {
          var index : Nat32 = 0;
          Array.foldRight<Nat8, Nat32>(b, 0, func (u8, accum) {
            index += 1;
            accum + Nat32.fromNat(Nat8.toNat(u8)) << ((index-1) * 8);
          });
        };
        private func nat32tobytes(n : Nat32) : [Nat8] {
          if (n < 256) {
            return [1, Nat8.fromNat(Nat32.toNat(n))];
          } else if (n < 65536) {
            return [
              2,
              Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)),
              Nat8.fromNat(Nat32.toNat((n) & 0xFF))
            ];
          } else if (n < 16777216) {
            return [
              3,
              Nat8.fromNat(Nat32.toNat((n >> 16) & 0xFF)),
              Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)),
              Nat8.fromNat(Nat32.toNat((n) & 0xFF))
            ];
          } else {
            return [
              4,
              Nat8.fromNat(Nat32.toNat((n >> 24) & 0xFF)),
              Nat8.fromNat(Nat32.toNat((n >> 16) & 0xFF)),
              Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)),
              Nat8.fromNat(Nat32.toNat((n) & 0xFF))
            ];
          };
        };
      };
    };