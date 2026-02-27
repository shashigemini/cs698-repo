import json

def global_error_search():
    try:
        with open('test_results.json', 'r', encoding='utf-16le', errors='ignore') as f:
            lines = f.readlines()
        
        for i, line in enumerate(lines):
            if any(k in line.lower() for k in ['exception', 'error', 'failure', 'bad state']):
                print(f"\n--- MATCH AT LINE {i} ---")
                try:
                    data = json.loads(line)
                    print(json.dumps(data, indent=2))
                except:
                    print(line.strip())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    global_error_search()
