import sys

# 建议从 GitHub 搜索 "通用规范汉字表3500" 获取完整字符串
# https://ty8.ustb.edu.cn/pub/yywzbgs/docs/2019-12/3257a7350ff544449f4d26577b48d292.pdf
with open("3500.txt", 'r', encoding='utf-8') as f:
    GRADE1_3500 = f.read()

def is_modern_common(char):
    if len(char) != 1: return True # 保留词组
    # 检查是否在 3500 字表内
    return char in GRADE1_3500

with open('zi.dict.yaml', 'r', encoding='utf-8') as f, \
     open('zi_level1_3500.dict.yaml', 'w', encoding='utf-8') as out:
    header_done = False
    for line in f:
        if not header_done:
            out.write(line)
            if line.strip() == "...": header_done = True
            continue
        
        parts = line.split('\t')
        if len(parts) >= 1:
            word = parts[0]
            if is_modern_common(word):
                out.write(line)

print("处理完成：已生成基于 3500 常用字的新词库。")