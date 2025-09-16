import React, { useState, useRef, useCallback, useEffect } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { Stars, Text } from '@react-three/drei';
import * as Tone from 'tone';
import * as THREE from 'three';

// --- API and WebSocket Service Functions ---
async function classifyCode(code: string): Promise<{ genre: string; confidence: number }> {
    const response = await fetch('http://127.0.0.1:8000/classify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code }),
    });
    if (!response.ok) throw new Error('Failed to classify code');
    return response.json();
}

// --- Musical Palettes ---
const musicPalettes: { [key: string]: { scale: string[]; synth: any; } } = {
    'Go-Concurrent': { scale: ['C3', 'D#3', 'G3', 'G#3', 'C4', 'D#4', 'G4', 'G#4'], synth: Tone.FMSynth },
    'Go-Systems':    { scale: ['A2', 'B2', 'C3', 'E3', 'A3', 'B3', 'C4', 'E4'], synth: Tone.AMSynth },
    'JS-Async':      { scale: ['G4', 'A4', 'C5', 'D5', 'F5', 'G5', 'A5', 'C6'], synth: Tone.PluckSynth },
    'JS-DOM':        { scale: ['C4', 'E4', 'G4', 'A4', 'B4', 'C5', 'E5', 'G5'], synth: Tone.PolySynth },
    'JS-Functional': { scale: ['D3', 'F3', 'A3', 'C4', 'E4', 'F4', 'A4', 'C5'], synth: Tone.MembraneSynth },
    'Algorithmic-Logic': { scale: ['C4', 'D4', 'E4', 'F#4', 'G#4', 'A#4', 'C5', 'D5'], synth: Tone.PolySynth },
    'default':       { scale: ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'], synth: Tone.PolySynth }
};

// --- Interfaces ---
interface NodeVisualProps { 
    id: string; type: string; position: [number, number, number]; duration: number; isError: boolean;
}
interface MusicalEvent {
    note: string | string[]; duration: string; type: string; startLine: number; endLine: number; isError: boolean; message: string;
}
interface HighlightInfo {
    start: number; end: number; type: string; isError: boolean;
}

// --- 3D Components ---
const NodeVisual: React.FC<NodeVisualProps> = ({ id, type, position, duration, isError }) => {
    const meshRef = useRef<THREE.Mesh>(null!);
    const initialLifetime = useRef(duration * (isError ? 3 : 1.5) + 0.5);

    useEffect(() => {
        if (meshRef.current) {
            meshRef.current.visible = true;
            meshRef.current.userData.lifetime = initialLifetime.current;
        }
    }, [id]);

    useFrame((_, delta) => {
        if (!meshRef.current || !meshRef.current.visible) return;
        meshRef.current.userData.lifetime -= delta;
        const lifetime = meshRef.current.userData.lifetime;
        const opacity = THREE.MathUtils.lerp(0, 1, lifetime / initialLifetime.current);
        (meshRef.current.material as THREE.MeshStandardMaterial).opacity = opacity;
        if (lifetime <= 0) meshRef.current.visible = false;
        if (isError && meshRef.current.visible) {
            meshRef.current.rotation.y += delta * 2;
            meshRef.current.rotation.x += delta;
        }
    });
    
    const getErrorGeometry = (errorType: string) => {
        switch(errorType) {
            case 'syntax_error': return <octahedronGeometry args={[0.8, 0]} />;
            case 'logical_error': return <dodecahedronGeometry args={[0.8, 0]} />;
            case 'best_practice': return <tetrahedronGeometry args={[0.8, 0]} />;
            default: return <octahedronGeometry args={[0.8, 0]} />;
        }
    };
    const geometry = isError ? getErrorGeometry(type) : type.includes('function') ? <sphereGeometry args={[0.6, 32, 32]} /> : type.includes('for') ? <torusGeometry args={[0.5, 0.15, 16, 100]} /> : type.includes('if') ? <boxGeometry args={[0.8, 0.8, 0.8]} /> : <icosahedronGeometry args={[0.5, 0]} />;
    const color = isError ? (type === 'syntax_error' ? '#ff0000' : type === 'logical_error' ? '#ff8c00' : type === 'best_practice' ? '#ffd700' : '#ff0000') : (type.includes('function') ? '#ff69b4' : type.includes('for') ? '#00ffff' : type.includes('if') ? '#ffff00' : '#9932cc');

    return (
        <mesh ref={meshRef} position={position}>
            {geometry}
            <meshStandardMaterial color={color} emissive={color} emissiveIntensity={3} transparent depthWrite={false} blending={THREE.AdditiveBlending} />
        </mesh>
    );
};

const CameraAnimator = ({ effect, setEffect }: { effect: number; setEffect: (e: number) => void }) => {
    const { camera } = useThree();
    useFrame(() => {
        if (effect > 0) {
            camera.position.x += (Math.random() - 0.5) * effect * 0.3;
            camera.position.y += (Math.random() - 0.5) * effect * 0.3;
            setEffect(effect * 0.9);
        }
        camera.position.lerp(new THREE.Vector3(0, 0, 15), 0.05);
    });
    return null;
};

// --- UI Components ---
const CodeEditor = ({ code, setCode, disabled, persistentErrors }: { code: string; setCode: (code: string) => void; disabled: boolean; persistentErrors: Map<number, string> }) => {
    const lineNumbers = code.split('\n').length;
    const lineCounterRef = useRef<HTMLDivElement>(null);
    const textAreaRef = useRef<HTMLTextAreaElement>(null);

    const handleScroll = () => {
        if (lineCounterRef.current && textAreaRef.current) {
            lineCounterRef.current.scrollTop = textAreaRef.current.scrollTop;
        }
    };
    
    const handleCodeChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
        setCode(e.target.value);
    };

    return (
        <div className="code-editor-wrapper">
            <div className="line-numbers" ref={lineCounterRef}>
                {Array.from({ length: lineNumbers }, (_, i) => {
                    const lineNum = i + 1;
                    const errorType = persistentErrors.get(lineNum);
                    const lineClass = errorType ? `error-line-${errorType}` : '';
                    return <div key={i} className={lineClass}>{lineNum}</div>
                })}
            </div>
            <textarea
                ref={textAreaRef}
                className="code-container"
                value={code}
                onChange={handleCodeChange}
                onScroll={handleScroll}
                disabled={disabled}
                spellCheck="false"
            />
        </div>
    );
};

