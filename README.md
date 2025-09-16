# Project Swar - AI-Powered Code Analysis with 3D Visualization

Project Swar is an innovative code analysis tool that combines artificial intelligence, 3D visualization, and audio synthesis to provide developers with a unique way to understand and explore their codebase.

## Features

- **Advanced Code Analysis**: Uses tree-sitter for precise syntax parsing and machine learning for intelligent code classification
- **3D Visualization**: Interactive 3D node-based visualization of code structure and relationships
- **Audio Synthesis**: Real-time musical representation of code patterns and structures using Tone.js
- **Real-time WebSocket Communication**: Live updates and interactive feedback
- **Cross-language Support**: Currently supports JavaScript and Go with extensible architecture

## Tech Stack

### Backend
- **FastAPI**: High-performance Python web framework
- **Tree-sitter**: Advanced syntax parsing library
- **scikit-learn**: Machine learning for code classification
- **WebSocket**: Real-time communication
- **Python 3.11+**: Core runtime environment

### Frontend
- **React 18**: Modern UI framework
- **TypeScript**: Type-safe development
- **Three.js + react-three-fiber**: 3D graphics and visualization
- **Tone.js**: Web audio synthesis
- **Vite**: Fast development and build tooling
- **Tailwind CSS**: Utility-first styling

## Installation

### Prerequisites
- Python 3.11 or higher
- Node.js 18 or higher
- Visual Studio Community 2022 (Windows) or build tools for compiling native modules

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Compile tree-sitter grammars (requires C++ compiler):
   ```bash
   python -c "from code_analyzer import compile_tree_sitter_languages; compile_tree_sitter_languages()"
   ```

5. Start the backend server:
   ```bash
   uvicorn main:app --reload
   ```

### Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

## Usage

1. **Access the Application**: Open your browser and navigate to `http://localhost:5173`

2. **Analyze Code**: 
   - Enter your code in the text area
   - Select the programming language (JavaScript or Go)
   - Click "Analyze Code" to process

3. **Explore Visualizations**:
   - View the 3D node representation of your code structure
   - Listen to the musical interpretation of code patterns
   - Interact with the visualization using mouse controls

4. **Real-time Feedback**: The application provides immediate feedback on:
   - Syntax errors and warnings
   - Code complexity metrics
   - Structural analysis results

## Architecture

### Code Analysis Pipeline
1. **Input Processing**: Code is received via REST API or WebSocket
2. **Syntax Parsing**: Tree-sitter analyzes code structure and identifies syntax elements
3. **Machine Learning Classification**: Trained model categorizes code patterns and complexity
4. **Visualization Generation**: 3D nodes and connections are created based on analysis results
5. **Audio Synthesis**: Musical patterns are generated to represent code characteristics

### API Endpoints
- `POST /classify`: Analyze code and return classification results
- `WS /ws/visualizer`: WebSocket endpoint for real-time visualization updates

## Development

### Tree-sitter Integration
The application uses tree-sitter for precise syntax analysis:
- Compiled language grammars are stored in `backend/build/languages.so`
- Supports recursive tree traversal for comprehensive analysis
- Fallback regex analysis for compatibility

### Machine Learning Model
- Trained on code complexity and pattern recognition
- Stored as `backend/model.joblib`
- Continuously improved through usage analytics

### 3D Visualization
- Built with Three.js and react-three-fiber
- Dynamic node positioning based on code structure
- Interactive camera controls and lighting

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and commit: `git commit -m "Add feature"`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

For issues, questions, or contributions, please visit the GitHub repository or contact the development team.

---

*Project Swar - Transforming code analysis through visualization and sound*