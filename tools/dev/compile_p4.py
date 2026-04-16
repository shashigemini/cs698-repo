import os

def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read().strip()

def main():
    base_dir = "/workspaces/cs698-repo"
    out_file = os.path.join(base_dir, "submission", "P4_SUBMISSION.md")
    
    parts = []
    
    parts.append("# Project 4: Backend Development Submission\n")
    
    # Section 1
    parts.append("## 1. Updated Development Specifications\n")
    parts.append(read_file(os.path.join(base_dir, "docs", "course", "P4_Story_1_Harmonized.md")))
    parts.append("\n<br>\n")
    parts.append(read_file(os.path.join(base_dir, "docs", "course", "P4_Story_2_Harmonized.md")))
    
    # Section 2
    parts.append("\n<br>\n---\n")
    parts.append("## 2. Unified Backend Architecture\n")
    parts.append(read_file(os.path.join(base_dir, "docs", "course", "P4_Unified_Architecture.md")))
    
    # Section 3
    parts.append("\n<br>\n---\n")
    parts.append("## 3. Module Specifications\n")
    parts.append(read_file(os.path.join(base_dir, "docs", "course", "P4_Module_Auth.md")))
    parts.append("\n<br>\n")
    parts.append(read_file(os.path.join(base_dir, "docs", "course", "P4_Module_RAG.md")))
    
    # Section 4
    parts.append("\n<br>\n---\n")
    parts.append("## 4. Links to GitHub Source\n")
    parts.append("*   **Source code (`apps/backend/app/`)**: [View on GitHub](https://github.com/shashigemini/cs698-repo/tree/main/apps/backend/app)")
    parts.append("*   **Test code (`apps/backend/tests/`)**: [View on GitHub](https://github.com/shashigemini/cs698-repo/tree/main/apps/backend/tests)")
    parts.append("*   **Backend README**: [View on GitHub](https://github.com/shashigemini/cs698-repo/blob/main/apps/backend/README.md)")
    
    # Section 5
    parts.append("\n<br>\n---\n")
    parts.append("## 5. Startup Commands\n")
    parts.append("### Backend Startup\n")
    parts.append("Below are the exact commands required to run the unified backend locally (extracted from `apps/backend/README.md`):")
    parts.append("```bash\ncd apps/backend\npoetry install\ndocker-compose up -d\npoetry run alembic upgrade head\npoetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload\n```")
    parts.append("\n### Frontend Startup\n")
    parts.append("In a separate terminal, use Flutter to run the frontend application. (We recommend the Chrome device for web testing). Make sure your backend is already running on port 8000.")
    parts.append("```bash\ncd apps/frontend\nflutter pub get\nflutter run -d chrome\n```")
    
    # Section 6
    parts.append("\n<br>\n---\n")
    parts.append("## 6. Student Reflection\n")
    parts.append(read_file(os.path.join(base_dir, "docs", "course", "P4_Reflection.md")))
    
    # Section 7
    parts.append("\n<br>\n---\n")
    parts.append("## 7. LLM Interaction Logs\n")
    parts.append("*[Note to student: Paste the link or transcript of your LLM chat sessions here.]*\n")
    
    with open(out_file, "w", encoding="utf-8") as f:
        f.write("\n\n".join(parts))
        
    print(f"Compilation complete! File saved to {out_file}")

if __name__ == "__main__":
    main()
