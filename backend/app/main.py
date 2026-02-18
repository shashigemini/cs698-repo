from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Spiritual Q&A Platform",
    description="Backend for Spiritual Q&A Platform using RAG",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Welcome to the Spiritual Q&A Platform API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
