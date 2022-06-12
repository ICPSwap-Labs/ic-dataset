import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Debug "mo:base/Debug";

module {

    public type Data<T> = {
        trxId : Nat;
        committed : Bool;
        deleted : Bool;
        val : ?T;
    };

    public type ActiveTrxSnapshot = {
        minTrxId : Nat;
        maxTrxId : Nat;
        activeTrxIds : [Nat];
    };

    public type LocalTrx = {
        trxId : Nat;
        trxSnapshot : ActiveTrxSnapshot;
    };

    public class DataRow<T>(_rowId : Nat) {

        private let rowId : Nat = _rowId;
        private var locked : Bool = false;
        private var lockTrxId : ?Nat = null;
        private var deleted : Bool = false;
        private var dataVersions : List.List<Data<T>> = List.nil<Data<T>>();

        public func add(_trxId : Nat, _val : ?T) : () {
            locked := true;
            lockTrxId := ?_trxId;
            var _deleted : Bool = false;
            switch(_val) {
                case null {
                    _deleted := true;
                };
                case (?v) {};
            };
            let data : Data<T> = {
                trxId = _trxId;
                committed = false;
                deleted = _deleted;
                val = _val;
            };

            dataVersions := List.filter<Data<T>>(dataVersions, func (_data : Data<T>) : Bool {
                return _data.trxId != _trxId;
            });
            dataVersions := List.push<Data<T>>(data, dataVersions);
        };

        public func get(_trx : LocalTrx) : ?T {
            switch(List.find<Data<T>>(dataVersions, func (_data : Data<T>) : Bool {
                return _data.trxId == _trx.trxId;
            })) {
                case (?data) {
                    return data.val;
                };
                case null {
                    switch(List.find<Data<T>>(dataVersions, func (_data : Data<T>) : Bool {
                        if (_data.committed) {
                            if (_data.trxId > _trx.trxSnapshot.maxTrxId) {
                                return false;
                            } else if (_data.trxId < _trx.trxSnapshot.minTrxId) {
                                return true;
                            } else {
                                switch(Array.find<Nat>(_trx.trxSnapshot.activeTrxIds, func (activeTrxId : Nat) : Bool{
                                    return _data.trxId == activeTrxId;
                                })) {
                                    case null {
                                        return true;
                                    };
                                    case (?id) {
                                        return false;
                                    };
                                };
                            };
                        };
                        return false;
                    })) {
                        case (?data) {
                            return data.val;
                        };
                        case null {
                            return null;
                        };
                    };
                };
            };
            null
        };

        public func getCommited() : ?T {
            switch(List.find<Data<T>>(dataVersions, func (_data : Data<T>) : Bool {
                return _data.committed;
            })) {
                case (?data) {
                    return data.val;
                };
                case null {
                    return null;
                };
            };
        };

        public func isLocked(_trxId : ?Nat) : Bool {
            switch(_trxId) {
                case null {
                    return locked;
                };
                case (?trxId) {
                    switch(lockTrxId) {
                        case null {
                            return locked;
                        };
                        case (?lockId) {
                            return locked and trxId != lockId;
                        };
                    };
                };
            };
        };

        public func isDeleted() : Bool {
            return deleted;
        };

        public func isNil() : Bool {
            return List.size<Data<T>>(dataVersions) == 0;
        };

        public func commit(_trxId : Nat) : () {
            switch(List.find<Data<T>>(dataVersions, func (_data : Data<T>) : Bool {
                return _data.trxId == _trxId;
            })) {
                case (?data) {
                    let commitData : Data<T> = {
                        trxId = data.trxId;
                        committed = true;
                        deleted = data.deleted;
                        val = data.val;
                    };
                    if (data.deleted) {
                        deleted := true;
                    };
                    
                    dataVersions := List.filter<Data<T>>(dataVersions, func (_data : Data<T>) : Bool {
                        return _data.trxId != _trxId;
                    });
                    dataVersions := List.push<Data<T>>(commitData, dataVersions);
                    locked := false;
                    lockTrxId := null;
                };
                case null {};
            };
        };

        public func rollback(_trxId : Nat) : () {
            dataVersions := List.filter<Data<T>>(dataVersions, func (_data : Data<T>) : Bool {
                if (_data.trxId == _trxId) {
                    locked := false;
                    lockTrxId := null;
                };
                return _data.trxId != _trxId;
            });
        };

        public func remove(_minTrx : LocalTrx) : () {
            var flag : Bool = false;
            dataVersions := List.mapFilter<Data<T>, Data<T>>(dataVersions, func (_data : Data<T>) : ?Data<T> {
                if (not flag) {
                    if (_data.trxId > _minTrx.trxSnapshot.maxTrxId) {
                        return ?_data;
                    } else if (_data.trxId < _minTrx.trxSnapshot.minTrxId) {
                        flag := true;
                        return ?_data;
                    } else {
                        switch(Array.find<Nat>(_minTrx.trxSnapshot.activeTrxIds, func (activeTrxId : Nat) : Bool{
                            return _data.trxId == activeTrxId;
                        })) {
                            case null {
                                flag := true;
                                return ?_data;
                            };
                            case (?id) {
                                return ?_data;
                            };
                        };
                    };
                };
                null
            });
        };
    };

};