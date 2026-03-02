// Fogbinder Contradiction Detector WASM Module
// License: MIT OR AGPL-3.0 (with Palimpsest)
// Language game conflict detection (NOT logical contradiction)

use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};

#[wasm_bindgen]
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Contradiction {
    source1_id: String,
    source2_id: String,
    severity: f64,
    language_game_conflict: String,
    description: String,
}

#[wasm_bindgen]
impl Contradiction {
    #[wasm_bindgen(getter)]
    pub fn source1_id(&self) -> String {
        self.source1_id.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn source2_id(&self) -> String {
        self.source2_id.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn severity(&self) -> f64 {
        self.severity
    }

    #[wasm_bindgen(getter)]
    pub fn language_game_conflict(&self) -> String {
        self.language_game_conflict.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn description(&self) -> String {
        self.description.clone()
    }
}

#[wasm_bindgen]
pub fn detect_contradictions(sources: JsValue) -> Result<JsValue, JsValue> {
    // Parse input sources
    let sources: Vec<String> = serde_wasm_bindgen::from_value(sources)?;

    // TODO: Implement language game conflict detection
    // This should detect Wittgensteinian contradictions,
    // not logical contradictions

    let contradictions: Vec<Contradiction> = vec![];

    serde_wasm_bindgen::to_value(&contradictions)
        .map_err(|e| JsValue::from_str(&e.to_string()))
}

#[wasm_bindgen]
pub fn calculate_similarity(text1: &str, text2: &str) -> f64 {
    // TODO: Implement semantic similarity calculation
    // for detecting potential contradictions
    0.0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_contradiction_creation() {
        let c = Contradiction {
            source1_id: "source1".to_string(),
            source2_id: "source2".to_string(),
            severity: 0.8,
            language_game_conflict: "scientific vs moral language games".to_string(),
            description: "Conflicting use of 'good'".to_string(),
        };
        assert_eq!(c.severity, 0.8);
    }
}
