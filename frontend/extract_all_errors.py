import json

def extract_all_errors():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
            
        for line in lines:
            try:
                data = json.loads(line)
                if data.get('type') == 'error' or data.get('result') == 'error':
                    print("\n" + "="*80)
                    print(json.dumps(data, indent=2))
                    print("="*80)
            except:
                pass
    except Exception as e:
        print(f"File error: {e}")

if __name__ == '__main__':
    extract_all_errors()
