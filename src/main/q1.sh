#!/bin/bash
# Q1：定位 handover，读取隐藏编号和欢迎文本。输出 location.txt、robot-id.txt、welcome.txt。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"

cd "$input/handover"
pwd > "$output/location.txt"

cat "$input/handover/.robot-id" > "$output/robot-id.txt"

cat "$input/notes/welcome.txt" > "$output/welcome.txt"
