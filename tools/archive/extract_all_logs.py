import subprocess
with open('all_logs.txt', 'w', encoding='utf-8') as f:
    out = subprocess.check_output(['docker', 'logs', 'backend-app-1'], stderr=subprocess.STDOUT)
    f.write(out.decode('utf-8', errors='replace'))
