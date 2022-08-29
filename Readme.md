#### MyVim程序手册

- 功能描述文档

1. 程序实现的是一个命令行编辑器程序，实现了vim的部分功能
2. 程序实现了vim的两个模式，普通模式（NORMAL）和编辑模式(INSERT)，下面分别进行阐述
3. 使用程序打开文件后，默认为普通模式

 1）程序支持显示行号显示，因为这是新创建的文件，因此没有内容，光标处于左上方位置

2）在界面下方，程序模仿vim，显示了底边栏，其中从左到右依次为：表示当前模式为普通模式的信息栏、当前打开的文件名称、当前文件的行数和字符数、当前光标的位置

3）在普通模式下，程序支持以下功能：

​	a) 按下h或上方向键，光标上移

​	b) 按下l或者下方向键，光标下移

​	c) 按下j或者左方向键，光标左移

​	d) 按下k或者右方向键，光标右移

​	e) 按下i，切换到编辑模式

​	f) 按下w，保存文件

​	g) 按下q，退出文件

​	h) 按下d，删除当前行

​	i) 按下g，光标移动到第一行行首

​	j) 按下G，光标移动到最后一行行首

4. 下边在普通模式下按下i，切换到编辑模式

1）编辑模式下，仍然有底边栏显示，从左到右依次为：表示当前模式为编辑模式的信息栏、当前光标所在的位置

2）编辑模式下，可以输入内容，输入内容方式和vim一样；支持输入空格、回车、换行符

3）编辑模式下，可以通过方向键移动光标位置进行编辑位置的选择

4）编辑模式下，按下Esc键，可以回到普通模式

5）此外，编辑模式还实现了一些编辑方面的细节

​	a) 在移动光标时，会判断光标是否超出文字范围，若会超出，则光标不会动（例如光标在行首时，按下左方向键不会响应左移）

​	b) 在使用退格键删除内容时，若光标位于当前行最左侧，再按下退格键后，当前行的内容会添加到前一行内容末尾（如果有前一行的话），同时当前行内容删除，这和vim保持一致，这个细节可以大大优化用该程序编写文档的使用体验

5. 此外，程序还设计了帮助文档和报错信息，帮助用户更好使用程序

```shell
./MyVim.sh --help
```

- 设计文档

##### 设计思想

程序的主要设计思想体现在以下几个方面：

1. 如何实现文件内容的显示
   1. 首先，在使用该程序打开文件时，程序会先创建一个备份文件，内容和源文件一致，所有尚未保存的操作均在备份文件中进行
   2. 在显示内容前，我们先要隐藏光标，之后清屏，为内容显示做准备
   3. 之后我们每次从备份文件中读取一行内容，通过行号和光标位置的比较，判断光标是否在当前行，若不在，直接输出当前行内容
   4. 若光标在当前行，我们在输出当前行内容的同时，也需要输出光标
   5. 在输出完所有文件内容后，我们移动光标位置到终端底部，输出底部信息栏，之后复原光标位置即可实现文件内容的显示
2. 如何实现键盘输入字符的读取
   1. 我们使用`read -sN1 key`命令循环读取字符
   2. 对于方向键的读取，因为方向键包含多个字符，因此我们可以采取短时间内读取多个字符再拼接的方式读入方向键
   3. 之后根据读取的字符进行相应的操作即可
3. 如何实现文件内容的更改
   1.  我们通过字符串的截取和拼接实现文件内容的更改
   2.  首先我们读取光标位置所在行的内容，将输入的字符拼接到光标对应的位置后，在将修改后的内容覆盖掉原先的行内容即可
   3.  使用`sed -i`命令，可以实现方便高效的文件内容修改
4. 如何实现光标的位置移动
   1. 我们使用`cursor_row`和`cursor_col`变量存储光标的位置
   2. 根据输入的字符，我们只需要相应修改变量的值即可实现光标位置的修改；其中需要注意一下边界的判定
   3. 修改了光标的位置变量后，在文件内容的显示部分，就可以显示光标位置的修改了
5. 如何实现普通模式和编辑模式的切换
   1. 我们使用`mode`变量来记录当前的模式，每读入一个字符，就根据当前的模式进行不同的操作即可

##### 功能模块

​	代码中的主要功能函数如下：

```shell
# 显示当前文件内容
ShowContent() {
}
# 处理上移和下移时光标位置的特殊情况
Cursor_Pos_Change() {
}
# 光标左移
Cursor_left() {
}
# 光标右移
Cursor_right() {
}
# 光标上移
Cursor_up() {
}
# 光标下移
Cursor_down() {
}
# 处理换行
Do_Enter() {
}
# 处理当前行的删除
Do_Delete() {
}
# 打印底部信息
ShowBottom() {
}
# 显示当前行数和字符数
ShowNumbers() {
}
```

##### 数据结构

​	程序的主要数据结构为字符串，通过对字符串进行截取和拼接，实现字符的输入和删除

##### 算法

​	程序不涉及复杂的算法，主要通过while循环读入字符和输出文件内容