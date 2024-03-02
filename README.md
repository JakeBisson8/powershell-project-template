# powershell-project-template

### About

A basic starter template for a PowerShell project that includes formatting, linting, and git hooks.

Dev Depenndencies:
- husky

### Installation

1. Select to use the template in GitHub and create a new repository using the template
2. Clone your new repository

```bash
git clone <repository_link>.git
```
3. Udpate `package.json` to change the `name`, `description`, `version`, `keywords`, `author` etc. to match your project.
4. Install project dependencies using your package manager of choice
```bash
npm install
```
5. Install recommended vscode extensions (Also listed in `.vscode/extensions.json`)
   1. PowerShell
6. Check out the `Settings` section and `Lint` section
7. Happy Coding!

### Settings
Recommended settings have been defined in `.vscode/settings.json` and will be used unless they have been overriden in your own `settings.json`. The settings set the Powershell extension's formatter as the default formatter for powershell files and enable format on save. The settings also have formatting settings pre-defined that can be modified.

### Format
Formatting is handled through the Powershell extension's formatter and formatting settings defined in `.vscode/settings.json`.

### Lint
You can change the analyzer settings in `PSScriptAnalyzerSettings.psd1` and you can use `.psscriptanalyzerignore` to define ignored files and folders. 

Check for linter errors
```bash
npm run lint
```

Check for linter errors and address fixable errors
```bash
npm run lint:fix
```

Check for linter errors on staged files only
```bash
npm run lint:staged
```

Check for linter errors and address fixable errors on staged files only
```bash
npm run lint:staged:fix
```

### Test

Run all tests
```bash
npm run test
```

Run all tests with detailed output
```bash
npm run test:detailed
```

### License
[MIT](https://github.com/JakeBisson8/powershell-project-template/blob/main/LICENSE)  
[https://choosealicense.com/licenses/mit/](https://choosealicense.com/licenses/mit/)
