import tseslint from "typescript-eslint";

export default [
  {
    files: ["src/**/*.ts"],
    languageOptions: { parser: tseslint.parser },
    plugins: { "@typescript-eslint": tseslint.plugin },
    rules: {
      "no-restricted-globals": ["error", { name: "fetch", message: "Use request() from src/lib/http.ts. See docs/coding-principles.md (One owner)." }],
      "no-restricted-properties": ["error", { object: "process", property: "env", message: "Read settings from config in src/config.ts. See docs/coding-principles.md (One owner)." }],
      "no-restricted-imports": ["error", { patterns: [{ group: ["**/legacy/fetch-helper"], message: "Use request() from src/lib/http.ts. See docs/coding-principles.md (One owner)." }] }],
      "no-useless-catch": "error",
      "no-warning-comments": ["error", { terms: ["plan", "spec", "task"], location: "anywhere" }],
      "@typescript-eslint/naming-convention": ["error", { selector: "typeLike", format: null, custom: { regex: "(Manager|Helper)$", match: false } }],
    },
  },
  { files: ["src/lib/http.ts", "src/legacy/fetch-helper.ts"], rules: { "no-restricted-globals": "off" } },
  { files: ["src/config.ts"], rules: { "no-restricted-properties": "off" } },
  // Existing violations, to clean up
  { files: ["src/reports/monthly.ts"], rules: { "no-restricted-imports": "off" } },
  { files: ["src/services/invoice-service.ts"], rules: { "no-useless-catch": "off", "@typescript-eslint/naming-convention": "off" } },
  { files: ["src/api/users.ts"], rules: { "no-warning-comments": "off" } },
];
