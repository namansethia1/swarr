import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
from code_analyzer import analyze_code_with_tree_sitter, CodeAnalyzer

# Initialize the FastAPI application
app = FastAPI()

# Configure CORS (Cross-Origin Resource Sharing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the pre-trained machine learning model for genre classification
model_pipeline = joblib.load('model.joblib')
# Instantiate your regex-based code analyzer
regex_analyzer = CodeAnalyzer()

class CodeInput(BaseModel):
    code: str

@app.post("/classify")
def classify(code_input: CodeInput):
    """
    HTTP endpoint to classify code genre using the pre-trained model.
    """
    prediction = model_pipeline.predict([code_input.code])
    return {"genre": prediction[0]}

@app.websocket("/ws/visualizer")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time code analysis.
    This now runs both tree-sitter and the regex analyzer in parallel.
    """
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            code = data['code']
            
            # Simple language detection (can be improved)
            language = 'javascript' if 'function' in code or 'const' in code or 'let' in code else 'go'

            # --- PARALLEL ANALYSIS ---
            # 1. Get structural and syntax errors from tree-sitter
            tree_sitter_results = list(analyze_code_with_tree_sitter(code, language))
            
            # 2. Get logical and best-practice errors from your regex analyzer
            regex_results = regex_analyzer.analyze_code(code, language)

            # 3. Combine and sort all results by line number
            all_results = sorted(tree_sitter_results + regex_results, key=lambda x: x['startLine'])
            
            # 4. Stream the unified results to the frontend
            for result in all_results:
                 await websocket.send_json(result)

            # Once done, break the loop to close the connection gracefully
            break

    except WebSocketDisconnect:
        print("Client disconnected")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        print("Connection closed")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
