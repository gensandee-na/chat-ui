const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const task = process.argv[2];

if (!task) {
  console.error('Error: Please provide a task description.');
  console.log('Usage: node run_agent.cjs "Go to http://localhost:5173 and check the title"');
  process.exit(1);
}

// Check for .env file
const envPath = path.resolve(__dirname, '../../.env');
if (!fs.existsSync(envPath)) {
  console.warn('Warning: .env file not found. Ensure HF_TOKEN or OPENAI_API_KEY is set in your environment.');
}

console.log(`Running agent task: "${task}"...`);

const agentProcess = spawn('npm', ['run', 'agent', task], {
  cwd: path.resolve(__dirname, '../../'),
  stdio: 'inherit',
  shell: true
});

agentProcess.on('close', (code) => {
  if (code === 0) {
    console.log('✅ Agent task completed.');
  } else {
    console.error(`❌ Agent task failed with exit code ${code}.`);
  }
});
