#!/bin/bash

# スクリーンショット自動移動スクリプト (Bash)

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DARK_CYAN='\033[2;36m'
DARK_GREEN='\033[2;32m'
DARK_YELLOW='\033[2;33m'
NC='\033[0m' # No Color

# 既存のinotifyプロセスを停止（テスト用）
pkill -f "inotifywait.*screenshot" 2>/dev/null

echo ""
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN} スクリーンショット自動移動スクリプト (Bash)${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${DARK_CYAN}Bash Version: $BASH_VERSION${NC}"
echo ""

# inotify-toolsがインストールされているかチェック
if ! command -v inotifywait &> /dev/null; then
    echo -e "${RED}エラー: inotify-toolsがインストールされていません。${NC}"
    echo "以下のコマンドでインストールしてください："
    echo "  Ubuntu/Debian: sudo apt install inotify-tools"
    echo "  CentOS/RHEL:   sudo yum install inotify-tools"
    echo "  macOS:         brew install fswatch"
    exit 1
fi

source_path=""
while true; do
    echo "スクリーンショットの保存元フォルダを選択してください："
    echo "  1. 現在のフォルダ ($(pwd))"
    echo "  2. 別のフォルダを指定"
    echo ""
    read -p "選択してください (1 または 2): " choice
    
    case $choice in
        1|"")
            source_path="$(pwd)"
            echo -e "${DARK_GREEN}現在のフォルダを使用します: $source_path${NC}"
            break
            ;;
        2)
            echo ""
            read -p "フォルダのパスを入力してください: " input_path
            if [ -d "$input_path" ]; then
                source_path="$input_path"
                echo -e "${DARK_GREEN}選択されたパス: $source_path${NC}"
                break
            else
                echo -e "${YELLOW}警告: 指定されたパスは存在しません。ディレクトリを作成しますか？ (y/n)${NC}"
                read -p "> " create_dir
                if [[ "$create_dir" =~ ^[Yy]$ ]]; then
                    mkdir -p "$input_path"
                    source_path="$input_path"
                    echo -e "${GREEN}ディレクトリを作成しました: $source_path${NC}"
                    break
                fi
            fi
            ;;
        *)
            echo -e "${RED}無効な選択です。1 または 2 を入力してください。${NC}"
            ;;
    esac
done

# 移動元フォルダの確認
echo ""
echo -e "${CYAN}=== 移動元フォルダの確認 ===${NC}"
echo -e "${DARK_CYAN}監視対象フォルダ: $source_path${NC}"
if [ ! -d "$source_path" ]; then
    echo -e "${RED}エラー: 移動元フォルダが存在しません: $source_path${NC}"
    exit 1
fi

# フォルダ内のファイル一覧表示
echo -e "${DARK_CYAN}現在のファイル一覧:${NC}"
ls -la "$source_path" | head -10
file_count=$(ls -1 "$source_path" | wc -l)
echo -e "${DARK_CYAN}ファイル数: $file_count${NC}"

# 画像ファイルの確認
image_count=$(find "$source_path" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | wc -l)
echo -e "${DARK_CYAN}画像ファイル数 (png/jpg/jpeg): $image_count${NC}"

if [ "$image_count" -gt 0 ]; then
    echo -e "${DARK_CYAN}既存の画像ファイル:${NC}"
    find "$source_path" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | head -5
fi

echo ""
destination_path="$(pwd)"
echo -e "${GREEN}現在の作業フォルダ: $destination_path${NC}"

while true; do
    read -p "このフォルダにスクリーンショットを移動しますか？ (y/n): " confirm
    case $confirm in
        [Yy]* ) break;;
        [Nn]* ) echo -e "${YELLOW}処理をキャンセルしました。${NC}"; exit;;
        * ) echo -e "${RED}無効な入力です。「y」または「n」を入力してください。${NC}";;
    esac
done

echo ""
echo -e "${DARK_YELLOW}----------------------------------------------------${NC}"
echo -e "${DARK_YELLOW} スクリーンショットの監視を開始します...${NC}"
echo -e "${DARK_YELLOW} 新しいスクリーンショットが作成されると即座に移動します。${NC}"
echo -e "${DARK_YELLOW} このウィンドウを閉じるか Ctrl+C を押すと停止します。${NC}"
echo -e "${DARK_YELLOW}----------------------------------------------------${NC}"
echo ""

# 履歴ファイル
history_file="/tmp/screenshot_move_history_$$"
echo "ファイル名,タイムスタンプ,ステータス,詳細" > "$history_file"

