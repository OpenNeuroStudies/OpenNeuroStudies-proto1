#!/bin/bash

#
# The idea is to produce a groupped collection of study-level datasets
# across all OpenNeuroDatasets.  This dataset will be a combination of
# both original OpenNeuroDatasets (as cloned from https://datasets.datalad.org/?dir=/openneuro) and merged into main tree and then original OpenNeuroDerivatives
#
set -eu

function fetch_cached() {
	url="$1"
	cpath=scratch/cache/
	mkdir -p "$cpath"
	cpath+="$url"
	if [ ! -e "$cpath" ] ; then
		wget -O "$cpath" "$url"
	fi
	cat "$cpath"
}

mkdir -p scratch
if ! grep -v scratch .gitignore; then
	touch .gitignore
	echo scratch >> .gitignore
	git add .gitignore
fi

# go through all of the datasets and produce their "study-level" datasets
echo -e "study_id\tName\tBIDSVersion\tLicense\tAuthors" >| studies.tsv
for ds in ds0?????; do
	sds="study-$ds"
	mkdir -p "$sds/{derivatives,sourcedata}"
	# TODO: add `git describe --tags` output somehow or version from CHANGES?
	fetch_cached "https://raw.githubusercontent.com/OpenNeuroDatasets/$ds/refs/heads/main/dataset_description.json" | python -c 'import json, sys; j=json.load(sys.stdin);j["DatasetType"]="study"; print(json.dumps(j, indent=2))' > "$sds/dataset_description.json"
	cat "$sds/dataset_description.json" | python -c "
import json, sys
data = json.load(sys.stdin)
row = ['$sds',
	   data.get('Name', ''),
	   data.get('BIDSVersion', ''),
	   data.get('License', ''),
	   repr(data.get('Authors', ''))]
print('\t'.join(row))
" >> studies.tsv

	git mv "$ds" "$sds/sourcedata/raw"
	# TODO: formalize!?
	echo "derivative_id\tName\tVersion" >| "$sds/derivatives.tsv"
	for der in "$ds-"; do
		ds_=${der##-*}
		test "$ds_" -eq "$ds"
		deriv=${der%*-}
		ver=$(fetch_cached "https://raw.githubusercontent.com/OpenNeuroDerivatives/$der/refs/heads/main/dataset_description.json" | jq -r .GeneratedBy[0].Version)
		name=$(fetch_cached "https://raw.githubusercontent.com/OpenNeuroDerivatives/$der/refs/heads/main/dataset_description.json" | jq -r .GeneratedBy[0].Name)
		git mv "$der" "$sds/derivatives/$deriv-$ver"
		echo "$deriv-$ver\t$name\t$ver" >> "$sds/derivatives.tsv"
	done
	git add "$sds/derivatives.tsv"
	break
done
git add studies.tsv

# whatever is left must be our bug as not having original dataset!
if /bin/ls ds0* | grep .; then
	echo "ERROR: still have some datasets left"
	exit 1
fi
