import Int "mo:base/Int";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Model "./Model";
import DataSet "../src/DataSet";

actor {

    stable var data1 : [Model.TestData] = [];
    stable var data2 : [Model.TestData2] = [];
    private var db1 : DataSet.DataSet<Model.TestData> = DataSet.fromArray<Model.TestData>(data1);
    private var db2 : DataSet.DataSet<Model.TestData2> = DataSet.fromArray<Model.TestData2>(data2);

    public shared(msg) func insert1(id : Nat, name : Text) : async Nat {
        let data : Model.TestData = {
            id = id;
            name = name;
        };
        db1.insert(data)
    };

    public shared(msg) func update1(id : Nat, name : Text) : async Int {
        let data : Model.TestData = {
            id = id;
            name = name;
        };
        db1.update(data, func (v : Model.TestData) : Bool {
            return v.id == id;
        })
    };

    public shared(msg) func delete1(id : Nat) : async Int {
        db1.delete(func (v : Model.TestData) : Bool {
            return v.id == id;
        })
    };

    public query func get1(id : Nat) : async ?Text {
        switch(db1.selectOne(func (v : Model.TestData) : Bool {
            v.id == id;
        })) {
            case null {
                null
            };
            case (?value) {
                ?value.name
            };
        }
    };

    public query func count1() : async Nat {
        db1.countAll()
    };

    public shared(msg) func insert2(trxId : Nat, id : Nat, name : Text) : async Nat {
        let data : Model.TestData = {
            id = id;
            name = name;
        };
        db1.insertWithTrx(trxId, data)
    };

    public shared(msg) func update2(trxId : Nat, id : Nat, name : Text) : async Int {
        let data : Model.TestData = {
            id = id;
            name = name;
        };
        db1.updateWithTrx(trxId, data, func (v : Model.TestData) : Bool {
            return v.id == id;
        })
    };

    public shared(msg) func updateByRowId2(trxId : Nat, rowId : Nat, id : Nat, name : Text) : async Int {
        let data : Model.TestData = {
            id = id;
            name = name;
        };
        db1.updateByRowIdWithTrxId(trxId, rowId, data)
    };

    public shared(msg) func delete2(trxId : Nat, id : Nat) : async Int {
        db1.deleteWithTrx(trxId, func (v : Model.TestData) : Bool {
            return v.id == id;
        })
    };

    public shared(msg) func deleteByRowId2(trxId : Nat, rowId : Nat) : async Int {
        db1.deleteByRowIdWithTrx(trxId, rowId)
    };

    public query func get2(trxId : Nat, id : Nat) : async ?Text {
        switch(db1.selectOneWithTrx(trxId, func (v : Model.TestData) : Bool {
            v.id == id;
        })) {
            case null {
                null
            };
            case (?value) {
                ?value.name
            };
        }
    };

    public query func count2(trxId : Nat) : async Nat {
        db1.countAllWithTrx(trxId)
    };

    public query func getMinLocalTrx() : async DataSet.LocalTrx {
        db1.getMinLocalTrx();
    };

    public query func getTrxMapping() : async [(Nat, DataSet.LocalTrx)] {
        db1.getTrxMapping();
    };

    public shared(msg) func startTrx(trxId : Nat) : async () {
        db1.startTrx(trxId);
    };

    public shared(msg) func commitTrx(trxId : Nat) : async () {
        try {
            db1.tryCommit(trxId);
            db2.tryCommit(trxId);

            db1.commit(trxId);
            db2.commit(trxId);
        } catch(e) {
            db1.rollback(trxId);
            db2.rollback(trxId);
        };
    };

    public shared(msg) func rollbackTrx(trxId : Nat) : async () {
        db1.rollback(trxId);
        db2.rollback(trxId);
    };

    public shared(msg) func tryCommit(trxId : Nat) : async () {
        db1.tryCommit(trxId);
        db2.tryCommit(trxId);
    };

    public shared(msg) func commit(trxId : Nat) : async () {
        db1.commit(trxId);
        db2.commit(trxId);
    };

    public shared(msg) func rollback(trxId : Nat) : async () {
        db1.rollback(trxId);
        db2.rollback(trxId);
    };

};