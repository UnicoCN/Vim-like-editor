#!/bin/bash

# 检查参数数量
if [ $# -ne 1 ]; then
    echo "Please input a filename as parameter"
    exit 1
fi

# 帮助界面
if [ $1 = "--help" ]
then
    echo "Usage: bash MyVim.sh [filename]"
    cat help
    echo ""
    exit 0
fi


# 获取文件名
filename=$1
backup=$1.backup

# 检查备份文件是否存在，若存在则将其删除;若不存在则创建一个
if [ -e $backup ]; then
    rm $backup
else
    touch $backup
fi

# 记录当前所编辑行的内容
cur_line="" 

# 检查当前我们所需要编辑的文件是否存在，若存在，则将其内容复制到备份文件中；若不存在，则新创建一个文件
if [ -e $filename ]; then
    # 将源文件内容拷贝到备份文件中
    # 之后的操作均在备份文件中进行
    cat $filename > $backup
    # 刚打开文件时，默认编辑第一行
    # 因此将第一行内容赋值给cur_line
    # 使用sed命令截取备份文件的第一行
    cur_line=$(cat $backup | sed -n '1p')
else
    # 若编辑文件不存在，则创建编辑文件
    touch $filename 
fi
# 如果备份文件为空，则我们向其中写入一个空字符串
# 这样是为了用程序打开新文件时有内容，否侧cur_line为空，会出现问题
if [[ !($cur_line) ]]; then
    echo "" > $backup
    cur_line=$(cat $backup | sed -n '1p')
fi

# 显示当前文件内容
ShowContent() {
    # 当前输出的行数
    cur_row=0
    cur_content=""
    # 在Linux中，默认分割符为空格、换行符以及回车，在读取文件内容时，内容中的空格以及回车会被省略
    # 因此我们需要将IFS，即默认分隔符变为空，这样才能正常echo出空格以及回车
    IFS=""

    while read -r cur_content; do
        echo -n $((cur_row+1))" "
        # 光标不在当前行，直接输出即可
        if [ $cur_row -ne $cursor_row ]; then
            echo "$cur_content"
        else
            # 如果光标不在当前行的末尾
            if [ $cursor_col -ne ${#cur_content} ]; then
                # 先输出光标前的内容
                echo -n "${cur_content:0:$cursor_col}"
                # 修改光标位置的颜色，将其高亮
                echo -ne "\e[100m${cur_content:$cursor_col:1}"
                # 光标之后的位置
                after_cursor=$cursor_col+1
                # 输出光标后的内容
                echo -e "\e[0m${cur_content:$after_cursor}"
            else
                # 如果光标在行末，我们可以多加一个空格显示光标位置
                echo -n "$cur_content"
                echo -e "\e[100m \e[0m"
            fi
        fi
            # 行数增加
            ((++cur_row))
    # while循环每次读入backup文件的一行内容
    done < "$backup"
    # 打印底部信息
    ShowBottom "$1"
}

# 处理上移和下移时光标位置的特殊情况
Cursor_Pos_Change() {
    # 将光标临近行的内容赋值给near_line 
    near_line=$1
    # 获取near_line的长度
    near_line_len=${#near_line}
    # 如果光标的列坐标大于临近行的长度，则光标的列坐标改为临近行的行末
    if [ $cursor_col -gt $near_line_len ]; then
        cursor_col=${#near_line}
    fi
}

# 光标左移
Cursor_left() {
    # 如果光标不在行首，则可以左移；反之不左移
    if [ $cursor_col -gt 0 ]; then
        # 光标位置左移
        cursor_col=$((cursor_col-1))
    fi
}
# 光标右移
Cursor_right() {
    # 处理光标右移，当移动到当前行末时，无法继续移动
    if [ $cursor_col -lt ${#cur_line} ]; then
        # 光标位置右移
        cursor_col=$((cursor_col+1))
    fi
}

# 光标上移
Cursor_up() {
    # 如果光标不在第一行，则可以上移
    if [ $cursor_row -gt 0 ]; then
        # 获取上一行的内容
        up_line=$(cat $backup | sed -n $((cursor_row))'p')
        # 光标行数减一
        cursor_row=$((cursor_row-1))
        # 处理光标上移
        Cursor_Pos_Change $up_line
    fi
}
# 光标下移
Cursor_down() {
    # 获取文件总行数
    total_line=$(cat $backup | wc -l)
    # 如果光标不在最后一行，则可以下移
    if [ $cursor_row -lt $((total_line-1)) ]; then
        # 获取下一行的内容
        down_line=$(cat $backup | sed -n $((cursor_row+2))'p')
        # 光标行数加一
        cursor_row=$((cursor_row+1))
        # 处理光标下移
        Cursor_Pos_Change $down_line
    fi
}
# 处理换行
Do_Enter() {
    # 当前行和下一行的行号
    preline_row=$((cursor_row+1))
    afterline_row=$((cursor_row+2))
    # 获取当前行和下一行的内容
    preline=${cur_line:0:$cursor_col}
    afterline=${cur_line:$cursor_col}$'\n'
    # 获取文件总行数
    total_line=$(cat $backup | wc -l)
    # 将更改写入备份文件
    sed -i ${preline_row}'s/.*/'"${preline}"'/' ${backup}
    # 若当前行不是最后一行，则在下一行前插入新行
    if [ $preline_row -lt $total_line ]; then
        sed -i ${afterline_row}'i '"${afterline}" ${backup}
    else
        # 在文件末尾多加一行
        sed -i '$a '"${afterline}" ${backup}
    fi
    # 光标移动到下一行的第一个字符
    cursor_row=$((cursor_row+1))
    cursor_col=0
}
# 处理当前行的删除
Do_Delete() {
    # 获取下一行行号
    next_row=$cursor_row
    # 获取文件总行数
    total_line=$(cat $backup | wc -l)
    # 若当前行为最后一行，则总行数减一
    if [ $((cursor_row+1)) -eq $total_line ]; then
        next_row=$((cursor_row-1))
    fi
    # 删除当前行
    sed -i $((cursor_row+1))'d' ${backup}
    # 重置光标位置到下一行行首
    cursor_row=$next_row
    cursor_col=0
}
# 打印底部信息
ShowBottom() {
    # 获取终端大小
    terminal_row=$(tput lines)
    terminal_col=$(tput cols)
    # 保存当前终端光标位置
    tput sc 

    # 打印底部信息
    # 光标移动到最后一行第一个位置
    tput cup $terminal_row 0
    # 输出底部信息
    echo -n "$1"

    # 打印当前光标位置信息
    tput cup $terminal_row $((terminal_col-10))
    # 输出光标位置，注意cursor_row和cursor_col是从0开始的，因此需要加一
    echo -n "$((cursor_row+1)),$((cursor_col+1))"
    # 恢复终端光标位置
    tput rc
}
# 显示当前行数和字符数
ShowNumbers() {
    # 获取文件行数和字符数
    total_line=$(cat $backup | wc -l)
    total_char=$(cat $backup | wc -m)
    # 将信息拼接到储存底部信息的字符串中
    bottom_msg="-- NORMAL --  "" \"${filename}\" ${total_line}L, ${total_char}C"
}

# 光标位置初始化
cursor_col=0
cursor_row=0

# 取消终端光标的显示
tput civis 
# 显示当前行数和字符数
ShowNumbers
# 清屏
clear
# 显示底部信息
ShowContent "$bottom_msg"

# 共有两个模式，第一个是普通模式(mode=0)，第二个是编辑模式(mode=1)
# 初始模式为普通模式
mode=0 

# 循环读入字符
# -s 不将用户的输入反映到终端输出
# -N1 每次仅读入1个字符
while read -s -N1 key; do  
    # 处理上下左右按键
    # Linux中的方向键包含多个字符，而使用`read -s -N1`一次只能读入一个字符；
    # 因此可以在非常短的时间内读入多个字符，再把它们拼接起来
    # 最后就可以得到我们需要的完整的方向键对应的字符了
    read -s -N1 -t 0.0001 k1
    read -s -N1 -t 0.0001 k2
    key=${key}${k1}${k2}
    # 临时变量，用于储存临时字符串
    tmp_line=""
    # 获得目前处理的行内容
    cur_line=$(cat $backup | sed -n $((cursor_row+1))'p')
    # 如果当前是正常模式
    if [ $mode -eq 0 ]; then
        # 获得bottom_msg
        ShowNumbers
        case $key in
            # 光标上移
            h|$'\e[A')  Cursor_up
                        ;;
            # 光标下移
            l|$'\e[B')  Cursor_down   
                        ;;
            # 光标左移
            j|$'\e[D')  Cursor_left   
                        ;;
            # 光标右移
            k|$'\e[C')  Cursor_right  
                        ;;
            # 切换到Insert
            i)  mode=1  
                bottom_msg="-- INSERT --"
                ;;
            # 保存文件
            w)  cp ${backup} ${filename}   
                bottom_msg=$button_msg" File Saved"
                ;;
            # 退出
            q)  break        
                ;;
            # 删除当前行
            d)  Do_Delete    
                ;;
            # 光标移到第一行行首
            g)  cursor_row=0
                cursor_col=0  
                ;;
            # 光标移动到最后一行
            G)  total_line=$(cat $backup | wc -l)
                cursor_row=$((total_line-1))
                cursor_col=0    
                ;;
            # 无效字符
            *)  bottom_msg="Command is not supported"
                ;; 
        esac
    else # 编辑模式
        case $key in
            # ESC，退出编辑模式
            $'\x1b')    mode=0  
                        ShowNumbers
                        ;;
            # 上方向键，光标上移             
            $'\e[A')    Cursor_up    
                        bottom_msg="-- INSERT --"   
                        ;;
            # 下方向键，光标下移
            $'\e[B')    Cursor_down
                        bottom_msg="-- INSERT --"
                        ;;
            # 左方向键，光标左移
            $'\e[D')    Cursor_left
                        bottom_msg="-- INSERT --"
                        ;;
            # 右方向键，光标右移
            $'\e[C')    Cursor_right
                        bottom_msg="-- INSERT --"
                        ;;
            # backspace键，删除光标位置的字符，并且光标进行左移
            $'\x7f')
                # 如果光标列坐标大于0，即光标前仍有字符，则可以进行回退
                if [ $cursor_col -gt 0 ]; then
                    tmp_line=${cur_line:0:$cursor_col-1}${cur_line:$cursor_col}
                    sed -i $((cursor_row+1))'s/.*/'"${tmp_line}"'/' ${backup}
                    cursor_col=$((cursor_col-1))
                elif [ $cursor_row -gt 0 ]; then
                    # 如果光标列坐标等于0，并且行坐标大于0，则当前行的内容添加到前一行的末尾
                    # 获取前一行内容
                    pre_line=$(cat $backup | sed -n $((cursor_row))'p')
                    # 将当前行的内容添加到前一行中
                    tmp_line=${pre_line}${cur_line}
                    # 替换前一行的内容
                    sed -i $((cursor_row))'s/.*/'"${tmp_line}"'/' ${backup}
                    # 删除当前行
                    sed -i $((cursor_row+1))'d' ${backup}
                    # 光标的行号减一
                    cursor_row=$((cursor_row-1))
                    # 光标的列号为前一行的末尾
                    cursor_col=${#preline}
                fi
                bottom_msg="-- INSERT --"
            ;;
            # Enter键，进行换行
            $'\n')
                Do_Enter
                bottom_msg="-- INSERT --"
            ;;
            # 其他输入
            *)
                # 将新字符插入光标所在位置，并且光标右移
                tmp_line=${cur_line:0:$cursor_col}$key${cur_line:$cursor_col}
                sed -i $((cursor_row+1))'s/.*/'"${tmp_line}"'/' ${backup}
                # 光标右移
                cursor_col=$((cursor_col+1))
                bottom_msg="-- INSERT --"
            ;;
        esac
    fi

    # 清除屏幕
    clear
    # 打印文件内容
    ShowContent "$bottom_msg"

done
# 清屏
clear
# 删除备份文件
rm $backup 
# 恢复光标
tput cvvis 
# 程序结束
exit 0