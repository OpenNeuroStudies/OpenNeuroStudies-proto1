#!/bin/bash

#
# The idea is to produce a groupped collection of study-level datasets
# across all OpenNeuroDatasets.  This dataset will be a combination of
# both original OpenNeuroDatasets (as cloned from https://datasets.datalad.org/?dir=/openneuro) and merged into main tree and then original OpenNeuroDerivatives
#
set -eu

if [ -n "$*" ]; then
	dss="$@"
else
	dss=( $(/bin/ls -1d ds0?????) )
fi

function fetch_cached() {
	url="$1"
	cpath=scratch/cache/
	mkdir -p "$cpath"
	cpath+=$(echo $url | tr '/' '_')
	if [ ! -e "$cpath" ] ; then
		curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "$url" >| "$cpath"
	fi
	cat "$cpath"
}

function get_default_branch() {
	fetch_cached  "https://api.github.com/repos/$1" | jq -r '.default_branch'
}

mkdir -p scratch
if ! grep -q -v scratch .gitignore; then
	touch .gitignore
	echo scratch >> .gitignore
	git add .gitignore
fi

# go through all of the datasets and produce their "study-level" datasets
echo -e "study_id\tName\tBIDSVersion\tLicense\tAuthors" >| studies.tsv
for ds in "${dss[@]}"; do
	echo "I: working on $ds"
	sds="study-$ds"
	mkdir -p "$sds"/{derivatives,sourcedata}
	# TODO: add `git describe --tags` output somehow or version from CHANGES?
	if ! fetch_cached "https://raw.githubusercontent.com/OpenNeuroDatasets/$ds/refs/heads/$(get_default_branch OpenNeuroDatasets/$ds)/dataset_description.json" | python -c 'import json, sys; j=json.load(sys.stdin);j["DatasetType"]="study"; print(json.dumps(j, indent=2))' > "$sds/dataset_description.json"; then
		echo " E: likely is not a BIDS dataset!"
		echo -e "$sds\tn/a\tn/a\tn/a\tn/a" >> studies.tsv  # TODO: expand
	else
		git add "$sds/dataset_description.json"
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
	fi
	git mv "$ds" "$sds/sourcedata/raw"
	# TODO: formalize!?
	echo -e "derivative_id\tName\tVersion" >| "$sds/derivatives.tsv"
	for der in "$ds"-*; do
		if [ "$der" = "$ds-*" ] ; then
			echo " I: found no derivatives for $ds"
			break
		fi
		ds_=${der%%-*}
		test "$ds_" = "$ds"
		deriv=${der#*-}
		ver=$(fetch_cached "https://raw.githubusercontent.com/OpenNeuroDerivatives/$der/refs/heads/$(get_default_branch OpenNeuroDerivatives/$der)/dataset_description.json" | jq -r .GeneratedBy[0].Version)
		name=$(fetch_cached "https://raw.githubusercontent.com/OpenNeuroDerivatives/$der/refs/heads/main/dataset_description.json" | jq -r .GeneratedBy[0].Name)
		git mv "$der" "$sds/derivatives/$deriv-$ver"
		echo -e "$deriv-$ver\t$name\t$ver" >> "$sds/derivatives.tsv"
	done
	git add "$sds/derivatives.tsv"
	# break
done
# TODO: enhance studies.tsv with information about derivatives -- either they are complete or not and either correspond to the same version of the dataset as what we have now etc. But may be that should be already part of the dashboarding
# TODO: move generation and update of the derivatives.tsv and studies.tsv into a reusable function
# which would also "bubble up" the status of processing
git add studies.tsv

# whatever is left must be our bug as not having original dataset!
if /bin/ls ds0* | head | grep .; then
	echo "ERROR: still have some datasets left"
	exit 1
fi
