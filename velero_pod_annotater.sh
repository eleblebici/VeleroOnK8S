#!/bin/bash
echo -n "On which namespace you will annotate pods? : "
read namespace
IFS= read -r -d '' -a pods < <( kubectl get pods -n $namespace | awk 'NR > 1 {print $1}' && printf '\0' )
declare -a podswhichhavePVC=()
for pod in $pods
do
	if [[ $(kubectl describe pod $pod -n $namespace) == *"PersistentVolumeClaim"* ]]
		then podswhichhavePVC+=($pod)
		continue
	fi
done
x=$(echo ${#podswhichhavePVC[@]})
for ((i=0;i<x;i++))
do
	IFS= read -r -d '' -a volumenamesforpod < <( kubectl describe pod ${podswhichhavePVC[$i]} -n $namespace | grep -B1 'PersistentVolumeClaim' |  grep -v 'PersistentVolumeClaim' | grep -v "\-\-" | sed 's/://' | sed -e 's/[ ]*//' )
	array=($volumenamesforpod)
	kubectl annotate pods ${podswhichhavePVC[$i]} -n $namespace backup.velero.io/backup-volumes="$(IFS=,; echo "${array[*]}")" --overwrite
#		echo pod ${podswhichhavePVC[i]} annotated with backup.velero.io/backup-volumes="${volumenamesforpod[a]}"
done

