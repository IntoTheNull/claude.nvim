# Security Policy

## API Key Security

Claude.nvim is designed to interact with the Anthropic Claude API, which requires an API key. To keep your API key secure:

1. **Never hardcode your API key** directly in your Neovim configuration
2. Use a command that retrieves the key from a secure location:
   ```lua
   api_key_cmd = "cat /path/to/secure/key/file" -- or
   api_key_cmd = "security find-generic-password -a $USER -s claude-api-key -w" -- MacOS Keychain
   ```
3. Ensure your API key file has appropriate permissions (e.g., `chmod 600`)
4. Do not commit API key files to version control (they are in `.gitignore` by default)

## Reporting a Vulnerability

If you discover a security vulnerability in Claude.nvim, please follow these steps:

1. **Do not disclose the vulnerability publicly** until it has been addressed
2. Email the details to the maintainers or open a GitHub Security Advisory
3. Include as much information as possible:
   - Type of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix if available

The maintainers will acknowledge receipt of your report within 72 hours and provide an estimated timeline for a fix.

## Best Practices for Users

When using Claude.nvim, follow these best practices:

1. Keep your Neovim and plugins updated to the latest versions
2. Review permissions of files containing sensitive information
3. Be careful about what information you send to the Claude API
4. Avoid sharing confidential or sensitive information in your conversations
5. Regularly review and rotate your API key

## Code Security Practices

The Claude.nvim development team follows these practices:

1. Careful review of PRs for security implications
2. No storage of user's conversations on servers
3. Minimal use of third-party dependencies
4. Regular security reviews of the codebase
5. Documentation of security considerations for users