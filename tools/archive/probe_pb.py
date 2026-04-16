"""Test cross-workspace cascade fetching from .pb files."""
import json, urllib.request, os

PORT = 52152
TOKEN = "9e2f4137-808d-42d9-a5da-b8796e59fb70"
PB_DIR = r"C:\Users\shash\.gemini\antigravity\conversations"

known = {
    "be327430-cfed-4077-b3e5-2a5508a2efcf",
    "4cdfd38a-77b4-401b-9de2-9f403dded2b7",
    "6aeac1a9-b80e-4d6d-91c8-9535d28ff931",
    "a21a7b34-0e42-495a-90ca-600efb2f9ebf",
    "6d964d61-c36a-45ff-9d53-e2123e4908af",
    "6ac84873-7c2b-444a-8b9e-e847250a8be7",
    "cc75ba46-d03d-4306-96fe-8225b755f534",
    "0feede47-faf3-4db0-ad62-4345f11dc900",
    "750d2d12-c4cb-4ed0-9d47-80a767af0128",
    "5a3c4ee6-29de-47f6-b4cc-38dfb24bfcd3",
    "2eda3a75-0a09-458d-a244-fdb7273f8809",
    "584906e6-7769-4091-9d02-97b3df52de98",
}

others = [
    f[:-3] for f in os.listdir(PB_DIR)
    if f.endswith(".pb") and f[:-3] not in known
]
print(f"Other cascade IDs: {len(others)}")


def call_steps(cid):
    req = urllib.request.Request(
        f"http://localhost:{PORT}/exa.language_server_pb"
        ".LanguageServerService/GetCascadeTrajectorySteps",
        data=json.dumps({"cascadeId": cid, "startIndex": 0, "endIndex": 2}).encode(),
        headers={
            "Content-Type": "application/json",
            "Connect-Protocol-Version": "1",
            "X-Codeium-Csrf-Token": TOKEN,
        },
    )
    try:
        return json.loads(urllib.request.urlopen(req, timeout=5).read()), None
    except Exception as e:
        return None, str(e)


for cid in others[:5]:
    d, err = call_steps(cid)
    if d:
        steps = d.get("steps", [])
        first_type = steps[0].get("type") if steps else "none"
        print(f"{cid}: OK, {len(steps)} steps, first={first_type}")
    else:
        print(f"{cid}: ERR {err[:80]}")
