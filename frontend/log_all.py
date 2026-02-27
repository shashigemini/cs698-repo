import json

def json_to_text():
    try:
        content = None
        # Try both UTF-16LE and UTF-8 as PowerShell handles them differently
        for enc in ['utf-16le', 'utf-8']:
            try:
                with open('test_results.json', 'r', encoding=enc) as f:
                    content = f.read()
                if content:
                    break
            except:
                continue
        
        if not content:
            print("Could not read test_results.json with known encodings")
            return

        lines = content.splitlines()
        with open('full_log_all.txt', 'w', encoding='utf-8') as out:
            for line in lines:
                try:
                    data = json.loads(line)
                    if 'message' in data:
                        out.write(data['message'])
                        out.write("\n")
                except:
                    continue
        print("Wrote full_log_all.txt")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    json_to_text()
