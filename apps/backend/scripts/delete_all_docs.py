import asyncio
import os
import sys

from app.core.database import Database
from app.config import get_settings
from app.services.document_service import DocumentService

async def main():
    settings = get_settings()
    database = Database(settings)
    try:
        async for session in database.get_session():
            service = DocumentService(settings, session)
            
            docs = await service.list_documents()
            for doc in docs:
                doc_id = str(doc['id'])
                print(f"Deleting document {doc_id} - {doc['title']}...")
                success = await service.delete_document(doc_id)
                if success:
                    print(f"Successfully deleted {doc_id}")
                else:
                    print(f"Failed to delete {doc_id}")
            break
    finally:
        await database.close()

if __name__ == "__main__":
    asyncio.run(main())
