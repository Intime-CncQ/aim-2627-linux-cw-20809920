#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"

# 读取环境变量文件
source "$input/launch.env"

# 运行检查工具，并分离标准输出和标准错误
if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" > "$output/stdout.log" 2> "$output/stderr.log"; then
    rc=0
else
    rc=$?
fi

# 保存真实退出码
echo "$rc" > "$output/exit-code.txt"

# 根据退出码判断状态并生成报告
if [ "$rc" -eq 0 ]; then
    result="SUCCESS"
    reason="NONE"
elif [ "$rc" -eq 10 ]; then
    result="FAILED"
    reason="MODEL_MISSING"
elif [ "$rc" -eq 20 ]; then
    result="FAILED"
    reason="CAMERA_DENIED"
else
    result="FAILED"
    reason="NONE"
fi

# 写入 report.txt
cat > "$output/report.txt" <<EOF
result=$result
exit_code=$rc
reason=$reason
EOF
