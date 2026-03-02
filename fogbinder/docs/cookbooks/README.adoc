# Fogbinder Cookbooks

Practical how-to guides for using Fogbinder's epistemic ambiguity analysis features.

## Available Cookbooks

### 📚 [Complete Cookbook](./COMPLETE_COOKBOOK.md)
All 9 recipes in one place. Use this as a comprehensive reference.

**Contents:**
1. Basic Analysis (Beginner)
2. Zotero Integration (Intermediate)
3. Epistemic States (Intermediate)
4. Speech Acts (Intermediate)
5. Detect Contradictions (Advanced)
6. Mood Scoring (Intermediate)
7. Mystery Clustering (Advanced)
8. FogTrail Visualization (Advanced)
9. Full Analysis Pipeline (Advanced)

### 🌱 [Beginner's Cookbook](./BEGINNER_COOKBOOK.md)
Start here if you're new to Fogbinder.

**Learn:**
- Basic Fogbinder analysis
- Understanding language game contexts
- Interpreting results (epistemic states, contradictions, mysteries, mood)

**Time:** 5-10 minutes

### 🔧 [Intermediate Cookbook](./INTERMEDIATE_COOKBOOK.md)
For users familiar with basic analysis.

**Topics:**
- Zotero integration
- Working with epistemic states
- Speech act analysis
- Mood scoring (not sentiment analysis!)

**Prerequisites:** Completed beginner recipe

### ⚡ [Advanced Cookbook](./ADVANCED_COOKBOOK.md)
Expert-level analysis and visualization.

**Topics:**
- Contradiction detection (language game conflicts)
- Mystery clustering (epistemic resistance)
- FogTrail visualization (network graphs)
- Full analysis pipeline

**Prerequisites:** Solid understanding of Wittgenstein's language games and J.L. Austin's speech acts

## Quick Start

1. **New to Fogbinder?** → Start with [Beginner's Cookbook](./BEGINNER_COOKBOOK.md)
2. **Want to integrate with Zotero?** → See [Intermediate Cookbook - Recipe 1](./INTERMEDIATE_COOKBOOK.md#recipe-1-zotero-integration)
3. **Need to detect contradictions?** → See [Advanced Cookbook - Recipe 1](./ADVANCED_COOKBOOK.md#recipe-1-contradiction-detection)
4. **Want comprehensive analysis?** → See [Advanced Cookbook - Recipe 4](./ADVANCED_COOKBOOK.md#recipe-4-full-analysis-pipeline)

## Structure of Each Recipe

Every recipe follows this format:

- **Title & Metadata** - Difficulty, time, prerequisites
- **Overview** - What you'll learn
- **Ingredients** - What you'll need
- **Steps** - Detailed instructions
- **Code** - Complete, working examples
- **Notes** - Important details and tips
- **See Also** - Related recipes and documentation

## Philosophy

These cookbooks are **auto-generated** from the codebase. As new features are added to Fogbinder, the cookbook generator automatically creates new recipes.

This ensures:
- ✅ Recipes are always up-to-date
- ✅ Code examples actually work
- ✅ No missing features
- ✅ Consistent format

## Regenerating Cookbooks

If you've added new features to Fogbinder and want to update the cookbooks:

```bash
deno run --allow-read --allow-write scripts/generate_cookbooks.ts
```

The generator will:
1. Scan the codebase for available modules and functions
2. Identify new features and capabilities
3. Generate or update recipes based on usage patterns
4. Export to Markdown in `docs/cookbooks/`

## Additional Resources

- [API Reference](../API.md) - Complete API documentation
- [Philosophy Guide](../PHILOSOPHY.md) - Theoretical foundations (Wittgenstein, J.L. Austin)
- [Development Guide](../DEVELOPMENT.md) - For contributors
- [CLAUDE.md](../../CLAUDE.md) - AI assistant guide

## Contributing Recipes

If you have a useful Fogbinder pattern or workflow:

1. Share it in the community (GitHub Discussions)
2. If it's common enough, it may be added to the cookbook generator
3. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines

## License

All cookbooks are licensed under **GNU AGPLv3**, same as Fogbinder itself.

---

**Last Updated:** 2025-11-23
**Fogbinder Version:** 0.1.0
**Auto-generated:** Yes (via `scripts/generate_cookbooks.ts`)
