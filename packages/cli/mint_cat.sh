#!/bin/bash

TOKEN_ID="45ee725c2c5993b3e4d308842d87e973bf1951f5f7a804b21e4dd964ecd12d6b_0"
TOKEN_AMOUNT=5

# 如果没有提供外部参数，使用默认阈值 1000
THRESHOLD=${1:-1000}

# 定义颜色
RED='\033[0;91m'    # 亮红色
GREEN='\033[0;92m'  # 亮绿色
YELLOW='\033[0;93m' # 亮黄色
BLUE='\033[0;94m'   # 亮蓝色
GRAY='\033[0;90m'  # 亮灰色
NC='\033[0m'        # No Color, 用于重置颜色

# 输出日志信息
log() {
  local type=$1
  local msg=$2
  local color
  case "$type" in
    error) color=$RED ;;
    success) color=$GREEN ;;
    warning) color=$YELLOW ;;
    info) color=$BLUE ;;
    *) color=$GRAY ;;
  esac
  echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] $msg${NC}"
}

# 打印当前使用的阈值
log "info" "Gas threshold: $THRESHOLD"

COUNT=0

# 循环执行命令
while true; do
  # 调用 API 获取当前 gas 值
  RESPONSE=$(curl -s --max-time 3 https://mempool.fractalbitcoin.io/api/v1/fees/recommended)
  if [ $? -ne 0 ]; then
    log "error" "Failed to fetch current gas (1). Retrying..."
    sleep 2
    continue
  fi

  # 解析 gas 值
  GAS=$(echo "$RESPONSE" | jq -r '.fastestFee' 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$GAS" ]; then
    log "error" "Failed to fetch current gas (2). Retrying..."
    sleep 2
    continue
  fi

  # 判断 gas 是否大于阈值
  if (( GAS > THRESHOLD )); then
    log "warning" "Gas fee is too high ($GAS sats/vB); waiting 5 seconds..."
    sleep 5
  else
    COUNT=$((COUNT + 1))
    log "success" "($COUNT) Minting CAT with fee rate $GAS sats/vB..."
    COMMAND="yarn cli mint -i $TOKEN_ID $TOKEN_AMOUNT --fee-rate $GAS"

    # 执行命令
    OUTPUT=$(eval "$COMMAND" 2>&1 | sed '1d')
    if [ $? -ne 0 ]; then
      log "error" "Minting failed."
    else
      log "" "$OUTPUT\n"
    fi
    sleep 2
  fi
done