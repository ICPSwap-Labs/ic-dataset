import Int "mo:base/Int";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

actor {

    private var nextId : Nat = 1;

    private var transactions : HashMap.HashMap<Nat, [Text]> = HashMap.HashMap<Nat, [Text]>(1, Nat.equal, Hash.hash);

    public type TrxCanister = actor {
        tryCommit : shared (trxId : Nat) -> async ();
        commit : shared (trxId : Nat) -> async ();
        rollback : shared (trxId : Nat) -> async ();
    };

    public shared(msg) func begin(trxCanisterIds : [Text]) : async Nat {
        let trxId: Nat = nextId;
        transactions.put(trxId, trxCanisterIds);
        nextId += 1;
        trxId
    };

    public func commit(trxId : Nat) : async Bool {
        try {
            switch(transactions.get(trxId)) {
                case null {
                    return true;
                };
                case (?trxCanisterIds) {
                    for (trxCanisterId in trxCanisterIds.vals()) {
                        let trxCanister = actor(trxCanisterId): TrxCanister;
                        await trxCanister.tryCommit(trxId);
                    };
                    for (trxCanisterId in trxCanisterIds.vals()) {
                        let trxCanister = actor(trxCanisterId): TrxCanister;
                        await trxCanister.commit(trxId);
                    };
                    return true;
                };
            };
        } catch(e) {
            return await rollback(trxId);
        };
    };

    public func rollback(trxId : Nat) : async Bool {
        switch(transactions.get(trxId)) {
            case null {
                return true;
            };
            case (?trxCanisterIds) {
                for (trxCanisterId in trxCanisterIds.vals()) {
                    let trxCanister = actor(trxCanisterId): TrxCanister;
                    await trxCanister.rollback(trxId);
                };
                return true;
            };
        };
    };

};