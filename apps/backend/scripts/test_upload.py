import asyncio
from app.core.database import Database
from app.dependencies import set_database
from app.config import get_settings
from app.services.document_service import DocumentService
from fastapi import BackgroundTasks

async def main():
    settings = get_settings()
    pdf_path = "/workspaces/cs698-repo/test_data/Meher Baba on Be True to Your Duty and Five Other Messages - Read Book.pdf"
    
    try:
        with open(pdf_path, "rb") as f:
            content = f.read()
    except Exception as e:
        print(f"Failed to read PDF: {e}")
        return
        
    database = Database(settings)
    set_database(database)
    async with database.session_factory() as session:
        service = DocumentService(settings, session)
        bt = BackgroundTasks()
        print("Ingesting document...")
        try:
            result = await service.ingest(
                file_content=content,
                filename="Meher_Baba_on_Be_True.pdf",
                title="Meher Baba Messages",
                logical_book_id="book_123",
                background_tasks=bt,
                author="Meher Baba",
                edition="1st"
            )
            print("Ingest returned:", result)
        except Exception as e:
            print(f"Ingest failed: {e}")
            return
            
        print(f"Executing {len(bt.tasks)} background tasks...")
        for task in bt.tasks:
            print(f"Running task {task.func.__name__}...")
            try:
                if asyncio.iscoroutinefunction(task.func):
                    await task.func(*task.args, **task.kwargs)
                else:
                    task.func(*task.args, **task.kwargs)
                print(f"Task {task.func.__name__} completed successfully.")
            except Exception as e:
                print(f"Background task {task.func.__name__} failed: {e}")

if __name__ == "__main__":
    asyncio.run(main())
