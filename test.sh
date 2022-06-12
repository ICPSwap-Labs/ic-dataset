id=1
name="1"
updateName="2"
right1="(opt \"1\")"
right2="(opt \"2\")"
rightNull="(null)"
rightLock="(-1 : int)"
rightZero="(0 : int)"
rightCount0="(0 : nat)"
rightCount1="(1 : nat)"
trxId1=1
trxId2=2
trxId3=3
failedCases=()

# set -x
echo "start test case 1"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
get="dfx canister call test get1 $id"
result=`$get`
if [ "$result" == "$right1" ]; then
  echo "test case 1 is passed"
else
  echo "test case 1 is failed"
  failedCases[0]=1
fi
delete=`dfx canister call test delete1 $id`

# set -x
echo "start test case 2"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
update=`dfx canister call test update1 '('$id', "'$updateName'")'`
get="dfx canister call test get1 $id"
result=`$get`
if [ "$result" == "$right2" ]; then
  echo "test case 2 is passed"
else
  echo "test case 2 is failed"
  failedCases[1]=2
fi
delete=`dfx canister call test delete1 $id`

# set -x
echo "start test case 3"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
delete=`dfx canister call test delete1 $id`
get="dfx canister call test get1 $id"
result=`$get`
if [ "$result" == "$rightNull" ]; then
  echo "test case 3 is passed"
else
  echo "test case 3 is failed"
  failedCases[2]=3
fi

#set -x
echo "start test case 4"
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
result=`dfx canister call test get2 '('$trxId1', '$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 4 is passed"
else
  echo "test case 4 is failed"
  failedCases[4]=4
fi
commit=`dfx canister call test commitTrx $trxId1`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 5"
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$rightNull" ]; then
  echo "test case 5 is passed"
else
  echo "test case 5 is failed"
  failedCases[4]=5
fi
commit=`dfx canister call test commitTrx $trxId1`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 6"
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
commit=`dfx canister call test commitTrx $trxId1`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 6 is passed"
else
  echo "test case 6 is failed"
  failedCases[5]=6
fi
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 7"
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
rollback=`dfx canister call test rollbackTrx $trxId1`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$rightNull" ]; then
  echo "test case 7 is passed"
else
  echo "test case 7 is failed"
  failedCases[6]=7
fi

#set -x
echo "start test case 8"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
update=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
result=`dfx canister call test get2 '('$trxId1', '$id')'`
if [ "$result" == "$right2" ]; then
  echo "test case 8 is passed"
else
  echo "test case 8 is failed"
  failedCases[7]=8
fi
commit=`dfx canister call test commitTrx $trxId1`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 9"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
update=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 9 is passed"
else
  echo "test case 9 is failed"
  failedCases[8]=9
fi
commit=`dfx canister call test commitTrx $trxId1`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 10"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
update=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
commit=`dfx canister call test commitTrx $trxId1`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$right2" ]; then
  echo "test case 10 is passed"
else
  echo "test case 10 is failed"
  failedCases[9]=10
fi
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 11"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
update=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
rollback=`dfx canister call test rollbackTrx $trxId1`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 11 is passed"
else
  echo "test case 11 is failed"
  failedCases[10]=11
fi
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 12"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
delete=`dfx canister call test delete2 '('$trxId1', '$id')'`
result=`dfx canister call test get2 '('$trxId1', '$id')'`
if [ "$result" == "$rightNull" ]; then
  echo "test case 12 is passed"
else
  echo "test case 12 is failed"
  failedCases[11]=12
fi
commit=`dfx canister call test commitTrx $trxId1`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 13"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
delete=`dfx canister call test delete2 '('$trxId1', '$id')'`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 13 is passed"
else
  echo "test case 13 is failed"
  failedCases[12]=13
fi
commit=`dfx canister call test commitTrx $trxId1`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 14"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
delete=`dfx canister call test delete2 '('$trxId1', '$id')'`
commit=`dfx canister call test commitTrx $trxId1`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$rightNull" ]; then
  echo "test case 14 is passed"
else
  echo "test case 14 is failed"
  failedCases[13]=14
fi

#set -x
echo "start test case 15"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
delete=`dfx canister call test delete2 '('$trxId1', '$id')'`
rollback=`dfx canister call test rollbackTrx $trxId1`
result=`dfx canister call test get1 '('$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 15 is passed"
else
  echo "test case 15 is failed"
  failedCases[14]=15
