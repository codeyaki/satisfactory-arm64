#!/bin/bash
set -e

# SteamCMD 경로 수정
STEAMCMD="/home/steam/steamcmd/steamcmd.sh"

exec FEXBash

# 서버 업데이트
$STEAMCMD +login anonymous \
  +force_install_dir /satisfactory/server \
  +app_update 1690800 -beta experimental validate \
  +quit

# 서버 데이터 디렉토리 생성
mkdir -/satisfactory/server-data/Config

# 서버 설정 파일 생성
if [ ! -f /satisfactory/server-data/Config/Game.ini ]; then
  cat <<EOT > /satisfactory/server-data/Config/Game.ini
[/Script/Engine.GameSession]
MaxPlayers=${MAXPLAYERS:-4}
ServerName=${SERVER_NAME:-ARM_Server}
EOT
fi

# FEX 환경 변수 설정
export FEX_ROOTFS=/home/steam/.fex-emu/RootFS/Ubuntu_22_04
export LD_LIBRARY_PATH=/satisfactory/server/linux64:/satisfactory/server

# 서버 실행
exec FEXInterpreter /satisfactory/server/FactoryServer.sh \
  -Port=7777 \
  -BeaconPort=8888 \
  -QueryPort=8888 \
  -unattended \
  -multihome=$(hostname -I | awk '{print $1}')

