def tail_text_log():
    try:
        with open('full_test_log.txt', 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        print(f"TOTAL LINES: {len(lines)}")
        for line in lines[-100:]:
            print(line, end='')
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    tail_text_log()
