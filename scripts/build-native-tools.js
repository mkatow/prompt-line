#!/usr/bin/env node
/**
 * Cross-platform native tools build script
 * Builds macOS Swift tools or Windows PowerShell tools based on platform
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const platform = process.platform;

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function buildMacOSTools() {
  console.log('Building macOS native tools...');
  
  try {
    // Run the existing macOS Makefile
    execSync('cd native && make install', { stdio: 'inherit' });
    
    // Copy to dist directory
    const sourceDir = path.join(__dirname, '..', 'src', 'native-tools');
    const destDir = path.join(__dirname, '..', 'dist', 'native-tools');
    
    if (fs.existsSync(sourceDir)) {
      execSync(`cp -r "${sourceDir}" "${destDir}"`, { stdio: 'inherit' });
      console.log('✅ macOS native tools built successfully');
    } else {
      throw new Error('Native tools source directory not found');
    }
  } catch (error) {
    console.error('❌ Failed to build macOS native tools:', error.message);
    process.exit(1);
  }
}

function buildWindowsTools() {
  console.log('Building Windows native tools...');
  
  try {
    // Run the Windows compile script
    const nativeWinDir = path.join(__dirname, '..', 'native-win');
    const compileScript = path.join(nativeWinDir, 'compile.bat');
    
    if (fs.existsSync(compileScript)) {
      execSync(`cd "${nativeWinDir}" && compile.bat`, { stdio: 'inherit' });
      
      // Copy to dist directory
      const sourceDir = path.join(__dirname, '..', 'src', 'native-tools-win');
      const destDir = path.join(__dirname, '..', 'dist', 'native-tools-win');
      
      if (fs.existsSync(sourceDir)) {
        ensureDir(path.dirname(destDir));
        execSync(`xcopy "${sourceDir}" "${destDir}" /E /I /Y`, { stdio: 'inherit' });
        console.log('✅ Windows native tools built successfully');
      } else {
        throw new Error('Windows native tools source directory not found');
      }
    } else {
      throw new Error('Windows compile script not found');
    }
  } catch (error) {
    console.error('❌ Failed to build Windows native tools:', error.message);
    process.exit(1);
  }
}

function buildLinuxFallback() {
  console.log('Linux platform detected - creating fallback structure...');
  
  // Create empty directories for Linux (no native tools supported)
  const destDir = path.join(__dirname, '..', 'dist', 'native-tools');
  ensureDir(destDir);
  
  // Create a README explaining Linux limitations
  const readmeContent = `# Native Tools Not Available on Linux

This directory is a placeholder. Native system automation tools are not available on Linux.
The application will fall back to basic clipboard operations only.

Supported platforms:
- macOS: Full native automation via Swift tools
- Windows: Full native automation via PowerShell tools  
- Linux: Basic clipboard operations only
`;
  
  fs.writeFileSync(path.join(destDir, 'README.md'), readmeContent);
  console.log('✅ Linux fallback structure created');
}

// Main execution
console.log(`🔧 Building native tools for platform: ${platform}`);

switch (platform) {
  case 'darwin':
    buildMacOSTools();
    break;
  case 'win32':
    buildWindowsTools();
    break;
  default:
    buildLinuxFallback();
    break;
}

console.log('🎉 Native tools build completed');