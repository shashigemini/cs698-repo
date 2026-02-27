import json

def extract_line_50():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
        
        target = lines[50]
        data = json.loads(target)
        print("FULL MESSAGE FROM LINE 50:")
        print(data.get('message', 'NO MESSAGE'))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    extract_line_50()