fi
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 16"
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$rightNull" ]; then
  echo "test case 16 is passed"
else
  echo "test case 16 is failed"
  failedCases[15]=16
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 17"
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
commit1=`dfx canister call test commitTrx $trxId1`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$rightNull" ]; then
  echo "test case 17 is passed"
else
  echo "test case 17 is failed"
  failedCases[16]=17
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 18"
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
rollback1=`dfx canister call test rollbackTrx $trxId1`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$rightNull" ]; then
  echo "test case 18 is passed"
else
  echo "test case 18 is failed"
  failedCases[17]=18
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 19"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
update=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 19 is passed"
else
  echo "test case 19 is failed"
  failedCases[18]=19
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 20"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
update=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
commit1=`dfx canister call test commitTrx $trxId1`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 20 is passed"
else
  echo "test case 20 is failed"
  failedCases[19]=20
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 21"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
insert=`dfx canister call test insert2 '('$trxId1', '$id', "'$name'")'`
rollback1=`dfx canister call test rollbackTrx $trxId1`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 21 is passed"
else
  echo "test case 21 is failed"
  failedCases[20]=21
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 22"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
delete=`dfx canister call test delete2 '('$trxId1', '$id')'`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 22 is passed"
else
  echo "test case 22 is failed"
  failedCases[21]=22
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 23"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
delete=`dfx canister call test delete2 '('$trxId1', '$id')'`
commit1=`dfx canister call test commitTrx $trxId1`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 23 is passed"
else
  echo "test case 23 is failed"
  failedCases[22]=23
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 24"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
delete=`dfx canister call test delete2 '('$trxId1', '$id')'`
rollback1=`dfx canister call test rollbackTrx $trxId1`
result=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$result" == "$right1" ]; then
  echo "test case 24 is passed"
else
  echo "test case 24 is failed"
  failedCases[23]=24
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 25"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
startTrx1=`dfx canister call test startTrx $trxId1`
startTrx2=`dfx canister call test startTrx $trxId2`
update2=`dfx canister call test update2 '('$trxId2', '$id', "'$updateName'")'`
commit2=`dfx canister call test commitTrx $trxId2`
startTrx3=`dfx canister call test startTrx $trxId3`
result1=`dfx canister call test get2 '('$trxId1', '$id')'`
result3=`dfx canister call test get2 '('$trxId3', '$id')'`
if [ "$result1" == "$right1" -a "$result3" == "$right2" ]; then
  echo "test case 25 is passed"
else
  echo "test case 25 is failed"
  failedCases[24]=25
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit3=`dfx canister call test commitTrx $trxId3`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 26"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
rowId=`echo $insert | tr -cd "[0-9]"`
startTrx1=`dfx canister call test startTrx $trxId1`
update1=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
startTrx2=`dfx canister call test startTrx $trxId2`
result=`dfx canister call test updateByRowId2 '('$trxId2', '$rowId', '$id', "'$updateName'")'`
if [ "$result" == "$rightLock" ]; then
  echo "test case 26 is passed"
else
  echo "test case 26 is failed"
  failedCases[25]=26
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 27"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
rowId=`echo $insert | tr -cd "[0-9]"`
startTrx1=`dfx canister call test startTrx $trxId1`
update1=`dfx canister call test update2 '('$trxId1', '$id', "'$updateName'")'`
startTrx2=`dfx canister call test startTrx $trxId2`
result=`dfx canister call test deleteByRowId2 '('$trxId2', '$rowId')'`
if [ "$result" == "$rightLock" ]; then
  echo "test case 27 is passed"
