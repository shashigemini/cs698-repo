import psutil
import sys

def get_process_cmdline(pid):
    try:
        process = psutil.Process(pid)
        return " ".join(process.cmdline())
    except Exception as e:
        return str(e)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        pid = int(sys.argv[1])
        print(get_process_cmdline(pid))
    else:
        print("Please provide a PID")
