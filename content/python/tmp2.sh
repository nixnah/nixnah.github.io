#!/bin/bash
set -o errexit
copyright: "本文采用[「CC BY-NC-SA 4.0」](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh)协议，转载请注明出处。"
original: false
author: 骆昊
link: https://github.com/jackfrued/Python-100-Days
file=$(ls)
tags:
- python
for f in ${file};do
	fe=${f##*.}
	if [ ! "$fe" == 'sh' ];then
		sed -ri 's/res\//\/res\//g' $f
	fi
done
