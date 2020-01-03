const https = require('https');
const { promises: fsp, readFileSync, createWriteStream } = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');
const { exec } = require('child_process');

const createHash = () => crypto.createHash('sha1').update(`${Date.now()}${Math.random()}`).digest('hex').replace(/[0-9]/g, '').substr(0, 5);

const runCommand = command => new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
        if (error || stderr) {
            return reject(error ? error.message : stderr);
        }
        return resolve(stdout);
    });
});

const downloadDeployable = (url, destination) => new Promise((resolve, reject) => {
    https.get(url, response => {
        if ([301, 302].includes(response.statusCode)) {
            return downloadDeployable(response.headers.location, destination).then(resolve).catch(reject);
        }
        if (response.statusCode !== 200) {
            return reject(response.statusMessage);
        }
        response.pipe(createWriteStream(destination)).on('close', resolve);
    });
});

const main = async ({ deployableName, owner, repo, version }) => {
    const tempDir = path.relative(__dirname, path.join(os.tmpdir(), createHash()));
    const targetPath = path.join(tempDir, createHash());

    await fsp.mkdir(tempDir, { recursive: true });
    await downloadDeployable(`https://github.com/${owner}/${repo}/releases/download/${version}/${deployableName}`, targetPath);

    await runCommand(`tar -xf ${targetPath} --directory "${tempDir}"`);
    await fsp.unlink(targetPath);

    const content = await fsp.readdir(tempDir);
    if (content.length === 0) {
        throw new Error(`Empty deployable response`);
    }
    if (content.length === 1 && (await fsp.stat(path.join(tempDir, content[0]))).isDirectory()) {
        return fsp.readdir(path.join(tempDir, content[0]));
    }
    return content;
}

main(JSON.parse(readFileSync(0))) // read and parse args from stdin
    .then(result => process.stdout.write(JSON.stringify(result)))
    .catch(err => {
        console.error(err);
        process.exit(1);
    });
