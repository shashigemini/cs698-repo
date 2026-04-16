import subprocess
with open('parsed_logs.txt', 'w', encoding='utf-8') as f:
    f.write('Extracting logs...\n')
    try:
        out = subprocess.check_output(['docker', 'logs', 'backend-app-1'], stderr=subprocess.STDOUT)
        out_str = out.decode('utf-8', errors='replace')
        lines = out_str.splitlines()
        found = False
        for i, line in enumerate(lines):
            if '/api/chat/conversations' in line or 'Traceback' in line or '500 Internal' in line or 'Exception' in line:
                found = True
                start = max(0, i - 2)
                end = min(len(lines), i + 50)
                f.write('='*50 + '\n')
                f.write(f'MATCH AT LINE {i}\n')
                f.write('='*50 + '\n')
                f.write('\n'.join(lines[start:end]) + '\n\n')
        if not found:
            f.write('NO MATCHES FOUND IN ALL LOGS\n')
    except Exception as e:
        f.write(f'Error reading logs: {e}\n')
