#!/bin/bash
set -o errexit ;set -o pipefail

files=$(ls -r)
for f in $files;do
  fe=${f%.md}
  t=$(date +%T)
  if [  ! "$f" ==  "_index.md" -a  ! "$f" == "tmp.sh" ];then
        # sed -i '1i\---\ntitle: '${fe}'\ndate: 2021-08-23T'$t'+08:00\n---' "$f"
	sed -i '3i\copyright: "本文采用[「CC BY-NC-SA 4.0」](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh)协议，转载请注明出处。"' "$f"
  fi
done