const CodeViewer = ({ code, highlightedLines }: { code: string; highlightedLines: HighlightInfo | null }) => {
    return (
        <div className="code-editor-wrapper view-mode">
            <div className="code-container">
                {code.split('\n').map((line, index) => {
                    const lineNum = index + 1;
                    const isHighlighted = highlightedLines && (lineNum >= highlightedLines.start && lineNum <= highlightedLines.end);
                    const lineClass = isHighlighted ? (highlightedLines.isError ? `error-line-${highlightedLines.type}` : 'highlighted-line') : '';
                    
                    return (
                        <div key={index} className={`code-line ${lineClass}`}>
                            <span className="line-number">{lineNum}</span>
                            <span className="line-content">{line || ' '}</span>
                        </div>
                    );
                })}
            </div>
        </div>
    );
};

const SummaryModal = ({ summary, onClose }: { summary: { title: string, messages: string[] } | null, onClose: () => void }) => {
    if (!summary) return null;
    return (
        <div className="modal-backdrop" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                <h2>{summary.title}</h2>
                {summary.messages.length > 0 ? (
                    <ul>
                        {summary.messages.map((msg, index) => <li key={index}>{msg}</li>)}
                    </ul>
                ) : <p>No issues found. The code is clean!</p>}
                <button onClick={onClose} className="modal-close-button">Close</button>
            </div>
        </div>
    );
};

