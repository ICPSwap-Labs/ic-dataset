# ic-dataset

A data storage collection including transaction management, developed and designed based on the Motoko language. It supports custom data types. By using TransactionManager, it can realize distributed transaction management across canisters and data collections in TCC mode. While ensuring ACID, it provides a SQL-like interface, which can easily and quickly select, insert, update and delete data.

## ACID

1. Atomicity. The smallest working unit of a transaction that either all succeeds or all fails.

2. Consistency. The integrity of a data set is not broken at the beginning and end of a transaction.

3. Isolation. Different transactions do not affect each other.

4. Persistence. After the transaction commits, changes to the data are permanent and are not lost.

## TCC

1. Try to commit. Preparing to commit a transaction.

2. Commit. If the operation is correct, the transaction will be committed.

3. Rollback. If the commit fails or an exception is thrown, the transaction is rolled back.

## Transaction Isolation Level

### Repeatable Read/RR

A transaction's read can read data committed by other transactions, but at the RR isolation level, the current read of this data can only be read once. The same value obtained on the first read is returned in the current transaction, no matter how many times it is read. The value read is not changed by other transactions modifying and committing this data after the first read.

## MVCC

MVCC: Multi-Version Concurrency Control.  

Use versioning to control data problems in concurrent situations. When transaction B starts to modify the accounts and the transaction is not committed, when transaction A needs to read the data, it will read the copy data before transaction B's modification operation, but if A must wait for transaction B to commit the transaction if the transaction needs to modify the data.

MVCC makes it possible to read data without locking the database and ordinary query requests without locking, which improves the concurrent processing capability of the database. With MVCC, users can view previous or previous historical versions of the current data, ensuring the I feature (isolation) in ACID.

## Transaction Snapshot

A transaction snapshot is obtained after each transaction starts. The transaction snapshot holds the ID numbers of the transactions that are active (uncommitted) in the current dataset.

## Interface

### Init
___
```rust
var ds : DataSet.DataSet<T> = DataSet.DataSet<T>();
```
Initialize a new data collection.

___
```rust
var ds : DataSet.DataSet<T> = DataSet.fromArray<T>([]);
```
Initialize a new data collection based on the array data.

### Insert
___
```rust
func insert(value : T) : Nat
```
Add a new data to the data collection, and return the data row ID of the data.

___
```rust
func insertWithTrx(trxId : Nat, value : T) : Nat
```
In a transaction, add a new data to the data collection, and return the data row ID of the data.

___
```rust
func insertAll(values : [T]) : ()
```
Add a batch of data to the data collection in batches.

### Update
___
```rust
func updateByRowId(rowId : Nat, value : T) : Int
```
According to the data row ID, update the data and return the number of rows affected.

___
```rust
func updateByRowIdWithTrxId(trxId : Nat, rowId : Nat, value : T) : Int
```
In a transaction, according to the data row ID, update the data and return the number of rows affected.

___
```rust
func update(value : T, equal : T -> Bool) : Int
```
According to the conditions of the equal function, update the data and return the number of rows affected.

___
```rust
func updateWithTrx(trxId : Nat, value : T, equal : T -> Bool) : Int
```
In a transaction, according to the conditions of the equal function, update the data and return the number of rows affected.

### Delete
___
```rust
func deleteByRowId(rowId : Nat) : Int
```
Delete data according to the data row ID, and return the number of rows affected.

___
```rust
func deleteByRowIdWithTrx(trxId : Nat, rowId : Nat) : Int
```
In a transaction, delete data according to the data row ID, and return the number of rows affected.

___
```rust
func delete(equal : T -> Bool) : Int
```
According to the conditions of the equal function, delete data and return the number of rows affected.

___
```rust
func deleteWithTrx(trxId : Nat, equal : T -> Bool) : Int
```
In a transaction, according to the conditions of the equal function, delete data and return the number of rows affected.

### Select
___
```rust
func countAll() : Nat
```
Query the total number of data items in the current dataset.

