import asyncio
import os
from qdrant_client import AsyncQdrantClient

async def check():
    client = AsyncQdrantClient(url="http://qdrant:6333")
    collection_name = os.environ.get("QDRANT_COLLECTION", "spiritual_docs_dev")
    collections = await client.get_collections()
    
    exists = False
    for c in collections.collections:
        if c.name == collection_name:
            exists = True
            break
            
    if not exists:
         print(f"Collection {collection_name} does not exist.")
         return
         
    count = await client.count(collection_name=collection_name)
    print(f"\nCollection '{collection_name}' has {count.count} points.")
    
    if count.count > 0:
        result = await client.scroll(
            collection_name=collection_name,
            limit=3,
            with_payload=True
        )
        points, _ = result
        print("\n=== SAMPLE POINTS ===")
        for i, point in enumerate(points):
            print(f"\n--- Point {i+1} ---")
            if point.payload:
                for k, v in point.payload.items():
                    if k == "text":
                        print(f"  {k}: {v[:100]}... (length: {len(v)})")
                    else:
                        print(f"  {k}: {v}")
            else:
                print("  (no payload)")

if __name__ == "__main__":
    asyncio.run(check())