// --- Main App Component ---
export default function App() {
    const [code, setCode] = useState("function factorial(n) {\n  if (n === 0) {\n    return 1;\n  } else {\n    let result = 1;\n    // A syntax error for demonstration\n    for (let i = 1; i <= n; i++ {\n      result *= i;\n    }\n    return result;\n  }\n}");
    const [isPlaying, setIsPlaying] = useState(false);
    const [status, setStatus] = useState('Ready. Paste your code and press Play.');
    const [visualNodes, setVisualNodes] = useState<NodeVisualProps[]>([]);
    const [cameraEffect, setCameraEffect] = useState(0);
    const [activePalette, setActivePalette] = useState('default');
    const [highlightedLines, setHighlightedLines] = useState<HighlightInfo | null>(null);
    const [summary, setSummary] = useState<{ title: string, messages: string[] } | null>(null);
    const [persistentErrors, setPersistentErrors] = useState<Map<number, string>>(new Map());
    
    const ws = useRef<WebSocket | null>(null);
    const synth = useRef<any>(null);
    const sequence = useRef<Tone.Sequence | null>(null);
    const stopTimeoutRef = useRef<number | null>(null);
    
    const stopMusic = useCallback((finalSummary?: { title: string, messages: string[] }) => {
        if (stopTimeoutRef.current) clearTimeout(stopTimeoutRef.current);
        
        Tone.Transport.stop();
        Tone.Transport.cancel();
        
        if (sequence.current) sequence.current.dispose();
        
        if (ws.current && ws.current.readyState === WebSocket.OPEN) ws.current.close();

        setIsPlaying(false);
        // **PERSISTENCE FIX**: Do not clear highlights on stop.
        if (finalSummary) {
            setSummary(finalSummary);
            setStatus(finalSummary.title);
        } else {
            setStatus('Ready to play again.');
        }
    }, []);
    
    const handleCodeChange = (newCode: string) => {
        setCode(newCode);
        // Clear errors when the user starts typing again
        if (persistentErrors.size > 0) {
            setPersistentErrors(new Map());
            setHighlightedLines(null);
        }
    };

    const handlePlay = useCallback(async (): Promise<void> => {
        if (isPlaying) {
            ws.current?.close();
            return;
        }

        if (Tone.context.state !== 'running') await Tone.start();

        try {
            setIsPlaying(true);
            setVisualNodes([]);
            setHighlightedLines(null);
            setSummary(null);
            setPersistentErrors(new Map());
            setStatus('1/3: Classifying code...');
            
            const classification = await classifyCode(code);
            const paletteKey = classification.genre in musicPalettes ? classification.genre : 'default';
            setActivePalette(paletteKey);
            const palette = musicPalettes[paletteKey];
            
            if (synth.current) synth.current.dispose();
            synth.current = new palette.synth({ volume: -9, oscillator: { type: 'sine8' } }).toDestination();
            
            setStatus('2/3: Analyzing code structure...');
            const musicalEvents: MusicalEvent[] = [];
            const errorMessages: string[] = [];
            const collectedErrors = new Map<number, string>();

            ws.current = new WebSocket('ws://127.0.0.1:8000/ws/visualizer');
            ws.current.onopen = () => ws.current?.send(JSON.stringify({ code }));

            ws.current.onmessage = (event) => {
                const data = JSON.parse(event.data);
                musicalEvents.push(data);
                if (data.isError) {
                    errorMessages.push(`Line ${data.startLine}: [${data.type}] ${data.message}`);
                    collectedErrors.set(data.startLine, data.type);
                }
            };

            ws.current.onerror = (error) => {
                console.error('WebSocket error:', error);
                stopMusic({ title: "Connection Error", messages: ["Failed to connect to the visualizer service."] });
            };

            ws.current.onclose = () => {
                if (musicalEvents.length === 0) {
                    stopMusic({ title: "Analysis Complete", messages: ["No parsable musical elements were found in the code."] });
                    return;
                }
                
                setStatus('3/3: Composing and playing music...');
                
                const scheduledEvents: (MusicalEvent & { time: number })[] = [];
                let cumulativeTime = 0;
                let messageCounter = 0;

                musicalEvents.forEach(event => {
                    const currentScale = palette.scale;
                    let note: string | string[];
                    let duration: string;

                    if (event.isError) {
                        switch(event.type) {
                            case 'syntax_error': note = ['C2', 'C#2']; duration = '8n'; break;
                            case 'logical_error': note = ['E2', 'F2']; duration = '16n'; break;
                            case 'best_practice': note = ['G2', 'G#2']; duration = '16n'; break;
                            default: note = 'C2'; duration = '16n'; break;
                        }
                    } else {
                         const noteIndex = Math.abs(event.startLine + messageCounter);
                         switch (event.type) {
                            case 'function_declaration': case 'arrow_function':
                                note = [currentScale[noteIndex % currentScale.length], currentScale[(noteIndex + 3) % currentScale.length]];
                                duration = '4n'; break;
                            default:
                                note = currentScale[noteIndex % currentScale.length];
                                duration = '16n'; break;
                        }
                    }
                    
                    const newScheduledEvent: MusicalEvent & { time: number } = {
                        time: cumulativeTime,
                        note: note,
                        duration: duration,
                        type: event.type,
                        startLine: event.startLine,
                        endLine: event.endLine,
                        isError: event.isError,
                        message: event.message,
                    };
                    scheduledEvents.push(newScheduledEvent);
                    cumulativeTime += Tone.Time(duration).toSeconds();
                    if (!event.isError) messageCounter++;
                });

                sequence.current = new Tone.Sequence((time, event) => {
                    synth.current?.triggerAttackRelease(event.note, event.duration, time);
                        
                    Tone.Draw.schedule(() => {
                        setHighlightedLines({ start: event.startLine, end: event.endLine, type: event.type, isError: event.isError });
                        setCameraEffect(event.isError ? 2.5 : 1.0);
                        const newNode: NodeVisualProps = {
                            id: `${time}-${Math.random()}`,
                            type: event.type,
                            position: [(Math.random() - 0.5) * 10, (Math.random() - 0.5) * 10, (Math.random() - 0.5) * 10],
                            duration: Tone.Time(event.duration).toSeconds(),
                            isError: event.isError
                        };
                        setVisualNodes(prev => [...prev.slice(-30), newNode]);
                    }, time);
                }, scheduledEvents).start(0);

                sequence.current.loop = false;
                Tone.Transport.start();

                const finalSummary = {
                    title: errorMessages.length > 0 ? "Analysis Complete: Issues Found" : "Analysis Complete: Code is Clean!",
                    messages: errorMessages
                };
                
                // Set persistent errors right before stopping
                const finalStop = () => {
                    setPersistentErrors(collectedErrors);
                    stopMusic(finalSummary);
                }
                stopTimeoutRef.current = window.setTimeout(finalStop, (cumulativeTime + 2) * 1000);
            };

        } catch (error) {
            console.error('Failed to start visualization:', error);
            stopMusic({ title: "Connection Error", messages: ["Could not connect to the backend service."] });
        }
    }, [code, isPlaying, stopMusic]);

    useEffect(() => {
        return () => { 
           stopMusic();
           if(ws.current) ws.current.close();
        }
    }, [stopMusic]);

    return (
        <div className="App">
            <header><h1>Swarr</h1><p>Real-Time Code Sonification & Visualization</p></header>
            <main>
                <div className="editor-container">
                    {isPlaying ? (
                        <CodeViewer code={code} highlightedLines={highlightedLines} />
                    ) : (
                        <CodeEditor code={code} setCode={handleCodeChange} disabled={isPlaying} persistentErrors={persistentErrors} />
                    )}
                    <button onClick={handlePlay} disabled={!code.trim()}>{isPlaying ? 'Play' : 'Scan'}</button>
                </div>
                <div className="visualizer-container">
                    <Canvas camera={{ position: [0, 0, 15], fov: 75 }}>
                        <ambientLight intensity={0.2} /><pointLight position={[10, 10, 10]} intensity={1.5} />
                        <Stars radius={100} depth={50} count={5000} factor={4} saturation={0} fade speed={1} />
                        {visualNodes.map(node => <NodeVisual key={node.id} {...node} />)}
                        {!isPlaying && (<Text position={[0, 0, 0]} fontSize={0.8} color="#555" anchorX="center" anchorY="middle" outlineColor="#000" outlineWidth={0.05}>Press Play to Visualize</Text>)}
                        <CameraAnimator effect={cameraEffect} setEffect={setCameraEffect} />
                    </Canvas>
                </div>
            </main>
            <footer>Status: {status} | Musical Palette: {activePalette}</footer>
            <SummaryModal summary={summary} onClose={() => setSummary(null)} />
        </div>
    );
}