# 現在の時刻を取得する関数
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 履歴に追加する関数
add_to_history() {
    local filename="$1"
    local status="$2"
    local message="$3"
    local timestamp="$(get_timestamp)"
    
    echo "$filename,$timestamp,$status,$message" >> "$history_file"
    
    # 最新10件を表示
    echo ""
    echo -e "${CYAN}=== スクリーンショット移動履歴 (最新10件) ===${NC}"
    echo -e "${CYAN}ファイル名${NC} | ${CYAN}タイムスタンプ${NC} | ${CYAN}ステータス${NC} | ${CYAN}詳細${NC}"
    echo "------------------------------------------------------------"
    
    tail -n 10 "$history_file" | tail -n +2 | while IFS=',' read -r file ts stat detail; do
        case "$stat" in
            "成功") color="${GREEN}";;
            "エラー") color="${RED}";;
            "警告") color="${YELLOW}";;
            "スキップ") color="${DARK_CYAN}";;
            *) color="${NC}";;
        esac
        printf "${color}%-20s${NC} | %-19s | ${color}%-8s${NC} | %s\n" "$file" "$ts" "$stat" "$detail"
    done
    echo ""
}

# ファイル処理関数
process_file() {
    local filepath="$1"
    local filename="$(basename "$filepath")"
    local status=""
    local message=""
    
    echo -e "${BLUE}[DEBUG] ファイル検出: $filepath${NC}"
    echo -e "${BLUE}[DEBUG] ファイル名: $filename${NC}"
    
    # スクリーンショットファイルかチェック（Linux/macOSの一般的な命名規則）
    if [[ "$filename" =~ ^(Screenshot|スクリーンショット|Screen Shot).+\.(png|jpg|jpeg)$ ]] || \
       [[ "$filename" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}.+\.(png|jpg|jpeg)$ ]] || \
       [[ "$filename" =~ ^screenshot.+\.(png|jpg|jpeg)$ ]] || \
       [[ "$filename" =~ \.(png|jpg|jpeg)$ ]]; then
        
        echo -e "${BLUE}[DEBUG] スクリーンショットファイルとして認識${NC}"
        
        # 少し待ってからファイルの存在確認
        sleep 0.5
        
        if [ -f "$filepath" ]; then
            echo -e "${BLUE}[DEBUG] ファイル存在確認: OK${NC}"
            local destination_filepath="$destination_path/$filename"
            
            if [ ! -f "$destination_filepath" ]; then
                echo -e "${BLUE}[DEBUG] 移動を実行: $filepath -> $destination_path/${NC}"
                if mv "$filepath" "$destination_path/" 2>/dev/null; then
                    # 移動後の存在確認
                    if [ -f "$destination_filepath" ]; then
                        status="成功"
                        message="OK（移動後に存在確認済）"
                        echo -e "${GREEN}[SUCCESS] ファイル移動完了: $filename${NC}"
                    else
                        status="エラー"
                        message="移動後にファイルが見つかりません"
                        echo -e "${RED}[ERROR] 移動後にファイルが見つかりません${NC}"
                    fi
                else
                    status="エラー"
                    message="ファイル移動に失敗しました"
                    echo -e "${RED}[ERROR] ファイル移動に失敗: $filepath${NC}"
                fi
            else
                status="スキップ"
                message="移動先に既に存在"
                echo -e "${YELLOW}[SKIP] 移動先に既に存在: $filename${NC}"
            fi
        else
            status="警告"
            message="移動前にファイルが消失"
            echo -e "${YELLOW}[WARNING] 移動前にファイルが消失: $filepath${NC}"
        fi
    else
        status="スキップ"
        message="スクリーンショット以外"
        echo -e "${DARK_CYAN}[SKIP] スクリーンショット以外: $filename${NC}"
    fi
    
    add_to_history "$filename" "$status" "$message"
}

# 終了処理
cleanup() {
    echo ""
    echo -e "${YELLOW}監視を停止しています...${NC}"
    # バックグラウンドプロセスを終了
    jobs -p | xargs -r kill 2>/dev/null
    # 履歴ファイルを削除
    rm -f "$history_file"
    echo -e "${GREEN}スクリーンショット監視を終了しました。${NC}"
    exit 0
}

# シグナルハンドラを設定
trap cleanup SIGINT SIGTERM

echo -e "${DARK_CYAN}$(get_timestamp) - inotifywaitが設定されました。${NC}"
echo -e "${DARK_CYAN}$(get_timestamp) - 監視パス: $source_path${NC}"
echo -e "${DARK_CYAN}$(get_timestamp) - フィルタ: *.png, *.jpg, *.jpeg${NC}"
echo -e "${DARK_CYAN}$(get_timestamp) - 監視を開始します。${NC}"
echo ""

# macOSの場合はfswatch、Linuxの場合はinotifywaitを使用
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS用（fswatch）
    if command -v fswatch &> /dev/null; then
        fswatch -0 "$source_path" | while read -d "" filepath; do
            if [[ "$filepath" =~ \.(png|jpg|jpeg)$ ]]; then
                process_file "$filepath"
            fi
        done
    else
        echo -e "${RED}エラー: fswatch がインストールされていません。${NC}"
        echo "以下のコマンドでインストールしてください："
        echo "  brew install fswatch"
        exit 1
    fi
else
    # Linux用（inotifywait）
    inotifywait -m -e create,moved_to --format '%w%f' "$source_path" | while read filepath; do
        if [[ "$filepath" =~ \.(png|jpg|jpeg)$ ]]; then
            process_file "$filepath"
        fi
    done
fi