___
```rust
func countAllWithTrx(trxId : Nat) : Nat
```
In a transaction, query the total number of data items in the current dataset.

___
```rust
func count(equal : T -> Bool) : Nat
```
According to the conditions of the equal function, query the number of eligible data items in the current dataset.

___
```rust
func countWithTrx(trxId : Nat, equal : T -> Bool) : Nat
```
In a transaction, according to the conditions of the equal function, query the number of eligible data items in the current dataset.

___
```rust
func selectByRowId(rowId : Nat) : ?T
```
According to the data row ID, query the data, if it exists, return the data.

___
```rust
func selectByRowIdWithTrx(trxId: Nat, rowId : Nat) : ?T
```
In a transaction, according to the data row ID, query the data, if it exists, return the data.

___
```rust
func selectOne(equal : T -> Bool) : ?T
```
According to the condition of the equal function, query data, if it exists, return the first data that matched the conditions.

___
```rust
func selectOneWithTrx(trxId: Nat, equal : T -> Bool) : ?T
```
In a transaction, according to the condition of the equal function, query data, if it exists, return the first data that matched the condition.

___
```rust
func select(equal : T -> Bool) : [T]
```
According to the condition of the equal function, query data and return an array of data that matched the condition.

___
```rust
func selectWithTrx(trxId: Nat, equal : T -> Bool) : [T]
```
In a transaction, according to the condition of the equal function, query data and return an array of data that matched the condition.

___
```rust
func selectByLimit(offset: Nat, limit: Nat, equal : T -> Bool) : [T]
```
According to the condition of the equal function, query the data that matched the condition, and return the array at the position.

___
```rust
func selectByLimitWithTrx(trxId: Nat, offset: Nat, limit: Nat, equal : T -> Bool) : [T]
```
In a transaction, according to the condition of the equal function, query the data that matched the condition, and return the array at the position.

### Commit
___
```rust
func tryCommit(trxId : Nat) : ()
```
Attempt to commit the transaction. The data within the transaction will be committed and updated, but the transaction snapshot still exists.

___
```rust
func commit(trxId : Nat) : ()
```
Commit the transaction, and delete the transaction snapshot and transaction log.

### Rollback
___
```rust
func rollback(trxId : Nat) : ()
```
Rollback the transaction, the data in the transaction will not be committed and updated. Also, transaction snapshot and transaction log will be deleted.

## TransactionManager

### Access TransactionManager
___
```rust
type TrxCanister = actor {
    tryCommit : shared (trxId : Nat) -> async ();
    commit : shared (trxId : Nat) -> async ();
    rollback : shared (trxId : Nat) -> async ();
};
```
The canister which access the TransactionManager, need to implement the interface above.

### Begin Global Transaction
___
```rust
func begin(trxCanisterIds : [Text]) : async Nat
```
Begin a global transaction and register the canisters involved in the global transaction in the TransactionManager.

### Commit Global Transaction
___
```rust
func commit(trxId : Nat) : async Bool
```
Commit the global transaction, if tryCommit is successful, commit all transactions, otherwise rollback all transactions. Returns the commit result of the global transaction.

### Rollback Global Transaction
___
```rust
func rollback(trxId : Nat) : async Bool
```
Rollback the global transaction, rollback the transactions of all registered canisters.

## Feature

- [x] Data Storage: Support CRUD operations.(v0.1.0)
- [x] Transaction Management: Support transaction commit and rollback.(v0.1.0)
- [x] Transaction Isolation Level: The default is Repeatable Read.(v0.1.0)
- [x] Transaction Concurrency Control: Implemented by MVCC and Transaction-Snapshot, while avoiding phantom reading.(v0.1.0)
- [x] Data Row Lock: When data is updated in a transaction, the row of data will be locked, and -1 will be returned when other transactions try to update.(v0.1.0)
- [ ] Multiple Transaction Isolation Level: Support to Read Committed.
- [ ] Primary Key: Configurable primary key, and provide primary key-related insert, update, delete and select interface.
- [ ] Lock Waiting Mechanism: Can choose to wait for lock release or return immediately.
