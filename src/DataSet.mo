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
import DataRow "./DataRow";

module {

    public type Data<T> = DataRow.Data<T>;

    public type ActiveTrxSnapshot = DataRow.ActiveTrxSnapshot;

    public type LocalTrx = DataRow.LocalTrx;

    public type DoType = {
        #insert;
        #update;
        #delete;
    };

    public type TrxLog = {
        doType : DoType;
        rowId : Nat;
    };

    public class DataSet<T>() {

        private var nextRowId : Nat = 0;
        private var nextLoaclTrxId : Nat = 0;
        private var minLocalTrx : LocalTrx = {
            trxId = 0;
            trxSnapshot = {
                minTrxId = 0;
                maxTrxId = 0;
                activeTrxIds = [];
            };
        };
        private var trxMapping : HashMap.HashMap<Nat, LocalTrx> = HashMap.HashMap<Nat, LocalTrx>(12, Nat.equal, Hash.hash);
        private var committedRows : [Nat] = [];
        private var dataRows : HashMap.HashMap<Nat, DataRow.DataRow<T>> = HashMap.HashMap<Nat, DataRow.DataRow<T>>(12, Nat.equal, Hash.hash);
        private var redoLog : HashMap.HashMap<Nat, HashMap.HashMap<Nat, TrxLog>> = HashMap.HashMap<Nat, HashMap.HashMap<Nat, TrxLog>>(12, Nat.equal, Hash.hash);
        private var undoLog : HashMap.HashMap<Nat, HashMap.HashMap<Nat, TrxLog>> = HashMap.HashMap<Nat, HashMap.HashMap<Nat, TrxLog>>(12, Nat.equal, Hash.hash);
        
        public func startTrx(trxId : Nat) : () {
            ignore getLocalTrxId(trxId);
        };

        public func getMinLocalTrx() : LocalTrx {
            minLocalTrx
        };

        public func getTrxMapping() : [(Nat, LocalTrx)] {
            Iter.toArray(trxMapping.entries())
        };

        //return a row id.
        public func insert(value : T) : Nat {
            let rowId : Nat = nextRowId;
            let data : DataRow.DataRow<T> = DataRow.DataRow<T>(rowId);
            data.add(nextLoaclTrxId, ?value);
            data.commit(nextLoaclTrxId);
            dataRows.put(rowId, data);

            nextRowId += 1;
            nextLoaclTrxId += 1;
            rowId
        };

        public func insertWithTrx(trxId : Nat, value : T) : Nat {
            let rowId : Nat = nextRowId;
            let data : DataRow.DataRow<T> = DataRow.DataRow<T>(rowId);
            let localTrx : LocalTrx = getLocalTrxId(trxId);
            data.add(localTrx.trxId, ?value);
            dataRows.put(rowId, data);

            let redo : TrxLog = {
                doType = #insert;
                rowId = rowId;
            };
            addRedoLog(redo, localTrx.trxId);

            let undo : TrxLog = {
                doType = #delete;
                rowId = rowId;
            };
            addUndoLog(undo, localTrx.trxId);

            nextRowId += 1;
            rowId
        };

        public func insertAll(values : [T]) : () {
            for (value in values.vals()) {
                let rowId : Nat = nextRowId;
                let data : DataRow.DataRow<T> = DataRow.DataRow<T>(rowId);
                data.add(nextLoaclTrxId, ?value);
                data.commit(nextLoaclTrxId);
                dataRows.put(rowId, data);

                nextRowId += 1;
            };
            
            nextLoaclTrxId += 1;
        };

        //return the number of update rows.
        //If return -1, it means update failed by transaction lock.
        public func updateByRowId(rowId : Nat, value : T) : Int {
            switch (dataRows.get(rowId)) {
                case null {
                    return 0;
                };
                case (?data) {
                    if (data.isLocked(null)) {
                        return -1;
                    };
                    if (data.isDeleted()) {
                        return 0;
                    };

                    data.add(nextLoaclTrxId, ?value);
                    data.commit(nextLoaclTrxId);
                    nextLoaclTrxId += 1;
                    return 1;
                };
            };
        };

        public func updateByRowIdWithTrxId(trxId : Nat, rowId : Nat, value : T) : Int {
            switch (dataRows.get(rowId)) {
                case null {
                    return 0;
                };
                case (?data) {
                    if (data.isLocked(?trxId)) {
                        return -1;
                    };
                    if (data.isDeleted()) {
                        return 0;
                    };
                    
                    let localTrx : LocalTrx = getLocalTrxId(trxId);
                    data.add(localTrx.trxId, ?value);

                    let redo : TrxLog = {
                        doType = #update;
                        rowId = rowId;
                    };
                    addRedoLog(redo, localTrx.trxId);

                    let undo : TrxLog = {
                        doType = #update;
                        rowId = rowId;
                    };
                    addUndoLog(undo, localTrx.trxId);
                    return 1;
                };
            };
        };

        public func update(value : T, equal : T -> Bool) : Int {
            var count : Int = 0;
            for ((rowId, data) in dataRows.entries()) {
                switch(data.getCommited()) {
                    case null {};
                    case (?v) {
                        if (equal(v) and not data.isLocked(null) and not data.isDeleted()) {
                            data.add(nextLoaclTrxId, ?value);
                            data.commit(nextLoaclTrxId);
                            count += 1;
                        };
                    };
                };
            };
            if (count > 0) {
                nextLoaclTrxId += 1;
            };
            count
        };

        public func updateWithTrx(trxId : Nat, value : T, equal : T -> Bool) : Int {
            var count : Int = 0;
            let localTrx : LocalTrx = getLocalTrxId(trxId);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.get(localTrx)) {
                    case null {};
                    case (?v) {
                        if (equal(v) and not data.isLocked(?trxId) and not data.isDeleted()) {
                            data.add(localTrx.trxId, ?value);

                            let redo : TrxLog = {
                                doType = #update;
                                rowId = rowId;
                            };
                            addRedoLog(redo, localTrx.trxId);

                            let undo : TrxLog = {
                                doType = #update;
                                rowId = rowId;
                            };
                            addUndoLog(undo, localTrx.trxId);

                            count += 1;
                        };
                    };
                };
            };
            count
        };

        //return the number of delete rows.
        //If return -1, it means delete failed by transaction lock.
        public func deleteByRowId(rowId : Nat) : Int {
            switch (dataRows.get(rowId)) {
                case null {
                    return 0;
                };
                case (?data) {
                    if (data.isLocked(null)) {
                        return -1;
                    };
                    if (data.isDeleted()) {
                        return 0;
                    };
                    data.add(nextLoaclTrxId, null);
                    data.commit(nextLoaclTrxId);
                    nextLoaclTrxId += 1;
                    if (data.isDeleted()) {
                        dataRows.delete(rowId);
                    };
                    return 1;
                };
            };
        };

        public func deleteByRowIdWithTrx(trxId : Nat, rowId : Nat) : Int {
            switch (dataRows.get(rowId)) {
                case null {
                    return 0;
                };
                case (?data) {
                    if (data.isLocked(?trxId)) {
                        return -1;
                    };
                    if (data.isDeleted()) {
                        return 0;
                    };

                    let localTrx : LocalTrx = getLocalTrxId(trxId);
                    data.add(localTrx.trxId, null);

                    let redo : TrxLog = {
                        doType = #delete;
                        rowId = rowId;
                    };
                    addRedoLog(redo, localTrx.trxId);

                    let undo : TrxLog = {
                        doType = #insert;
                        rowId = rowId;
                    };
                    addUndoLog(undo, localTrx.trxId);
                    return 1;
                };
            };
        };

        public func delete(equal : T -> Bool) : Int {
            var count : Int = 0;
            for ((rowId, data) in dataRows.entries()) {
                switch(data.getCommited()) {
                    case null {};
                    case (?v) {
                        if (equal(v) and not data.isLocked(null) and not data.isDeleted()) {
                            data.add(nextLoaclTrxId, null);
                            data.commit(nextLoaclTrxId);
                            if (data.isDeleted()) {
                                dataRows.delete(rowId);
                            };
                            count += 1;
                        };
                    };
                };
            };
            if (count > 0) {
                nextLoaclTrxId += 1;
            };
            count
        };

        public func deleteWithTrx(trxId : Nat, equal : T -> Bool) : Int {
            var count : Int = 0;
            let localTrx : LocalTrx = getLocalTrxId(trxId);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.get(localTrx)) {
                    case null {};
                    case (?v) {
                        if (equal(v) and not data.isLocked(?trxId) and not data.isDeleted()) {
                            data.add(localTrx.trxId, null);

                            let redo : TrxLog = {
                                doType = #delete;
                                rowId = rowId;
                            };
                            addRedoLog(redo, localTrx.trxId);

                            let undo : TrxLog = {
                                doType = #insert;
                                rowId = rowId;
                            };
                            addUndoLog(undo, localTrx.trxId);

                            count += 1;
                        };
                    };
                };
            };
            count
        };

        public func countAll() : Nat {
            var count : Nat = 0;
            for ((rowId, data) in dataRows.entries()) {
                switch(data.getCommited()) {
                    case null {};
                    case (?v) {
                        count += 1;
                    };
                };
            };
            count
        };

        public func countAllWithTrx(trxId : Nat) : Nat {
            var count : Nat = 0;
            let localTrx : LocalTrx = findLocalTrxId(trxId);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.get(localTrx)) {
                    case null {};
                    case (?v) {
                        count += 1;
                    };
                };
            };
            count
        };

        public func count(equal : T -> Bool) : Nat {
            var count : Nat = 0;
            for ((rowId, data) in dataRows.entries()) {
                switch(data.getCommited()) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            count += 1;
                        };
                    };
                };
            };
            count
        };

        public func countWithTrx(trxId : Nat, equal : T -> Bool) : Nat {
            var count : Nat = 0;
            let localTrx : LocalTrx = findLocalTrxId(trxId);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.get(localTrx)) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            count += 1;
                        };
                    };
                };
            };
            count
        };

        public func selectByRowId(rowId : Nat) : ?T {
            switch(dataRows.get(rowId)) {
                case null {
                    return null;
                };
                case (?data) {
                    return data.getCommited();
                };
            };
        };

        public func selectByRowIdWithTrx(trxId: Nat, rowId : Nat) : ?T {
            switch(dataRows.get(rowId)) {
                case null {
                    return null;
                };
                case (?data) {
                    let localTrx : LocalTrx = findLocalTrxId(trxId);
                    return data.get(localTrx);
                };
            };
        };

        public func selectOne(equal : T -> Bool) : ?T {
            for ((rowId, data) in dataRows.entries()) {
                switch(data.getCommited()) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            return ?v;
                        };
                    };
                };
            };
            null
        };

        public func selectOneWithTrx(trxId: Nat, equal : T -> Bool) : ?T {
            let localTrx : LocalTrx = findLocalTrxId(trxId);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.get(localTrx)) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            return ?v;
                        };
                    };
                };
            };
            null
        };

        public func select(equal : T -> Bool) : [T] {
            var result : Buffer.Buffer<T> = Buffer.Buffer<T>(dataRows.size());
            for ((rowId, data) in dataRows.entries()) {
                switch(data.getCommited()) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            result.add(v);
                        };
                    };
                };
            };
            result.toArray()
        };

        public func selectWithTrx(trxId: Nat, equal : T -> Bool) : [T] {
            var result : Buffer.Buffer<T> = Buffer.Buffer<T>(dataRows.size());
            let localTrx : LocalTrx = findLocalTrxId(trxId);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.get(localTrx)) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            result.add(v);
                        };
                    };
                };
            };
            result.toArray()
        };

        public func selectByLimit(offset: Nat, limit: Nat, equal : T -> Bool) : [T] {
            var row : Nat = 0;
            let end : Nat = offset + limit - 1;
            var result : Buffer.Buffer<T> = Buffer.Buffer<T>(limit);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.getCommited()) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            if (row >= offset and row <= end) {
                                result.add(v);
                            };
                            row += 1;
                        };
                    };
                };
            };
            result.toArray()
        };

        public func selectByLimitWithTrx(trxId: Nat, offset: Nat, limit: Nat, equal : T -> Bool) : [T] {
            var row : Nat = 0;
            let end : Nat = offset + limit - 1;
            var result : Buffer.Buffer<T> = Buffer.Buffer<T>(limit);
            let localTrx : LocalTrx = findLocalTrxId(trxId);
            for ((rowId, data) in dataRows.entries()) {
                switch(data.get(localTrx)) {
                    case null {};
                    case (?v) {
                        if (equal(v)) {
                            if (row >= offset and row <= end) {
                                result.add(v);
                            };
                            row += 1;
                        };
                    };
                };
            };
            result.toArray()
        };

        public func tryCommit(trxId : Nat) : () {
            let localTrx : LocalTrx = getLocalTrxId(trxId);
            switch(redoLog.get(localTrx.trxId)) {
                case null {};
                case (?log) {
                    for((rowId, redo) in log.entries()) {
                        tryCommitByRowId(rowId, localTrx.trxId, redo.doType);
                    };
                };
            };
        };

        public func commit(trxId : Nat) : () {
            let localTrx : LocalTrx = getLocalTrxId(trxId);

            refreshTrxMapping(trxId);
            redoLog.delete(localTrx.trxId);
            undoLog.delete(localTrx.trxId);
        };

        public func rollback(trxId : Nat) : () {
            let localTrx : LocalTrx = getLocalTrxId(trxId);
            switch(undoLog.get(localTrx.trxId)) {
                case null {};
                case (?log) {
                    for ((rowId, undo) in log.entries()) {
                        rollbackByRowId(rowId, localTrx.trxId, undo.doType);
                    };
                };
            };

            refreshTrxMapping(trxId);
            redoLog.delete(localTrx.trxId);
            undoLog.delete(localTrx.trxId);
        };

        private func tryCommitByRowId(rowId : Nat, trxId : Nat, doType : DoType) : () {
            switch(dataRows.get(rowId)) {
                case null {};
                case (?data) {
                    data.commit(trxId);
                };
            };
        };

        private func rollbackByRowId(rowId : Nat, trxId : Nat, doType : DoType) : () {
            switch(dataRows.get(rowId)) {
                case null {};
                case (?data) {
                    data.rollback(trxId);
                    if (doType == #delete) {
                        if (data.isDeleted()) {
                            dataRows.delete(rowId);
                        };
                    };
                };
            };
        };

        private func addRedoLog(redo : TrxLog, trxId : Nat) : () {
            switch(redoLog.get(trxId)) {
                case null {
                    var log : HashMap.HashMap<Nat, TrxLog> = HashMap.HashMap<Nat, TrxLog>(12, Nat.equal, Hash.hash);
                    log.put(redo.rowId, redo);
                    redoLog.put(trxId, log);
                };
                case (?log) {
                    log.put(redo.rowId, redo);
                };
            };
        };

        private func addUndoLog(undo : TrxLog, trxId : Nat) : () {
            switch(undoLog.get(trxId)) {
                case null {
                    var log : HashMap.HashMap<Nat, TrxLog> = HashMap.HashMap<Nat, TrxLog>(12, Nat.equal, Hash.hash);
                    log.put(undo.rowId, undo);
                    undoLog.put(trxId, log);
                };
                case (?log) {
                    log.put(undo.rowId, undo);
                };
            };
        };

        private func getLocalTrxId(trxId : Nat) : LocalTrx {
            switch(trxMapping.get(trxId)) {
                case null {
                    let localTrxId : Nat = nextLoaclTrxId;
                    var minLocalTrxId : Nat = localTrxId;
                    var maxLocalTrxId : Nat = localTrxId;
                    var activeTrxIds : Buffer.Buffer<Nat> = Buffer.Buffer<Nat>(trxMapping.size());
                    for ((_trxId, _localTrx) in trxMapping.entries()) {
                        if (minLocalTrxId == localTrxId or minLocalTrxId > _localTrx.trxId) {
                            minLocalTrxId := _localTrx.trxId;
                        };
                        activeTrxIds.add(_localTrx.trxId);
                    };
                    let activeTrxSnapshot : ActiveTrxSnapshot = {
                        minTrxId = minLocalTrxId;
                        maxTrxId = maxLocalTrxId;
                        activeTrxIds = activeTrxIds.toArray();
                    };
                    let localTrx : LocalTrx = {
                        trxId = localTrxId;
                        trxSnapshot = activeTrxSnapshot;
                    };
                    trxMapping.put(trxId, localTrx);
                    nextLoaclTrxId += 1;
                    return localTrx;
                };
                case (?localTrx) {
                    return localTrx;
                };
            };
        };

        private func findLocalTrxId(trxId : Nat) : LocalTrx {
            switch(trxMapping.get(trxId)) {
                case null {
                    let activeTrxSnapshot : ActiveTrxSnapshot = {
                        minTrxId = nextLoaclTrxId;
                        maxTrxId = nextLoaclTrxId;
                        activeTrxIds = [];
                    };
                    let localTrx : LocalTrx = {
                        trxId = nextLoaclTrxId;
                        trxSnapshot = activeTrxSnapshot;
                    };
                    return localTrx;
                };
                case (?localTrx) {
                    return localTrx;
                };
            };
        };

        private func refreshTrxMapping(trxId : Nat) : () {
            switch(trxMapping.remove(trxId)) {
                case null {};
                case (?localTrx) {
                    if (localTrx.trxId == minLocalTrx.trxId or minLocalTrx.trxId == 0) {
                        updateMinLocalTrx();
                        removeCache();
                    };
                };
            };
        };

        private func updateMinLocalTrx() : () {
            if (trxMapping.size() > 0) {
                var _minLocalTrx : LocalTrx = {
                    trxId = nextLoaclTrxId;
                    trxSnapshot = {
                        minTrxId = nextLoaclTrxId;
                        maxTrxId = nextLoaclTrxId;
                        activeTrxIds = [];
                    };
                };
                for ((trxId, localTrx) in trxMapping.entries()) {
                    if (localTrx.trxId <= _minLocalTrx.trxId) {
                        _minLocalTrx := localTrx;
                    };
                };
                minLocalTrx := _minLocalTrx;
            } else {
                minLocalTrx := {
                    trxId = nextLoaclTrxId;
                    trxSnapshot = {
                        minTrxId = nextLoaclTrxId;
                        maxTrxId = nextLoaclTrxId;
                        activeTrxIds = [];
                    };
                };
            };
        };

        private func addCommittedRows(_rowIds : [Nat]) : () {
            var newCommittedRows : [Nat] = [];
            let newRowIds : List.List<Nat> = List.fromArray<Nat>(_rowIds);
            for (committedRowId in committedRows.vals()) {
                if (not List.some<Nat>(newRowIds, func (rowId : Nat) : Bool {
                    return committedRowId == rowId;
                })) {
                    newCommittedRows := Array.append<Nat>(newCommittedRows, [committedRowId]);
                };
            };
            committedRows := Array.append<Nat>(newCommittedRows, _rowIds);
        };

        private func removeCache() : () {
            for (committedRowId in committedRows.vals()) {
                switch(dataRows.get(committedRowId)) {
                    case null {};
                    case (?data) {
                        data.remove(minLocalTrx);
                        if (data.isNil()) {
                            dataRows.delete(committedRowId);
                        };
                    };
                };
            };
        };

        public func getAll() : [T] {
            select(func (v : T) : Bool {
                true
            })
        };

    };

    public func fromArray<T>(values : [T]) : DataSet<T> {
        var db : DataSet<T> = DataSet<T>();
        db.insertAll(values);
        db
    };

};