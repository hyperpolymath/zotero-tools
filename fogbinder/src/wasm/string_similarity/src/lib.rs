// Fogbinder String Similarity WASM Module
// License: MIT OR AGPL-3.0 (with Palimpsest)
// High-performance string similarity algorithms

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn levenshtein_distance(s1: &str, s2: &str) -> usize {
    let len1 = s1.chars().count();
    let len2 = s2.chars().count();

    if len1 == 0 { return len2; }
    if len2 == 0 { return len1; }

    let mut matrix = vec![vec![0; len2 + 1]; len1 + 1];

    for i in 0..=len1 {
        matrix[i][0] = i;
    }
    for j in 0..=len2 {
        matrix[0][j] = j;
    }

    let s1_chars: Vec<char> = s1.chars().collect();
    let s2_chars: Vec<char> = s2.chars().collect();

    for i in 1..=len1 {
        for j in 1..=len2 {
            let cost = if s1_chars[i - 1] == s2_chars[j - 1] { 0 } else { 1 };
            matrix[i][j] = std::cmp::min(
                std::cmp::min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
                matrix[i - 1][j - 1] + cost
            );
        }
    }

    matrix[len1][len2]
}

#[wasm_bindgen]
pub fn similarity_ratio(s1: &str, s2: &str) -> f64 {
    let distance = levenshtein_distance(s1, s2);
    let max_len = std::cmp::max(s1.len(), s2.len());

    if max_len == 0 {
        return 1.0;
    }

    1.0 - (distance as f64 / max_len as f64)
}

#[wasm_bindgen]
pub fn cosine_similarity(text1: &str, text2: &str) -> f64 {
    // TODO: Implement cosine similarity for text
    // For semantic comparison
    0.0
}

#[wasm_bindgen]
pub fn jaccard_similarity(text1: &str, text2: &str) -> f64 {
    // TODO: Implement Jaccard similarity
    // For set-based comparison
    0.0
}

#[wasm_bindgen]
pub fn fuzzy_match(pattern: &str, text: &str) -> bool {
    // agrep-style fuzzy matching
    let ratio = similarity_ratio(pattern, text);
    ratio >= 0.8 // 80% similarity threshold
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_levenshtein() {
        assert_eq!(levenshtein_distance("kitten", "sitting"), 3);
        assert_eq!(levenshtein_distance("", ""), 0);
        assert_eq!(levenshtein_distance("abc", "abc"), 0);
    }

    #[test]
    fn test_similarity_ratio() {
        let ratio = similarity_ratio("hello", "hallo");
        assert!(ratio > 0.7);
    }

    #[test]
    fn test_fuzzy_match() {
        assert!(fuzzy_match("wittgenstein", "wittgenstein"));
        assert!(fuzzy_match("wittgenstein", "wittgenstin")); // typo
    }
}
