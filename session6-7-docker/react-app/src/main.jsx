import React from "react";
import { createRoot } from "react-dom/client";

function App() {
    return (
        <div>
            <h1>Hello World from React + Docker!</h1>
            <h3>Name: Rishi Harti</h3>
            <h3>Roll No: 24bcs10239</h3>
        </div>
    );
}

createRoot(document.getElementById("root")).render(<App />);