else
  echo "test case 27 is failed"
  failedCases[26]=27
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 28"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
rowId=`echo $insert | tr -cd "[0-9]"`
startTrx1=`dfx canister call test startTrx $trxId1`
delete1=`dfx canister call test delete2 '('$trxId1', '$id')'`
startTrx2=`dfx canister call test startTrx $trxId2`
result=`dfx canister call test updateByRowId2 '('$trxId2', '$rowId', '$id', "'$updateName'")'`
if [ "$result" == "$rightLock" ]; then
  echo "test case 28 is passed"
else
  echo "test case 28 is failed"
  failedCases[27]=28
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 29"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
rowId=`echo $insert | tr -cd "[0-9]"`
startTrx1=`dfx canister call test startTrx $trxId1`
delete1=`dfx canister call test delete2 '('$trxId1', '$id')'`
startTrx2=`dfx canister call test startTrx $trxId2`
result=`dfx canister call test deleteByRowId2 '('$trxId2', '$rowId')'`
if [ "$result" == "$rightLock" ]; then
  echo "test case 29 is passed"
else
  echo "test case 29 is failed"
  failedCases[28]=29
fi
commit1=`dfx canister call test commitTrx $trxId1`
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 30"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
rowId=`echo $insert | tr -cd "[0-9]"`
startTrx1=`dfx canister call test startTrx $trxId1`
delete1=`dfx canister call test delete2 '('$trxId1', '$id')'`
startTrx2=`dfx canister call test startTrx $trxId2`
commit1=`dfx canister call test commitTrx $trxId1`
updateResult=`dfx canister call test update2 '('$trxId2', '$id', "'$updateName'")'`
getResult=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$updateResult" == "$rightZero" -a "$getResult" == "$right1" ]; then
  echo "test case 30 is passed"
else
  echo "test case 30 is failed"
  failedCases[29]=30
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 31"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
rowId=`echo $insert | tr -cd "[0-9]"`
startTrx1=`dfx canister call test startTrx $trxId1`
delete1=`dfx canister call test delete2 '('$trxId1', '$id')'`
startTrx2=`dfx canister call test startTrx $trxId2`
commit1=`dfx canister call test commitTrx $trxId1`
deleteResult=`dfx canister call test delete2 '('$trxId2', '$id')'`
getResult=`dfx canister call test get2 '('$trxId2', '$id')'`
if [ "$deleteResult" == "$rightZero" -a "$getResult" == "$right1" ]; then
  echo "test case 31 is passed"
else
  echo "test case 31 is failed"
  failedCases[30]=31
fi
commit2=`dfx canister call test commitTrx $trxId2`
delete=`dfx canister call test delete1 $id`

#set -x
echo "start test case 32"
insert=`dfx canister call test insert1 '('$id', "'$name'")'`
rowId=`echo $insert | tr -cd "[0-9]"`
startTrx1=`dfx canister call test startTrx $trxId1`
delete1=`dfx canister call test delete2 '('$trxId1', '$id')'`
startTrx2=`dfx canister call test startTrx $trxId2`
commit1=`dfx canister call test commitTrx $trxId1`
countResult1=`dfx canister call test count2 $trxId2`
commit2=`dfx canister call test commitTrx $trxId2`
countResult2=`dfx canister call test count2 $trxId2`
if [ "$countResult1" == "$rightCount1" -a "$countResult2" == "$rightCount0" ]; then
  echo "test case 32 is passed"
else
  echo "test case 32 is failed"
  failedCases[31]=32
fi
delete=`dfx canister call test delete1 $id`

# test result
if [ ${#failedCases[*]} == 0 ]; then
  echo "all test cases are passed"
else
  echo "the failed test case is " ${failedCases[*]}
fi